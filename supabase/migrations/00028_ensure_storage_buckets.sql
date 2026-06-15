-- ============================================================================
-- Ensure Supabase Storage buckets
-- ============================================================================
-- Makes backend duplication reproducible from migrations only.
-- The storage policies are recreated idempotently so a fresh Supabase project
-- can receive uploads without manual bucket setup.

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('member-photos', 'member-photos', FALSE),
  ('documents', 'documents', FALSE),
  ('organization-assets', 'organization-assets', TRUE)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public;

DROP POLICY IF EXISTS "Users can upload member photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view member photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update member photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete member photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete documents" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view organization assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload organization assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins can update organization assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete organization assets" ON storage.objects;

CREATE POLICY "Users can upload member photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'member-photos'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can view member photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'member-photos'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can update member photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'member-photos'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can delete member photos"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'member-photos'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can upload documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can view documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can update documents"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Users can delete documents"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'documents'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Anyone can view organization assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'organization-assets');

CREATE POLICY "Admins can upload organization assets"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'organization-assets'
  AND get_user_role() = 'admin_national'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Admins can update organization assets"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'organization-assets'
  AND get_user_role() = 'admin_national'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

CREATE POLICY "Admins can delete organization assets"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'organization-assets'
  AND get_user_role() = 'admin_national'
  AND (storage.foldername(name))[1] = get_user_organization_id()::text
);
