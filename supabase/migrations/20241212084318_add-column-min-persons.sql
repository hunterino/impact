alter table public.project_event_timeslot
  add column timeslot_minimum_count int NOT NULL DEFAULT 0;
