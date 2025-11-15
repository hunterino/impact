-- Create the survey_question table with RLS
CREATE TABLE public.survey_question (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id uuid NOT NULL,
  question_order int NOT NULL,
  question_text text NOT NULL,
  question_type text NOT NULL,
  required boolean NOT NULL,
  closed_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.survey_question ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_survey_question" ON public.survey_question
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_survey_question" ON public.survey_question
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id
      FROM survey
      WHERE survey.id = survey_id
      LIMIT 1
    )
  );

CREATE POLICY "update_survey_question" ON public.survey_question
  FOR UPDATE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id
      FROM survey
      WHERE survey.id = survey_id
      LIMIT 1
    ) AND (
      NOT EXISTS (
        SELECT 1
        FROM public.survey_question sq
        WHERE sq.id = id AND sq.question_text <> question_text
      )
    )
  );

CREATE POLICY "delete_survey_question" ON public.survey_question
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id
      FROM survey
      WHERE survey.id = survey_id
      LIMIT 1
    )
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_survey_question_modtime
  BEFORE UPDATE ON public.survey_question
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.survey_question
ADD CONSTRAINT fk_survey_id_to_survey_id
FOREIGN KEY (survey_id) REFERENCES public.survey(id);
