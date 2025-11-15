-- Create the profile table with RLS
CREATE TABLE public.sensitive_profile (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  iss text, -- Auth0 issuer
  sub text, -- Auth0 subject
  email text,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.sensitive_profile ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows profiles to read their own data
CREATE POLICY "read_profile" ON public.sensitive_profile
  FOR SELECT TO authenticated
  USING (
   (select auth.uid()) = user_id
  );

-- Create a policy that allows profiles manage their own data
CREATE POLICY "insert_profile" ON public.sensitive_profile
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
  );

CREATE POLICY "update_profile" ON public.sensitive_profile
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

CREATE POLICY "delete_profile" ON public.sensitive_profile
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

-- Create an index on the user_id column for better performance
CREATE INDEX sensitive_profile_user_id_idx ON public.sensitive_profile(user_id);

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_profile_modtime
  BEFORE UPDATE ON public.sensitive_profile
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
