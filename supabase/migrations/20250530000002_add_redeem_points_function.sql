-- Create atomic function for point redemption
CREATE OR REPLACE FUNCTION redeem_points_atomic(
  p_user_id uuid,
  p_amount integer,
  p_order_id text DEFAULT NULL,
  p_confirmation_code text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_balance integer;
  transaction_id uuid;
BEGIN
  -- Lock the wallet balance row to prevent concurrent modifications
  SELECT balance INTO current_balance
  FROM wallet_balance
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Check if user has sufficient balance
  IF current_balance IS NULL THEN
    RAISE EXCEPTION 'Wallet not found for user';
  END IF;

  IF current_balance < p_amount THEN
    RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', current_balance, p_amount;
  END IF;

  -- Deduct points from wallet
  UPDATE wallet_balance
  SET balance = balance - p_amount,
      updated_at = timezone('utc'::text, now())
  WHERE user_id = p_user_id;

  -- Create transaction record
  INSERT INTO transactions (
    user_id,
    amount,
    type,
    status,
    order_id,
    confirmation_code,
    metadata
  ) VALUES (
    p_user_id,
    p_amount,
    'debit',
    'pending',
    p_order_id,
    p_confirmation_code,
    jsonb_build_object('redemption_type', 'vendure_payment')
  ) RETURNING id INTO transaction_id;

  RETURN transaction_id;
END;
$$;
