-- Seed data for the admnin table
INSERT INTO public.admin_user (id, user_id, role, created_by)
VALUES 
  ('00000000-0000-0000-0000-0000ad313001', '0c62f531-1c21-467b-aa7f-94ab684b50c8', 'admin', '00000000-0000-0000-0000-00000c53c001'),
  ('00000000-0000-0000-0000-0000ad313002', '00000000-0000-0000-0000-00000c53c001', 'admin', '00000000-0000-0000-0000-00000c53c001')
ON CONFLICT (id) 
DO UPDATE SET 
  user_id = EXCLUDED.user_id,
  role = EXCLUDED.role,
  created_by = EXCLUDED.created_by;
