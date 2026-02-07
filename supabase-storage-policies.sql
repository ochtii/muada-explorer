-- ============================================================================
-- MUADA EXPLORER - Storage Bucket Policies (IDEMPOTENT - kann mehrmals ausgeführt werden)
-- ============================================================================

-- WICHTIG: Erst die Buckets erstellen, dann dieses Script ausführen!
-- 
-- Buckets erstellen in: Supabase Dashboard > Storage > New Bucket
--   1. Name: "locations" (Private, Max 5MB)
--   2. Name: "avatars" (Public, Max 2MB)

-- ============================================================================
-- LOCATIONS BUCKET POLICIES (Drop if exists, then create)
-- ============================================================================

DROP POLICY IF EXISTS "Authenticated users can upload location images" ON storage.objects;
CREATE POLICY "Authenticated users can upload location images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'locations' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Mitglied+ can view location images" ON storage.objects;
CREATE POLICY "Mitglied+ can view location images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'locations'
  AND has_role_or_higher(auth.uid(), 'mitglied'::app_role)
);

DROP POLICY IF EXISTS "Owner or Mod+ can update location images" ON storage.objects;
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

DROP POLICY IF EXISTS "Owner or Mod+ can delete location images" ON storage.objects;
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
-- AVATARS BUCKET POLICIES (Drop if exists, then create)
-- ============================================================================

DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Anyone can view avatars" ON storage.objects;
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
CREATE POLICY "Users can delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- FERTIG! Dieses Script kann mehrmals ausgeführt werden ohne Fehler! 🎉
-- ============================================================================
