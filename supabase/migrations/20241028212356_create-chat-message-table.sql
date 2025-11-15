-- Create the chat_message table with RLS
CREATE TABLE public.chat_message (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL, -- user who wrote the chat message
  project_id uuid NOT NULL,
  team_id uuid NOT NULL,
  friend_id uuid NOT NULL,
  tone text,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.chat_message ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_chat_message" ON public.chat_message
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- (select auth.uid()) = user_id
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_chat_message" ON public.chat_message
FOR INSERT TO authenticated
WITH CHECK (
    (select auth.uid()) = user_id
    AND
    (project_id IS NOT NULL)::int +
    (team_id IS NOT NULL)::int +
    (friend_id IS NOT NULL)::int = 1
);

CREATE POLICY "update_chat_message" ON public.chat_message
FOR UPDATE TO authenticated
USING (
    (select auth.uid()) = user_id
    AND
    (project_id IS NOT NULL)::int +
    (team_id IS NOT NULL)::int +
    (friend_id IS NOT NULL)::int = 1
);

CREATE POLICY "delete_chat_message" ON public.chat_message
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = user_id
  );

-- Create an index on the project_id column for better performance
CREATE INDEX chat_message_project_id_idx ON public.chat_message(project_id);

-- Create an index on the team_id column for better performance
CREATE INDEX chat_message_team_id_idx ON public.chat_message(team_id);

-- Create an index on the friend_id column for better performance
CREATE INDEX chat_message_friend_id_idx ON public.chat_message(friend_id);

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_chat_message_modtime
  BEFORE UPDATE ON public.chat_message
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();
