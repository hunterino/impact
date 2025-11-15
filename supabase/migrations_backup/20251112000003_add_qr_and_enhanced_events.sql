-- Migration: Add QR codes and enhanced event features from Libertas
-- Description: QR check-in, sponsorships, and enhanced event management

-- Add QR code support to project_events
ALTER TABLE project_events
ADD COLUMN IF NOT EXISTS qr_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS qr_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS qr_valid_from TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS qr_valid_until TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS check_in_radius_meters INTEGER DEFAULT 100,
ADD COLUMN IF NOT EXISTS virtual_event_url TEXT,
ADD COLUMN IF NOT EXISTS is_virtual BOOLEAN DEFAULT false;

-- Add QR check-in support to commitments
ALTER TABLE project_event_commitments
ADD COLUMN IF NOT EXISTS check_in_method TEXT DEFAULT 'manual' CHECK (check_in_method IN ('manual', 'qr', 'geofence', 'auto')),
ADD COLUMN IF NOT EXISTS check_in_location GEOGRAPHY(Point),
ADD COLUMN IF NOT EXISTS check_out_location GEOGRAPHY(Point),
ADD COLUMN IF NOT EXISTS qr_scan_data JSONB,
ADD COLUMN IF NOT EXISTS device_info JSONB,
ADD COLUMN IF NOT EXISTS verification_photo_url TEXT;

-- Create sponsorships table
CREATE TABLE IF NOT EXISTS sponsorships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    organization TEXT,
    logo_url TEXT,
    website_url TEXT,
    sponsorship_level TEXT CHECK (sponsorship_level IN ('platinum', 'gold', 'silver', 'bronze', 'community')),
    contribution_amount DECIMAL(10,2),
    contribution_type TEXT CHECK (contribution_type IN ('monetary', 'in-kind', 'volunteer', 'venue', 'equipment')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create project_sponsors junction table
CREATE TABLE IF NOT EXISTS project_sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    sponsor_id UUID REFERENCES sponsorships(id) ON DELETE CASCADE,
    sponsorship_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    UNIQUE(project_id, sponsor_id)
);

-- Create event_sponsors junction table
CREATE TABLE IF NOT EXISTS event_sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES project_events(id) ON DELETE CASCADE,
    sponsor_id UUID REFERENCES sponsorships(id) ON DELETE CASCADE,
    sponsorship_date DATE DEFAULT CURRENT_DATE,
    notes TEXT,
    UNIQUE(event_id, sponsor_id)
);

-- Create attendance_logs table for detailed tracking
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    commitment_id UUID REFERENCES project_event_commitments(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('check_in', 'check_out', 'break_start', 'break_end')),
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    method TEXT CHECK (method IN ('qr', 'manual', 'geofence', 'auto')),
    location GEOGRAPHY(Point),
    notes TEXT,
    logged_by UUID REFERENCES profiles(id)
);

-- Create event_statistics table for analytics
CREATE TABLE IF NOT EXISTS event_statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES project_events(id) ON DELETE CASCADE,
    total_registered INTEGER DEFAULT 0,
    total_attended INTEGER DEFAULT 0,
    total_hours_served DECIMAL(10,2) DEFAULT 0,
    average_rating DECIMAL(3,2),
    qr_scans_count INTEGER DEFAULT 0,
    no_shows_count INTEGER DEFAULT 0,
    calculated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id)
);

-- Function to generate unique QR codes
CREATE OR REPLACE FUNCTION generate_qr_code()
RETURNS TEXT AS $$
DECLARE
    v_code TEXT;
    v_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate a unique code with prefix
        v_code := 'stbf://event/' || gen_random_uuid()::text;

        -- Check if it exists
        SELECT EXISTS(SELECT 1 FROM project_events WHERE qr_code = v_code) INTO v_exists;

        EXIT WHEN NOT v_exists;
    END LOOP;

    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- Function to process QR check-in
