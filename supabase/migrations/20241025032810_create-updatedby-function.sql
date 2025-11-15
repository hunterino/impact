-- Create a function to automatically update the updated_at timestamp and updated_by
CREATE OR REPLACE FUNCTION update_modified_columns()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.updated_by = (auth.jwt() ->> 'user_id')::uuid;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public;
