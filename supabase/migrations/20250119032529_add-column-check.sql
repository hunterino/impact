alter table public.project_event_timeslot
  add column checkin boolean not null default false,
  add column checkout boolean not null default false;

alter table public.project_event_commitment
  add project_event_timeslot_id uuid;

ALTER TABLE public.project_event_commitment
ADD CONSTRAINT fk_project_event_timeslot_id_to_project_event_timeslot_id
FOREIGN KEY (project_event_timeslot_id) REFERENCES public.project_event_timeslot(id);
