-- Seed data for the team table
INSERT INTO public.team (id, owner_id, name, description, published, created_by)
VALUES 
  ('00000000-0000-0000-0000-00000d34d001', '0c62f531-1c21-467b-aa7f-94ab684b50c8', 'Is My Demo Team', 'A sample team', false, '0c62f531-1c21-467b-aa7f-94ab684b50c8'),
  ('00000000-0000-0000-0000-00000d34d002', '00000000-0000-0000-0000-00000c53c001', 'Was My Demo Team', 'A sample team', false, '0c62f531-1c21-467b-aa7f-94ab684b50c8'),
  ('00000000-0000-0000-0000-00000d34d003', '00000000-0000-0000-0000-00000c53c001', 'Not my Demo Team', 'Another sample team', false, '00000000-0000-0000-0000-00000c53c001')
ON CONFLICT (id) 
DO UPDATE SET 
  owner_id = EXCLUDED.owner_id,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  published = EXCLUDED.published,
  created_by = EXCLUDED.created_by;
