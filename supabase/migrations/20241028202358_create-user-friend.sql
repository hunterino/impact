-- Create the user_friend table with RLS
CREATE TABLE public.user_friend (
  user_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  PRIMARY KEY (user_id, friend_id),
  friends boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.user_friend ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_user_friend" ON public.user_friend
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
    OR
    (select auth.uid()) = friend_id
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_user_friend" ON public.user_friend
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
  );

CREATE POLICY "update_user_friend" ON public.user_friend
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

CREATE POLICY "delete_user_friend" ON public.user_friend
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );


-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_user_friend_modtime
  BEFORE UPDATE ON public.user_friend
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
