-- RLS is already enabled on storage.objects by default
-- alter table storage.objects enable row level security;

DROP POLICY IF EXISTS "allow_user_uploads_with_specific_path" ON storage.objects;
DROP POLICY IF EXISTS "allow_user_uploads_with_specific_path" ON storage.objects;
DROP POLICY IF EXISTS "allow_user_updates_with_specific_path" ON storage.objects;
DROP POLICY IF EXISTS "allow_user_deletes_with_specific_path" ON storage.objects;

CREATE POLICY "public_images_select_policy"
ON storage.objects
FOR SELECT
TO authenticated, anon
USING (
  true
);

CREATE POLICY "public_images_insert_policy"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  owner = auth.uid() AND
  bucket_id = 'public-images'
);

CREATE POLICY "public_images_update_policy"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  owner = auth.uid() AND
  bucket_id = 'public-images'
)
WITH CHECK (
  owner = auth.uid() AND
  bucket_id = 'public-images'
);

CREATE POLICY "public_images_delete_policy"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  owner = auth.uid() AND
  bucket_id = 'public-images'
);
