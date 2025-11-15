alter table public.witness
  add column commitment_id uuid;

ALTER TABLE public.witness
ADD CONSTRAINT fk_commitment_id_to_commitment_id
FOREIGN KEY (commitment_id) REFERENCES public.project_event_commitment(id);
