-- Seed data for the project table
INSERT INTO public.project (id, owner_id, name, description, published, created_by)
VALUES 
  ('00000000-0000-0000-0000-00bb0b3b1001', '0c62f531-1c21-467b-aa7f-94ab684b50c8', 'Is My Demo Project', 'A sample project for testing', false, '0c62f531-1c21-467b-aa7f-94ab684b50c8'),
  ('00000000-0000-0000-0000-00bb0b3b1002', '00000000-0000-0000-0000-00000c53c001', 'Was My Demo Project', 'A sample project for testing', false, '0c62f531-1c21-467b-aa7f-94ab684b50c8'),
  ('00000000-0000-0000-0000-00bb0b3b1003', '00000000-0000-0000-0000-00000c53c002', 'Not My Demo Project', 'Another sample project', false, '00000000-0000-0000-0000-00000c53c001'),
  ('00000000-0000-0000-0000-00bb0b3b1004', '00000000-0000-0000-0000-00000c53c002', 'Published Demo Project', 'Hidden sample project', true, '00000000-0000-0000-0000-00000c53c001'),
  ('00000000-0000-0000-0000-00bb0b3b1005', '00000000-0000-0000-0000-00000c53c002', 'Another Published Demo Project', 'Hidden sample project 2', true, '00000000-0000-0000-0000-00000c53c001'),
  ('00000000-0000-0000-0000-00bb0b3b1006', '0c62f531-1c21-467b-aa7f-94ab684b50c8', 'My Published Demo Project', 'Hidden sample project 3', true, '00000000-0000-0000-0000-00000c53c001')
ON CONFLICT (id) 
DO UPDATE SET 
  owner_id = EXCLUDED.owner_id,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  published = EXCLUDED.published,
  created_by = EXCLUDED.created_by;
