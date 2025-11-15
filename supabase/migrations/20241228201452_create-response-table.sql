-- Create the survey_response table with RLS
CREATE TABLE public.survey_response (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  survey_id uuid NOT NULL,
  survey_question_id uuid NOT NULL,
  question_type text NOT NULL,
  response_text text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.survey_response ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_survey_response" ON public.survey_response
  FOR SELECT TO authenticated, anon
  USING (
    (select auth.uid()) = created_by
    or
    (select auth.uid()) = (
      SELECT owner_id
      FROM survey
      WHERE survey.id = survey_id
      LIMIT 1
    )
  );

-- Create a policy that allows users manage their own data
CREATE POLICY "insert_survey_response" ON public.survey_response
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = created_by
  );

CREATE POLICY "delete_survey_response" ON public.survey_response
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = created_by
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_survey_response_modtime
  BEFORE UPDATE ON public.survey_response
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.survey_response
ADD CONSTRAINT fk_survey_id_to_survey_id
FOREIGN KEY (survey_id) REFERENCES public.survey(id);

ALTER TABLE public.survey_response
ADD CONSTRAINT fk_survey_question_id_to_survey_question_id
FOREIGN KEY (survey_question_id) REFERENCES public.survey_question(id);

ALTER TABLE public.survey_response
ADD CONSTRAINT fk_created_by_to_profile_id
FOREIGN KEY (created_by) REFERENCES public.profile(user_id);
