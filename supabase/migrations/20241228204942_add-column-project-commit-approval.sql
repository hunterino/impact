alter table public.project
  add column commitment_survey_id uuid,
  add column approve_commitments boolean NOT NULL DEFAULT false;

ALTER TABLE public.project
ADD CONSTRAINT fk_commitment_survey_id_to_survey_id
FOREIGN KEY (commitment_survey_id) REFERENCES public.survey(id);
