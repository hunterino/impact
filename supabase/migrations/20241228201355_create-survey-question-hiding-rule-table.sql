-- Create the survey_question_hiding_rule table with RLS
CREATE TABLE public.survey_question_hiding_rule (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id uuid NOT NULL,
  survey_question_id uuid NOT NULL,
  response_survey_question_id uuid NOT NULL,
  response_text_indicating_to_hide text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.survey_question_hiding_rule ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_survey_question_hiding_rule" ON public.survey_question_hiding_rule
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_survey_question_hiding_rule" ON public.survey_question_hiding_rule
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id
      FROM survey
      WHERE survey.id = survey_id
      LIMIT 1
    )
  );

CREATE POLICY "delete_survey_question_hiding_rule" ON public.survey_question_hiding_rule
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
CREATE TRIGGER update_survey_question_hiding_rule_modtime
  BEFORE UPDATE ON public.survey_question_hiding_rule
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.survey_question_hiding_rule
ADD CONSTRAINT fk_survey_id_to_survey_id
FOREIGN KEY (survey_id) REFERENCES public.survey(id);

ALTER TABLE public.survey_question_hiding_rule
ADD CONSTRAINT fk_survey_question_id_to_survey_question_id
FOREIGN KEY (survey_question_id) REFERENCES public.survey_question(id);
