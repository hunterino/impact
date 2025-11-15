-- Create a dedicated role for Vendure
CREATE ROLE vendure_role;

-- Create the vendure schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS vendure;

-- Grant permissions to vendure_role
GRANT USAGE ON SCHEMA vendure TO vendure_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA vendure TO vendure_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA vendure TO vendure_role;
GRANT ALL PRIVILEGES ON SCHEMA vendure TO vendure_role;

-- Allow vendure_role to create new objects in the schema
ALTER DEFAULT PRIVILEGES IN SCHEMA vendure
GRANT ALL PRIVILEGES ON TABLES TO vendure_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA vendure
GRANT ALL PRIVILEGES ON SEQUENCES TO vendure_role;

-- Comment explaining the purpose of this role
COMMENT ON ROLE vendure_role IS 'Role used by Vendure application to access and manage the vendure schema';
