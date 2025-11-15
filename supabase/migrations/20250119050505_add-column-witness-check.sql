alter table public.witness
  add column checkin boolean not null default false,
  add column checkout boolean not null default false;
