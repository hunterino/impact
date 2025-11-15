-- Migration: Add notifications and enhanced team features
-- Description: Push notifications, in-app notifications, and improved team management

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN (
        'event_reminder', 'commitment_confirmed', 'points_earned',
        'friend_request', 'team_invite', 'message', 'comment',
        'like', 'mention', 'achievement', 'system', 'promotion'
    )),
    title TEXT NOT NULL,
    message TEXT,
    data JSONB,
    image_url TEXT,
    action_url TEXT,
    is_read BOOLEAN DEFAULT false,
    is_push_sent BOOLEAN DEFAULT false,
    push_sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create push_tokens table for device registration
CREATE TABLE IF NOT EXISTS push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    device_info JSONB,
    is_active BOOLEAN DEFAULT true,
    last_used TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- Enhance teams table (if not exists, create it)
CREATE TABLE IF NOT EXISTS teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    avatar_url TEXT,
    cover_image_url TEXT,
    team_type TEXT DEFAULT 'volunteer' CHECK (team_type IN ('volunteer', 'corporate', 'school', 'community', 'family')),
    visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'invite_only')),
    max_members INTEGER DEFAULT 50,
    points_multiplier DECIMAL(3,2) DEFAULT 1.0,
    leader_id UUID REFERENCES profiles(id),
    project_id UUID REFERENCES projects(id),
    parent_team_id UUID REFERENCES teams(id),
    settings JSONB DEFAULT '{}',
    stats JSONB DEFAULT '{}',
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enhance team_members table
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'moderator', 'member')),
    status TEXT DEFAULT 'active' CHECK (status IN ('pending', 'active', 'inactive', 'banned')),
    points_contributed DECIMAL(10,2) DEFAULT 0,
    hours_contributed DECIMAL(10,2) DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    invited_by UUID REFERENCES profiles(id),
    invitation_message TEXT,
    left_at TIMESTAMPTZ,
    UNIQUE(team_id, user_id)
);

-- Create team_invitations table
CREATE TABLE IF NOT EXISTS team_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    invited_user_id UUID REFERENCES profiles(id),
    invited_email TEXT,
    invited_phone TEXT,
    inviter_id UUID REFERENCES profiles(id),
    invitation_code TEXT UNIQUE DEFAULT gen_random_uuid()::text,
    message TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,
    CHECK (invited_user_id IS NOT NULL OR invited_email IS NOT NULL OR invited_phone IS NOT NULL)
);

-- Create team_activities table for team feed
CREATE TABLE IF NOT EXISTS team_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id),
    activity_type TEXT NOT NULL,
    description TEXT,
    data JSONB,
    points_earned DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create team_challenges table
CREATE TABLE IF NOT EXISTS team_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    challenge_type TEXT CHECK (challenge_type IN ('hours', 'points', 'projects', 'members', 'custom')),
    target_value DECIMAL(10,2),
    current_value DECIMAL(10,2) DEFAULT 0,
    reward_points DECIMAL(10,2),
    reward_description TEXT,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create team_challenge_participants junction table
CREATE TABLE IF NOT EXISTS team_challenge_participants (
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
    challenge_id UUID REFERENCES team_challenges(id) ON DELETE CASCADE,
    progress DECIMAL(10,2) DEFAULT 0,
    completed_at TIMESTAMPTZ,
    rank INTEGER,
    PRIMARY KEY (team_id, challenge_id)
);

-- Create achievements/badges table
CREATE TABLE IF NOT EXISTS achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    category TEXT,
    points_value INTEGER DEFAULT 0,
    requirements JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create user_achievements junction table
CREATE TABLE IF NOT EXISTS user_achievements (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id),
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    progress DECIMAL(5,2) DEFAULT 100.0,
    PRIMARY KEY (user_id, achievement_id)
);

