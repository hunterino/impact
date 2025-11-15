-- Create the team table with RLS
CREATE TABLE public.team (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  published boolean DEFAULT false,
  lead_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.team ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows read access to all users for published teams
CREATE POLICY "read_team" ON public.team
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only be able to see if you are in the team, or it is published
    -- published = false
    -- OR
    -- (select auth.uid()) = owner_id
  );

-- Create a policy that allows insert, update, and delete for the admin
CREATE POLICY "insert_team" ON public.team
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = owner_id OR ((select auth.role()) = 'admin')
  );

CREATE POLICY "update_team" ON public.team
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = owner_id OR ((select auth.role()) = 'admin')
  );

CREATE POLICY "delete_team" ON public.team
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = owner_id OR ((select auth.role()) = 'admin')
  );

-- Create an index on the admin column for better performance
CREATE INDEX team_owner_id_idx ON public.team(owner_id);

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_team_modtime
  BEFORE UPDATE ON public.team
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
