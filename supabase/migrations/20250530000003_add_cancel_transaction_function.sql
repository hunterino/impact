-- Create function to cancel/refund transactions
CREATE OR REPLACE FUNCTION cancel_transaction_atomic(
  p_transaction_id uuid,
  p_reason text DEFAULT 'cancelled'
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  tx_record record;
BEGIN
  -- Get transaction details with lock
  SELECT * INTO tx_record
  FROM transactions
  WHERE id = p_transaction_id
  FOR UPDATE;

  -- Check if transaction exists
  IF tx_record IS NULL THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Only process if transaction is pending or completed
  IF tx_record.status NOT IN ('pending', 'completed') THEN
    -- Already cancelled or in other state
    RETURN false;
  END IF;

  -- For debit transactions, refund the points
  IF tx_record.type = 'debit' THEN
    -- Add points back to wallet
    UPDATE wallet_balance
    SET balance = balance + tx_record.amount,
        updated_at = timezone('utc'::text, now())
    WHERE user_id = tx_record.user_id;

    -- Create compensating credit transaction
    INSERT INTO transactions (
      user_id,
      amount,
      type,
      status,
      order_id,
      metadata
    ) VALUES (
      tx_record.user_id,
      tx_record.amount,
      'credit',
      'completed',
      tx_record.order_id,
      jsonb_build_object(
        'refund_for_transaction', p_transaction_id,
        'refund_reason', p_reason
      )
    );
  END IF;

  -- Mark original transaction as cancelled
  UPDATE transactions
  SET status = 'cancelled',
      updated_at = timezone('utc'::text, now()),
      metadata = metadata || jsonb_build_object('cancellation_reason', p_reason)
  WHERE id = p_transaction_id;

  RETURN true;
END;
$$;
