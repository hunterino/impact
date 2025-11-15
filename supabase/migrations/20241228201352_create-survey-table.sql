-- Create the survey table with RLS
CREATE TABLE public.survey (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  name text NOT NULL,
  description text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.survey ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_survey" ON public.survey
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_survey" ON public.survey
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = owner_id
  );

CREATE POLICY "delete_survey" ON public.survey
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = owner_id
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_survey_modtime
  BEFORE UPDATE ON public.survey
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
