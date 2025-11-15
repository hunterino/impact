alter table public.profile
  add column bio text;

alter table public.sensitive_profile
  add column accepted_at timestamp with time zone,
  drop column accepted_terms;
