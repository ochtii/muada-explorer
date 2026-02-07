-- ============================================================================
-- MUADA EXPLORER - Storage Bucket Policies
-- Run these AFTER creating the buckets in Supabase Dashboard
-- ============================================================================

-- INSTRUCTIONS:
-- 1. Go to Supabase Dashboard > Storage
-- 2. Create buckets:
--    - Name: "locations" (Private, Max 5MB, MIME: image/jpeg, image/png, image/webp)
--    - Name: "avatars" (Public, Max 2MB, MIME: image/jpeg, image/png, image/webp)
-- 3. Then run these policies in the SQL Editor

-- ============================================================================
-- LOCATIONS BUCKET POLICIES
-- ============================================================================

-- Allow authenticated users to upload location images
CREATE POLICY "Authenticated users can upload location images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'locations' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Mitglied+ can view location images
CREATE POLICY "Mitglied+ can view location images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'locations'
  AND has_role_or_higher(auth.uid(), 'mitglied'::app_role)
);

-- Owner or Mod+ can update their images
CREATE POLICY "Owner or Mod+ can update location images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'locations'
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR has_role_or_higher(auth.uid(), 'mod'::app_role)
  )
);

-- Owner or Mod+ can delete images
CREATE POLICY "Owner or Mod+ can delete location images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'locations'
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR has_role_or_higher(auth.uid(), 'mod'::app_role)
  )
);

-- ============================================================================
-- AVATARS BUCKET POLICIES
-- ============================================================================

-- Allow authenticated users to upload avatars
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view avatars (public bucket)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own avatar
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
