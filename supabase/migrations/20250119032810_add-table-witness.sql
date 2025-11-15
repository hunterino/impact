-- Create the profile table with RLS
CREATE TABLE public.witness (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid,
  manual_user_id uuid,
  witnessed_user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.witness ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows profiles to read their own data
CREATE POLICY "read_profile" ON public.witness
  FOR SELECT TO authenticated
  USING (
   (select auth.uid()) = created_by
  );

-- Create a policy that allows profiles manage their own data
CREATE POLICY "insert_profile" ON public.witness
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = created_by
  );

-- Create an index on the user_id column for better performance
CREATE INDEX created_by_id_idx ON public.witness(created_by);

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_profile_modtime
  BEFORE UPDATE ON public.witness
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.witness
ADD CONSTRAINT fk_project_id_to_project_id
FOREIGN KEY (project_id) REFERENCES public.project(id);
