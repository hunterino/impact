-- ================================================
-- REWARDS MARKETPLACE DATABASE SCHEMA
-- ================================================
-- This migration creates the complete rewards marketplace system
-- including rewards, redemptions, and multi-currency wallet support

-- ================================================
-- 1. UPDATE WALLET TABLE WITH MULTI-CURRENCY SUPPORT
-- ================================================

-- Add SERV DR and SERV Coin balances to wallet
ALTER TABLE public.wallet_balance
  ADD COLUMN IF NOT EXISTS serv_dr_balance decimal(10,2) DEFAULT 0.00 NOT NULL,
  ADD COLUMN IF NOT EXISTS serv_coin_balance decimal(10,2) DEFAULT 0.00 NOT NULL,
  ADD COLUMN IF NOT EXISTS serv_coin_wallet_active boolean DEFAULT false NOT NULL;

-- Add check constraints for non-negative balances
ALTER TABLE public.wallet_balance
  ADD CONSTRAINT balance_non_negative CHECK (balance >= 0),
  ADD CONSTRAINT serv_dr_balance_non_negative CHECK (serv_dr_balance >= 0),
  ADD CONSTRAINT serv_coin_balance_non_negative CHECK (serv_coin_balance >= 0);

-- ================================================
-- 2. CREATE REWARDS TABLE
-- ================================================

CREATE TABLE public.rewards (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  title text NOT NULL,
  description text,
  category text NOT NULL CHECK (category IN ('Retail', 'Dining', 'Entertainment', 'Gift Cards', 'Travel', 'Services')),
  serv_dr_cost decimal(10,2) NOT NULL CHECK (serv_dr_cost > 0),
  retail_value decimal(10,2),
  image_url text,
  terms_and_conditions text,
  vendor_name text,
  vendor_id uuid,
  stock_quantity integer DEFAULT -1, -- -1 means unlimited
  is_active boolean DEFAULT true NOT NULL,
  metadata jsonb DEFAULT '{}',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_by uuid REFERENCES auth.users(id),
  updated_by uuid REFERENCES auth.users(id)
);

-- Create indexes for rewards
CREATE INDEX idx_rewards_category ON public.rewards(category);
CREATE INDEX idx_rewards_is_active ON public.rewards(is_active);
CREATE INDEX idx_rewards_serv_dr_cost ON public.rewards(serv_dr_cost);
CREATE INDEX idx_rewards_created_at ON public.rewards(created_at DESC);

-- Enable RLS for rewards
ALTER TABLE public.rewards ENABLE ROW LEVEL SECURITY;

-- Rewards are publicly viewable if active
CREATE POLICY "Active rewards are viewable by all authenticated users" ON public.rewards
  FOR SELECT USING (is_active = true AND auth.role() = 'authenticated');

-- Only admins can insert/update/delete rewards
CREATE POLICY "Only admins can manage rewards" ON public.rewards
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.admin_user
      WHERE user_id = auth.uid()
    )
  );

-- Add updated_at trigger for rewards
CREATE TRIGGER update_rewards_updated_at
  BEFORE UPDATE ON public.rewards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 3. CREATE REDEMPTIONS TABLE
-- ================================================

CREATE TABLE public.redemptions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reward_id uuid NOT NULL REFERENCES public.rewards(id),
  serv_dr_cost decimal(10,2) NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'fulfilled', 'cancelled', 'expired')),
  redemption_code text UNIQUE,
  fulfillment_instructions text,
  redemption_date timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  fulfilled_at timestamp with time zone,
  expires_at timestamp with time zone,
  metadata jsonb DEFAULT '{}',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes for redemptions
CREATE INDEX idx_redemptions_user_id ON public.redemptions(user_id);
CREATE INDEX idx_redemptions_reward_id ON public.redemptions(reward_id);
CREATE INDEX idx_redemptions_status ON public.redemptions(status);
CREATE INDEX idx_redemptions_code ON public.redemptions(redemption_code) WHERE redemption_code IS NOT NULL;
CREATE INDEX idx_redemptions_created_at ON public.redemptions(created_at DESC);

-- Enable RLS for redemptions
ALTER TABLE public.redemptions ENABLE ROW LEVEL SECURITY;

-- Users can view their own redemptions
CREATE POLICY "Users can view their own redemptions" ON public.redemptions
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create redemptions via function only
CREATE POLICY "Users can create redemptions via function" ON public.redemptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Add updated_at trigger for redemptions
CREATE TRIGGER update_redemptions_updated_at
  BEFORE UPDATE ON public.redemptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 4. UPDATE TRANSACTIONS TABLE FOR MULTI-CURRENCY
-- ================================================

