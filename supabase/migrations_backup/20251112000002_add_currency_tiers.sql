-- Migration: Add 3-tier currency system from serve_to_be_free
-- Description: Implements STBF Points -> SERV DR -> SERV Coin with atomic operations

-- Create currency tiers table
CREATE TABLE IF NOT EXISTS currency_tiers (
    id SERIAL PRIMARY KEY,
    tier_level INTEGER UNIQUE NOT NULL CHECK (tier_level BETWEEN 1 AND 3),
    name TEXT UNIQUE NOT NULL,
    symbol TEXT NOT NULL,
    conversion_rate DECIMAL(10,4) NOT NULL,
    description TEXT,
    min_conversion_amount DECIMAL(10,2) DEFAULT 0,
    max_conversion_amount DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert the three currency tiers
INSERT INTO currency_tiers (tier_level, name, symbol, conversion_rate, description, min_conversion_amount) VALUES
(1, 'STBF Points', 'STBF', 1.0000, 'Base currency earned through volunteer service', 1),
(2, 'SERV DR', 'DR', 0.1000, 'Intermediate currency for marketplace purchases', 10),
(3, 'SERV Coin', 'SERV', 0.0100, 'Premium currency for exclusive rewards and governance', 100);

-- Update wallet_balances to support 3-tier system
ALTER TABLE wallet_balances
ADD COLUMN IF NOT EXISTS serv_dr DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS serv_coin DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_earned_stbf DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_spent_stbf DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_converted_stbf DECIMAL(10,2) DEFAULT 0;

-- Create currency conversion history table
CREATE TABLE IF NOT EXISTS currency_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    from_tier INTEGER REFERENCES currency_tiers(tier_level),
    to_tier INTEGER REFERENCES currency_tiers(tier_level),
    from_amount DECIMAL(10,2) NOT NULL,
    to_amount DECIMAL(10,2) NOT NULL,
    conversion_rate DECIMAL(10,4) NOT NULL,
    status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'reversed')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create rewards catalog table
CREATE TABLE IF NOT EXISTS rewards_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    image_url TEXT,
    required_tier INTEGER REFERENCES currency_tiers(tier_level),
    price DECIMAL(10,2) NOT NULL,
    quantity_available INTEGER,
    is_limited BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create redemption history table
CREATE TABLE IF NOT EXISTS redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reward_id UUID REFERENCES rewards_catalog(id),
    currency_tier INTEGER REFERENCES currency_tiers(tier_level),
    amount_spent DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'shipped', 'cancelled')),
    shipping_info JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Function for atomic currency conversion
CREATE OR REPLACE FUNCTION convert_currency(
    p_user_id UUID,
    p_from_tier INTEGER,
    p_to_tier INTEGER,
    p_amount DECIMAL
) RETURNS JSONB AS $$
DECLARE
    v_from_balance DECIMAL;
    v_from_rate DECIMAL;
    v_to_rate DECIMAL;
    v_converted_amount DECIMAL;
    v_min_amount DECIMAL;
    v_max_amount DECIMAL;
    v_result JSONB;
