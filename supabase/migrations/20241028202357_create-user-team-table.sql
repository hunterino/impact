-- Create the user_team table with RLS
CREATE TABLE public.user_team (
  user_id uuid NOT NULL,
  team_id uuid NOT NULL,
  PRIMARY KEY (user_id, team_id),
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.user_team ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_user_team" ON public.user_team
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- (select auth.uid()) = user_id
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_user_team" ON public.user_team
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = user_id
  );
  -- TODO: or admin of project

CREATE POLICY "update_user_team" ON public.user_team
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

CREATE POLICY "delete_user_team" ON public.user_team
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );


-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_user_team_modtime
  BEFORE UPDATE ON public.user_team
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