-- Add transaction category and currency type
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS category text DEFAULT 'points' CHECK (category IN ('points', 'serv_dr', 'serv_coin', 'conversion', 'redemption')),
  ADD COLUMN IF NOT EXISTS currency text DEFAULT 'points' CHECK (currency IN ('points', 'serv_dr', 'serv_coin')),
  ADD COLUMN IF NOT EXISTS conversion_rate decimal(10,4);

-- Add index on category
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category);

-- ================================================
-- 5. CREATE CURRENCY CONVERSION FUNCTIONS
-- ================================================

-- Conversion rates (can be adjusted)
-- 100 STBF Points = 1 SERV DR
-- 1 SERV DR = 1 SERV Coin (after wallet activation)

-- Function to convert Points to SERV DR
CREATE OR REPLACE FUNCTION convert_points_to_serv_dr(
  p_user_id uuid,
  p_points_amount integer
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_points_balance integer;
  serv_dr_amount decimal(10,2);
  transaction_id uuid;
  conversion_rate constant decimal := 100.0; -- 100 points = 1 SERV DR
BEGIN
  -- Calculate SERV DR amount
  serv_dr_amount := p_points_amount / conversion_rate;

  IF serv_dr_amount <= 0 THEN
    RAISE EXCEPTION 'Conversion amount too small. Minimum 100 points required.';
  END IF;

  -- Lock wallet for update
  SELECT balance INTO current_points_balance
  FROM wallet_balance
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Validate sufficient balance
  IF current_points_balance IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  IF current_points_balance < p_points_amount THEN
    RAISE EXCEPTION 'Insufficient points. Current: %, Required: %', current_points_balance, p_points_amount;
  END IF;

  -- Deduct points and add SERV DR
  UPDATE wallet_balance
  SET
    balance = balance - p_points_amount,
    serv_dr_balance = serv_dr_balance + serv_dr_amount,
    updated_at = timezone('utc'::text, now())
  WHERE user_id = p_user_id;

  -- Create transaction record
  INSERT INTO transactions (
    user_id,
    amount,
    type,
    category,
    currency,
    status,
    conversion_rate,
    metadata
  ) VALUES (
    p_user_id,
    p_points_amount,
    'debit',
    'conversion',
    'points',
    'completed',
    conversion_rate,
    jsonb_build_object(
      'conversion_type', 'points_to_serv_dr',
      'points_deducted', p_points_amount,
      'serv_dr_credited', serv_dr_amount
    )
  ) RETURNING id INTO transaction_id;

  RETURN transaction_id;
END;
$$;

-- Function to convert SERV DR to SERV Coin
CREATE OR REPLACE FUNCTION convert_serv_dr_to_serv_coin(
  p_user_id uuid,
  p_serv_dr_amount decimal(10,2)
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_serv_dr_balance decimal(10,2);
  wallet_active boolean;
  serv_coin_amount decimal(10,2);
  transaction_id uuid;
  conversion_rate constant decimal := 1.0; -- 1 SERV DR = 1 SERV Coin
BEGIN
  -- Calculate SERV Coin amount
  serv_coin_amount := p_serv_dr_amount * conversion_rate;

  IF serv_coin_amount <= 0 THEN
    RAISE EXCEPTION 'Conversion amount must be greater than 0';
  END IF;

  -- Lock wallet for update
  SELECT serv_dr_balance, serv_coin_wallet_active
  INTO current_serv_dr_balance, wallet_active
  FROM wallet_balance
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Validate wallet exists and is active
  IF current_serv_dr_balance IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  IF NOT wallet_active THEN
    RAISE EXCEPTION 'SERV Coin wallet must be activated before conversion';
  END IF;

  IF current_serv_dr_balance < p_serv_dr_amount THEN
    RAISE EXCEPTION 'Insufficient SERV DR. Current: %, Required: %', current_serv_dr_balance, p_serv_dr_amount;
  END IF;

  -- Deduct SERV DR and add SERV Coin
  UPDATE wallet_balance
  SET
    serv_dr_balance = serv_dr_balance - p_serv_dr_amount,
    serv_coin_balance = serv_coin_balance + serv_coin_amount,
    updated_at = timezone('utc'::text, now())
  WHERE user_id = p_user_id;

  -- Create transaction record
  INSERT INTO transactions (
    user_id,
    amount,
    type,
    category,
    currency,
    status,
    conversion_rate,
    metadata
  ) VALUES (
    p_user_id,
    p_serv_dr_amount::integer,
    'debit',
    'conversion',
    'serv_dr',
    'completed',
    conversion_rate,
    jsonb_build_object(
      'conversion_type', 'serv_dr_to_serv_coin',
      'serv_dr_deducted', p_serv_dr_amount,
      'serv_coin_credited', serv_coin_amount
    )
  ) RETURNING id INTO transaction_id;

  RETURN transaction_id;
END;
$$;

-- Function to activate SERV Coin wallet
CREATE OR REPLACE FUNCTION activate_serv_coin_wallet(
  p_user_id uuid
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update wallet to activate SERV Coin
  UPDATE wallet_balance
  SET
    serv_coin_wallet_active = true,
    updated_at = timezone('utc'::text, now())
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  RETURN true;
END;
$$;

-- ================================================
-- 6. CREATE REWARD REDEMPTION FUNCTION
-- ================================================

CREATE OR REPLACE FUNCTION redeem_reward_atomic(
  p_user_id uuid,
  p_reward_id uuid
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_serv_dr_balance decimal(10,2);
  reward_cost decimal(10,2);
  reward_title text;
  reward_stock integer;
  reward_is_active boolean;
  redemption_id uuid;
  transaction_id uuid;
  generated_code text;
BEGIN
  -- Get reward details and lock for stock check
  SELECT serv_dr_cost, title, stock_quantity, is_active
  INTO reward_cost, reward_title, reward_stock, reward_is_active
  FROM rewards
  WHERE id = p_reward_id
  FOR UPDATE;

  -- Validate reward exists and is active
  IF reward_cost IS NULL THEN
    RAISE EXCEPTION 'Reward not found';
  END IF;

  IF NOT reward_is_active THEN
    RAISE EXCEPTION 'Reward is no longer available';
  END IF;

  -- Check stock (if not unlimited)
  IF reward_stock != -1 AND reward_stock <= 0 THEN
    RAISE EXCEPTION 'Reward is out of stock';
  END IF;

  -- Lock wallet and check balance
  SELECT serv_dr_balance INTO current_serv_dr_balance
  FROM wallet_balance
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF current_serv_dr_balance IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  IF current_serv_dr_balance < reward_cost THEN
    RAISE EXCEPTION 'Insufficient SERV DR. Current: %, Required: %', current_serv_dr_balance, reward_cost;
  END IF;

  -- Deduct SERV DR from wallet
  UPDATE wallet_balance
  SET
    serv_dr_balance = serv_dr_balance - reward_cost,
    updated_at = timezone('utc'::text, now())
  WHERE user_id = p_user_id;

  -- Decrement stock (if not unlimited)
  IF reward_stock != -1 THEN
    UPDATE rewards
    SET stock_quantity = stock_quantity - 1,
        updated_at = timezone('utc'::text, now())
    WHERE id = p_reward_id;
  END IF;

  -- Generate unique redemption code
  generated_code := 'RDM-' || upper(substring(md5(random()::text) from 1 for 8));

  -- Create redemption record
  INSERT INTO redemptions (
    user_id,
    reward_id,
    serv_dr_cost,
    status,
    redemption_code,
    expires_at,
    metadata
  ) VALUES (
    p_user_id,
    p_reward_id,
    reward_cost,
    'pending',
    generated_code,
    timezone('utc'::text, now()) + interval '30 days',
    jsonb_build_object('reward_title', reward_title)
  ) RETURNING id INTO redemption_id;

  -- Create transaction record
  INSERT INTO transactions (
    user_id,
    amount,
    type,
    category,
    currency,
    status,
    metadata
  ) VALUES (
    p_user_id,
    reward_cost::integer,
    'debit',
    'redemption',
    'serv_dr',
    'completed',
    jsonb_build_object(
      'redemption_id', redemption_id,
      'reward_id', p_reward_id,
      'reward_title', reward_title,
      'redemption_code', generated_code
    )
  ) RETURNING id INTO transaction_id;

  RETURN redemption_id;
END;
$$;

-- ================================================
-- 7. CREATE HELPER FUNCTIONS
-- ================================================

-- Function to get user wallet summary
CREATE OR REPLACE FUNCTION get_user_wallet_summary(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  wallet_data jsonb;
BEGIN
  SELECT jsonb_build_object(
    'user_id', user_id,
    'points_balance', balance,
    'serv_dr_balance', serv_dr_balance,
    'serv_coin_balance', serv_coin_balance,
    'serv_coin_wallet_active', serv_coin_wallet_active,
    'updated_at', updated_at
  ) INTO wallet_data
  FROM wallet_balance
  WHERE user_id = p_user_id;

  IF wallet_data IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  RETURN wallet_data;
END;
$$;

-- ================================================
-- 8. GRANT EXECUTE PERMISSIONS
-- ================================================

GRANT EXECUTE ON FUNCTION convert_points_to_serv_dr TO authenticated;
GRANT EXECUTE ON FUNCTION convert_serv_dr_to_serv_coin TO authenticated;
GRANT EXECUTE ON FUNCTION activate_serv_coin_wallet TO authenticated;
GRANT EXECUTE ON FUNCTION redeem_reward_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_wallet_summary TO authenticated;