BEGIN
    -- Validate tiers
    IF p_from_tier = p_to_tier THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot convert to same tier');
    END IF;

    -- Get conversion rates and limits
    SELECT conversion_rate, min_conversion_amount, max_conversion_amount
    INTO v_from_rate, v_min_amount, v_max_amount
    FROM currency_tiers WHERE tier_level = p_from_tier AND is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid source tier');
    END IF;

    SELECT conversion_rate INTO v_to_rate
    FROM currency_tiers WHERE tier_level = p_to_tier AND is_active = true;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid destination tier');
    END IF;

    -- Check minimum amount
    IF p_amount < COALESCE(v_min_amount, 0) THEN
        RETURN jsonb_build_object('success', false, 'error', 'Amount below minimum conversion limit');
    END IF;

    -- Check maximum amount
    IF v_max_amount IS NOT NULL AND p_amount > v_max_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Amount exceeds maximum conversion limit');
    END IF;

    -- Calculate converted amount
    v_converted_amount := p_amount * (v_to_rate / v_from_rate);

    -- Lock the wallet row and check balance
    PERFORM 1 FROM wallet_balances WHERE user_id = p_user_id FOR UPDATE;

    -- Get current balance based on tier
    SELECT CASE p_from_tier
        WHEN 1 THEN stbf_points
        WHEN 2 THEN serv_dr
        WHEN 3 THEN serv_coin
    END INTO v_from_balance
    FROM wallet_balances WHERE user_id = p_user_id;

    -- Check sufficient balance
    IF v_from_balance < p_amount THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient balance');
    END IF;

    -- Perform atomic update
    UPDATE wallet_balances
    SET
        stbf_points = CASE
            WHEN p_from_tier = 1 THEN stbf_points - p_amount
            WHEN p_to_tier = 1 THEN stbf_points + v_converted_amount
            ELSE stbf_points
        END,
        serv_dr = CASE
            WHEN p_from_tier = 2 THEN serv_dr - p_amount
            WHEN p_to_tier = 2 THEN serv_dr + v_converted_amount
            ELSE serv_dr
        END,
        serv_coin = CASE
            WHEN p_from_tier = 3 THEN serv_coin - p_amount
            WHEN p_to_tier = 3 THEN serv_coin + v_converted_amount
            ELSE serv_coin
        END,
        total_converted_stbf = CASE
            WHEN p_from_tier = 1 THEN total_converted_stbf + p_amount
            ELSE total_converted_stbf
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record conversion history
    INSERT INTO currency_conversions (
        user_id, from_tier, to_tier, from_amount,
        to_amount, conversion_rate, status
    ) VALUES (
        p_user_id, p_from_tier, p_to_tier, p_amount,
        v_converted_amount, v_to_rate / v_from_rate, 'completed'
    );

    -- Record transaction
    INSERT INTO transactions (
        user_id, type, description, amount,
        balance_after, created_at
    ) VALUES (
        p_user_id, 'convert',
        format('Converted %s tier %s to %s tier %s', p_amount, p_from_tier, v_converted_amount, p_to_tier),
        -p_amount,
        v_from_balance - p_amount,
        NOW()
    );

    v_result := jsonb_build_object(
        'success', true,
        'from_amount', p_amount,
        'to_amount', v_converted_amount,
        'conversion_rate', v_to_rate / v_from_rate
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Enhanced atomic redemption function for 3-tier system
CREATE OR REPLACE FUNCTION redeem_points_multi_tier(
    p_user_id UUID,
    p_amount DECIMAL,
    p_tier INTEGER,
    p_description TEXT,
    p_reference_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_balance DECIMAL;
    v_tier_name TEXT;
    v_result JSONB;
BEGIN
    -- Get tier name
    SELECT name INTO v_tier_name FROM currency_tiers WHERE tier_level = p_tier;

    -- Lock the wallet row
    PERFORM 1 FROM wallet_balances WHERE user_id = p_user_id FOR UPDATE;

    -- Get current balance for the tier
    SELECT CASE p_tier
        WHEN 1 THEN stbf_points
        WHEN 2 THEN serv_dr
        WHEN 3 THEN serv_coin
    END INTO v_balance
    FROM wallet_balances WHERE user_id = p_user_id;

    -- Check sufficient balance
    IF v_balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', format('Insufficient %s balance', v_tier_name)
        );
    END IF;

    -- Update balance
    UPDATE wallet_balances
    SET
        stbf_points = CASE WHEN p_tier = 1 THEN stbf_points - p_amount ELSE stbf_points END,
        serv_dr = CASE WHEN p_tier = 2 THEN serv_dr - p_amount ELSE serv_dr END,
        serv_coin = CASE WHEN p_tier = 3 THEN serv_coin - p_amount ELSE serv_coin END,
        total_spent_stbf = CASE WHEN p_tier = 1 THEN total_spent_stbf + p_amount ELSE total_spent_stbf END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record transaction
    INSERT INTO transactions (
        user_id, type, description, amount,
        balance_after, reference_id, created_at
    ) VALUES (
        p_user_id, 'redeem',
        COALESCE(p_description, format('Redemption of %s %s', p_amount, v_tier_name)),
        -p_amount,
        v_balance - p_amount,
        p_reference_id,
        NOW()
    );

    v_result := jsonb_build_object(
        'success', true,
        'amount_redeemed', p_amount,
        'tier', v_tier_name,
        'new_balance', v_balance - p_amount
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to award points with tier selection
CREATE OR REPLACE FUNCTION award_points(
    p_user_id UUID,
    p_amount DECIMAL,
    p_tier INTEGER DEFAULT 1,
    p_description TEXT DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Update wallet balance
    UPDATE wallet_balances
    SET
        stbf_points = CASE WHEN p_tier = 1 THEN stbf_points + p_amount ELSE stbf_points END,
        serv_dr = CASE WHEN p_tier = 2 THEN serv_dr + p_amount ELSE serv_dr END,
        serv_coin = CASE WHEN p_tier = 3 THEN serv_coin + p_amount ELSE serv_coin END,
        total_earned_stbf = CASE WHEN p_tier = 1 THEN total_earned_stbf + p_amount ELSE total_earned_stbf END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record transaction
    INSERT INTO transactions (
        user_id, type, description, amount, reference_id
    ) VALUES (
        p_user_id, 'earn',
        COALESCE(p_description, format('Earned %s points', p_amount)),
        p_amount,
        p_reference_id
    );
END;
$$ LANGUAGE plpgsql;

-- Create indexes for performance
CREATE INDEX idx_currency_conversions_user ON currency_conversions(user_id);
CREATE INDEX idx_currency_conversions_created ON currency_conversions(created_at DESC);
CREATE INDEX idx_rewards_catalog_active ON rewards_catalog(is_active, required_tier);
CREATE INDEX idx_redemptions_user ON redemptions(user_id);
CREATE INDEX idx_redemptions_status ON redemptions(status);

-- Row Level Security
ALTER TABLE currency_conversions ENABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own conversions" ON currency_conversions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own redemptions" ON redemptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Anyone can view active rewards catalog" ON rewards_catalog
    FOR SELECT USING (is_active = true);