CREATE OR REPLACE FUNCTION process_qr_checkin(
    p_qr_code TEXT,
    p_user_id UUID,
    p_location GEOGRAPHY DEFAULT NULL,
    p_device_info JSONB DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_event RECORD;
    v_commitment RECORD;
    v_result JSONB;
BEGIN
    -- Find event by QR code
    SELECT * INTO v_event
    FROM project_events
    WHERE qr_code = p_qr_code
    AND qr_enabled = true
    AND (qr_valid_from IS NULL OR qr_valid_from <= NOW())
    AND (qr_valid_until IS NULL OR qr_valid_until >= NOW());

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired QR code');
    END IF;

    -- Find user's commitment
    SELECT pec.* INTO v_commitment
    FROM project_event_commitments pec
    JOIN project_event_timeslots pet ON pec.timeslot_id = pet.id
    WHERE pet.event_id = v_event.id
    AND pec.user_id = p_user_id
    AND pec.status IN ('confirmed', 'pending');

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'No commitment found for this event');
    END IF;

    -- Check if already checked in
    IF v_commitment.checked_in_at IS NOT NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already checked in');
    END IF;

    -- Verify location if required
    IF v_event.check_in_radius_meters IS NOT NULL AND p_location IS NOT NULL THEN
        IF ST_Distance(v_event.location::geography, p_location) > v_event.check_in_radius_meters THEN
            RETURN jsonb_build_object('success', false, 'error', 'Outside check-in radius');
        END IF;
    END IF;

    -- Process check-in
    UPDATE project_event_commitments
    SET
        checked_in_at = NOW(),
        check_in_method = 'qr',
        check_in_location = p_location,
        qr_scan_data = jsonb_build_object(
            'qr_code', p_qr_code,
            'scan_time', NOW(),
            'event_id', v_event.id
        ),
        device_info = p_device_info,
        status = 'checked_in'
    WHERE id = v_commitment.id;

    -- Log attendance
    INSERT INTO attendance_logs (
        commitment_id, action, method, location
    ) VALUES (
        v_commitment.id, 'check_in', 'qr', p_location
    );

    -- Update event statistics
    UPDATE event_statistics
    SET total_attended = total_attended + 1
    WHERE event_id = v_event.id;

    v_result := jsonb_build_object(
        'success', true,
        'commitment_id', v_commitment.id,
        'event_name', v_event.title,
        'check_in_time', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to process check-out
CREATE OR REPLACE FUNCTION process_checkout(
    p_commitment_id UUID,
    p_method TEXT DEFAULT 'manual',
    p_location GEOGRAPHY DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_commitment RECORD;
    v_hours_served DECIMAL;
    v_points_earned DECIMAL;
    v_result JSONB;
BEGIN
    -- Get commitment
    SELECT * INTO v_commitment
    FROM project_event_commitments
    WHERE id = p_commitment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Commitment not found');
    END IF;

    IF v_commitment.checked_in_at IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Not checked in');
    END IF;

    IF v_commitment.checked_out_at IS NOT NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Already checked out');
    END IF;

    -- Calculate hours served
    v_hours_served := EXTRACT(EPOCH FROM (NOW() - v_commitment.checked_in_at)) / 3600.0;

    -- Calculate points (10 points per hour as default)
    v_points_earned := v_hours_served * 10;

    -- Update commitment
    UPDATE project_event_commitments
    SET
        checked_out_at = NOW(),
        check_out_location = p_location,
        hours_served = v_hours_served,
        status = 'completed'
    WHERE id = p_commitment_id;

    -- Log attendance
    INSERT INTO attendance_logs (
        commitment_id, action, method, location
    ) VALUES (
        p_commitment_id, 'check_out', p_method, p_location
    );

    -- Award points
    PERFORM award_points(
        v_commitment.user_id,
        v_points_earned,
        1,
        format('Service hours for event attendance (%s hours)', round(v_hours_served, 2)),
        p_commitment_id
    );

    -- Update event statistics
    UPDATE event_statistics
    SET total_hours_served = total_hours_served + v_hours_served
    WHERE event_id = (
        SELECT pet.event_id
        FROM project_event_timeslots pet
        WHERE pet.id = v_commitment.timeslot_id
    );

    v_result := jsonb_build_object(
        'success', true,
        'hours_served', v_hours_served,
        'points_earned', v_points_earned,
        'check_out_time', NOW()
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to generate QR codes for new events
CREATE OR REPLACE FUNCTION auto_generate_qr_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.qr_code IS NULL AND NEW.qr_enabled = true THEN
        NEW.qr_code := generate_qr_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_event_insert_qr
BEFORE INSERT ON project_events
FOR EACH ROW EXECUTE FUNCTION auto_generate_qr_code();

-- Trigger to initialize event statistics
CREATE OR REPLACE FUNCTION init_event_statistics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO event_statistics (event_id)
    VALUES (NEW.id)
    ON CONFLICT (event_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_event_insert_stats
AFTER INSERT ON project_events
FOR EACH ROW EXECUTE FUNCTION init_event_statistics();

-- Update existing events with QR codes
UPDATE project_events
SET qr_code = generate_qr_code()
WHERE qr_code IS NULL AND qr_enabled = true;

-- Initialize statistics for existing events
INSERT INTO event_statistics (event_id)
SELECT id FROM project_events
ON CONFLICT (event_id) DO NOTHING;

-- Indexes for performance
CREATE INDEX idx_project_events_qr_code ON project_events(qr_code) WHERE qr_enabled = true;
CREATE INDEX idx_attendance_logs_commitment ON attendance_logs(commitment_id);
CREATE INDEX idx_attendance_logs_timestamp ON attendance_logs(timestamp DESC);
CREATE INDEX idx_event_statistics_event ON event_statistics(event_id);

-- Row Level Security
ALTER TABLE sponsorships ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_statistics ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Sponsorships are viewable by everyone" ON sponsorships
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can view their own attendance logs" ON attendance_logs
    FOR SELECT USING (
        commitment_id IN (
            SELECT id FROM project_event_commitments
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Event statistics are viewable by everyone" ON event_statistics
    FOR SELECT USING (true);