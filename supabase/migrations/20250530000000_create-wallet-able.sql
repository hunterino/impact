CREATE TABLE public.wallet_balance (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id)
);

-- Create an index on user_id for faster lookups
CREATE INDEX idx_wallet_balance_user_id ON public.wallet_balance(user_id);

-- Enable RLS
ALTER TABLE public.wallet_balance ENABLE ROW LEVEL SECURITY;

-- Create policy for users to only see their own balance
CREATE POLICY "Users can view their own wallet balance" ON public.wallet_balance
  FOR SELECT USING (auth.uid() = user_id);
