-- ============================================================================
-- EAB Backend - 00006 Storage Buckets
-- ============================================================================
-- Configuration des buckets Supabase Storage
-- ============================================================================

-- ============================================================================
-- CREATE STORAGE BUCKETS
-- ============================================================================

-- Note: Bucket creation is done via Supabase Dashboard or API
-- This script contains the RLS policies for storage

-- Buckets to create in Dashboard:
-- 1. member-photos (private)
-- 2. documents (private) 
-- 3. organization-assets (public)

-- ============================================================================
-- STORAGE POLICIES FOR member-photos BUCKET
-- ============================================================================

-- Users can upload photos for members in their organization
CREATE POLICY "Users can upload member photos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'member-photos'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can view member photos from their organization
CREATE POLICY "Users can view member photos"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'member-photos'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can update member photos from their organization
CREATE POLICY "Users can update member photos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'member-photos'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can delete member photos from their organization
CREATE POLICY "Users can delete member photos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'member-photos'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- ============================================================================
-- STORAGE POLICIES FOR documents BUCKET
-- ============================================================================

-- Users can upload documents for their organization
CREATE POLICY "Users can upload documents"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can view documents from their organization
CREATE POLICY "Users can view documents"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can update documents from their organization
CREATE POLICY "Users can update documents"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Users can delete documents from their organization
CREATE POLICY "Users can delete documents"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- ============================================================================
-- STORAGE POLICIES FOR organization-assets BUCKET (Public)
-- ============================================================================

-- Anyone can view organization assets (logos, etc.)
CREATE POLICY "Anyone can view organization assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'organization-assets');

-- Only admins can upload organization assets
CREATE POLICY "Admins can upload organization assets"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'organization-assets'
    AND get_user_role() = 'admin_national'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Only admins can update organization assets
CREATE POLICY "Admins can update organization assets"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'organization-assets'
    AND get_user_role() = 'admin_national'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);

-- Only admins can delete organization assets
CREATE POLICY "Admins can delete organization assets"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'organization-assets'
    AND get_user_role() = 'admin_national'
    AND (storage.foldername(name))[1] = get_user_organization_id()::text
);
