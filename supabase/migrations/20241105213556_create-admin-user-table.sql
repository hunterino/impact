-- Create the profile table with RLS
CREATE TABLE public.admin_user (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role text,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.admin_user ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows profiles to read their own data
CREATE POLICY "read_admin_user" ON public.admin_user
  FOR SELECT TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

-- Create an index on the user_id column for better performance
CREATE INDEX admin_user_user_id_idx ON public.admin_user(user_id);

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_profile_modtime
  BEFORE UPDATE ON public.admin_user
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
