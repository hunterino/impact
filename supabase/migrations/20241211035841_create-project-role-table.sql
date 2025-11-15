-- Create the project project_role table with RLS
CREATE TABLE public.project_role (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,

  name text,
  description text,

  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.project_role ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_project_role" ON public.project_role
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users to manage the project_roles of the project they admin
CREATE POLICY "insert_project_role" ON public.project_role
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_role.project_id
      LIMIT 1
    )
  );

CREATE POLICY "delete_project_role" ON public.project_role
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_role.project_id
      LIMIT 1
    )
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_project_role_modtime
  BEFORE UPDATE ON public.project_role
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.project_role
ADD CONSTRAINT fk_project_id_to_project_role_project_id
FOREIGN KEY (project_id) REFERENCES public.project(id);
