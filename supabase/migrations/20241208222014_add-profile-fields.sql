alter table public.sensitive_profile
  add column first_name text,
  add column last_name text,
  add column accepted_terms bool;

ALTER TABLE public.sensitive_profile
ADD CONSTRAINT fk_user_id_to_profile_user_id
FOREIGN KEY (user_id) REFERENCES public.profile(user_id);