-- Function to send notification
CREATE OR REPLACE FUNCTION send_notification(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_data JSONB DEFAULT NULL,
    p_action_url TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    -- Insert notification
    INSERT INTO notifications (
        user_id, type, title, message, data, action_url
    ) VALUES (
        p_user_id, p_type, p_title, p_message, p_data, p_action_url
    ) RETURNING id INTO v_notification_id;

    -- Trigger push notification (would be handled by edge function)
    -- This is a placeholder for the actual push notification logic

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql;

-- Function to invite user to team
CREATE OR REPLACE FUNCTION invite_to_team(
    p_team_id UUID,
    p_inviter_id UUID,
    p_invited_user_id UUID DEFAULT NULL,
    p_invited_email TEXT DEFAULT NULL,
    p_invited_phone TEXT DEFAULT NULL,
    p_message TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_team RECORD;
    v_invitation_id UUID;
    v_invitation_code TEXT;
BEGIN
    -- Validate team exists and inviter has permission
    SELECT * INTO v_team
    FROM teams t
    JOIN team_members tm ON t.id = tm.team_id
    WHERE t.id = p_team_id
    AND tm.user_id = p_inviter_id
    AND tm.role IN ('owner', 'admin')
    AND t.is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'No permission to invite');
    END IF;

    -- Check if already a member
    IF p_invited_user_id IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM team_members
            WHERE team_id = p_team_id AND user_id = p_invited_user_id
        ) THEN
            RETURN jsonb_build_object('success', false, 'error', 'User already a member');
        END IF;
    END IF;

    -- Create invitation
    INSERT INTO team_invitations (
        team_id, invited_user_id, invited_email, invited_phone,
        inviter_id, message
    ) VALUES (
        p_team_id, p_invited_user_id, p_invited_email, p_invited_phone,
        p_inviter_id, p_message
    ) RETURNING id, invitation_code INTO v_invitation_id, v_invitation_code;

    -- Send notification if user exists
    IF p_invited_user_id IS NOT NULL THEN
        PERFORM send_notification(
            p_invited_user_id,
            'team_invite',
            'Team Invitation',
            format('You have been invited to join %s', v_team.name),
            jsonb_build_object(
                'team_id', p_team_id,
                'invitation_id', v_invitation_id
            )
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'invitation_id', v_invitation_id,
        'invitation_code', v_invitation_code
    );
END;
$$ LANGUAGE plpgsql;

-- Function to calculate team statistics
CREATE OR REPLACE FUNCTION calculate_team_stats(p_team_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    WITH team_stats AS (
        SELECT
            COUNT(DISTINCT tm.user_id) AS total_members,
            SUM(tm.points_contributed) AS total_points,
            SUM(tm.hours_contributed) AS total_hours,
            COUNT(DISTINCT ta.id) AS total_activities,
            AVG(tm.points_contributed) AS avg_points_per_member
        FROM team_members tm
        LEFT JOIN team_activities ta ON ta.team_id = p_team_id
        WHERE tm.team_id = p_team_id
        AND tm.status = 'active'
    )
    SELECT jsonb_build_object(
        'total_members', COALESCE(total_members, 0),
        'total_points', COALESCE(total_points, 0),
        'total_hours', COALESCE(total_hours, 0),
        'total_activities', COALESCE(total_activities, 0),
        'avg_points_per_member', COALESCE(avg_points_per_member, 0),
        'last_updated', NOW()
    ) INTO v_stats
    FROM team_stats;

    -- Update team stats
    UPDATE teams
    SET stats = v_stats, updated_at = NOW()
    WHERE id = p_team_id;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create notification for various events
CREATE OR REPLACE FUNCTION notify_on_event()
RETURNS TRIGGER AS $$
BEGIN
    -- Handle different notification scenarios based on the table
    IF TG_TABLE_NAME = 'project_event_commitments' THEN
        IF NEW.status = 'confirmed' AND OLD.status != 'confirmed' THEN
            PERFORM send_notification(
                NEW.user_id,
                'commitment_confirmed',
                'Commitment Confirmed',
                'Your volunteer commitment has been confirmed',
                jsonb_build_object('commitment_id', NEW.id)
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create notification trigger for commitments
CREATE TRIGGER on_commitment_change_notify
AFTER UPDATE ON project_event_commitments
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION notify_on_event();

-- Indexes for performance
CREATE INDEX idx_notifications_user_unread ON notifications(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id) WHERE is_active = true;
CREATE INDEX idx_team_members_team ON team_members(team_id) WHERE status = 'active';
CREATE INDEX idx_team_members_user ON team_members(user_id) WHERE status = 'active';
CREATE INDEX idx_team_invitations_code ON team_invitations(invitation_code) WHERE status = 'pending';
CREATE INDEX idx_team_activities_team ON team_activities(team_id, created_at DESC);
CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);

-- Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own push tokens" ON push_tokens
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Teams visible based on visibility" ON teams
    FOR SELECT USING (
        visibility = 'public'
        OR EXISTS (
            SELECT 1 FROM team_members
            WHERE team_id = teams.id
            AND user_id = auth.uid()
            AND status = 'active'
        )
    );

CREATE POLICY "Team members can view their teams" ON team_members
    FOR SELECT USING (
        user_id = auth.uid()
        OR team_id IN (
            SELECT team_id FROM team_members
            WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Achievements are viewable by everyone" ON achievements
    FOR SELECT USING (is_active = true);

CREATE POLICY "Users can view their own achievements" ON user_achievements
    FOR SELECT USING (user_id = auth.uid());