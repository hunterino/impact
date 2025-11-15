-- Create the project project_event table with RLS
CREATE TABLE public.project_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL,

  -- Column for the date (without time)
  project_event_date date NOT NULL,

  timezone TEXT NOT NULL,

  -- Column for location using Postpublic geography type (e.g., for storing latitude and longitude)
  location gis.GEOGRAPHY(Point, 4326),

  location_name text,
  street_address text,
  city text,
  state text,
  postal_code text,
  country text,

  created_at timestamp with time zone DEFAULT now(),
  created_by uuid NOT NULL,
  updated_at timestamp with time zone DEFAULT now(),
  updated_by uuid
);

-- Enable Row Level Security
ALTER TABLE public.project_event ENABLE ROW LEVEL SECURITY;

-- USE PostGIS index
create index project_event_geo_index
  on public.project_event
  using GIST (location);

-- Create a policy that allows anyone to read the user table
CREATE POLICY "read_project_event" ON public.project_event
  FOR SELECT TO authenticated, anon
  USING (
    true
    -- TODO: should only allow self, and admin of project (and friends of user) to see
    -- auth.jwt() ->> 'user_id' = user_id::text
  );

-- Create a policy that allows users to manage the project_events of the project they admin
CREATE POLICY "insert_project_event" ON public.project_event
  FOR INSERT TO authenticated
  WITH CHECK (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_event.project_id
      LIMIT 1
    )
  );

CREATE POLICY "delete_project_event" ON public.project_event
  FOR DELETE TO authenticated
  USING (
    (select auth.uid()) = (
      SELECT owner_id
      FROM project
      WHERE project.id = project_event.project_id
      LIMIT 1
    )
  );

-- Create a trigger to call the update_modified_columns function
CREATE TRIGGER update_project_event_modtime
  BEFORE UPDATE ON public.project_event
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_columns();

ALTER TABLE public.project_event
ADD CONSTRAINT fk_project_id_to_project_event_project_id
FOREIGN KEY (project_id) REFERENCES public.project(id);
