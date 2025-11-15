-- ================================================
-- AUTO-CREATE WALLET FOR NEW USERS
-- ================================================
-- This migration creates a trigger to automatically create
-- a wallet for new users when they sign up

-- Create function to auto-create wallet
CREATE OR REPLACE FUNCTION create_wallet_for_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Create wallet with zero balances
  INSERT INTO public.wallet_balance (
    user_id,
    balance,
    serv_dr_balance,
    serv_coin_balance,
    serv_coin_wallet_active
  ) VALUES (
    NEW.id,
    0,
    0.00,
    0.00,
    false
  );

  RETURN NEW;
END;
$$;

-- Create trigger on auth.users table
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_wallet_for_new_user();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION create_wallet_for_new_user TO authenticated;
