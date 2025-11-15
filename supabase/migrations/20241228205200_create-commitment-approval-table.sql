-- Create the project_event_commitment_approval table with RLS
CREATE TABLE public.project_event_commitment_approval (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,
  project_event_id uuid NOT NULL,
  project_event_commitment_id uuid NOT NULL,
  user_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.project_event_commitment_approval ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_project_event_commitment_approval" ON public.project_event_commitment_approval
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_project_event_commitment_approval" ON public.project_event_commitment_approval
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_id
      LIMIT 1
    )
  );

CREATE POLICY "delete_project_event_commitment_approval" ON public.project_event_commitment_approval
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_id
      LIMIT 1
    )
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER project_event_commitment_approval_modtime
  BEFORE UPDATE ON public.project_event_commitment_approval
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.project_event_commitment_approval
ADD CONSTRAINT fk_project_id_to_project_id
FOREIGN KEY (project_id) REFERENCES public.project(id);

ALTER TABLE public.project_event_commitment_approval
ADD CONSTRAINT fk_user_id_to_profile_user_id
FOREIGN KEY (user_id) REFERENCES public.profile(user_id);

ALTER TABLE public.project_event_commitment_approval
ADD CONSTRAINT fk_created_by_to_profile_user_id
FOREIGN KEY (created_by) REFERENCES public.profile(user_id);

ALTER TABLE public.project_event_commitment_approval
ADD CONSTRAINT fk_project_event_id_to_project_event_id
FOREIGN KEY (project_event_id) REFERENCES public.project_event(id);

ALTER TABLE public.project_event_commitment_approval
ADD CONSTRAINT fk_project_event_commitment_id_to_project_event_commitment_id
FOREIGN KEY (project_event_commitment_id) REFERENCES public.project_event_commitment(id);
