-- ============================================================================
-- MUADA EXPLORER - STORAGE BUCKETS & POLICIES
-- ============================================================================
-- Erstellt Storage Buckets für Fotos und definiert Zugriffspolicies
-- Kann mehrmals ausgeführt werden (idempotent)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- HINWEIS: BUCKETS MANUELL ERSTELLEN!
-- ────────────────────────────────────────────────────────────────────────────
-- Storage Buckets können NICHT via SQL erstellt werden!
-- Gehe zu: https://supabase.com/dashboard/project/hcjkxiwmufabnztabbeb/storage/buckets
-- 
-- Erstelle manuell:
-- 1. Bucket: "locations"
--    - Public: NEIN (privat!)
--    - File size limit: 5 MB
--    - Allowed MIME types: image/*
-- 
-- 2. Bucket: "avatars"
--    - Public: JA
--    - File size limit: 2 MB
--    - Allowed MIME types: image/*
-- ────────────────────────────────────────────────────────────────────────────

-- ────────────────────────────────────────────────────────────────────────────
-- 1. LOCATIONS BUCKET POLICIES (PRIVAT)
-- ────────────────────────────────────────────────────────────────────────────
-- Fotos von Lost Places - nur für Mods/Webmaster sichtbar!

-- Alte Policies löschen
DROP POLICY IF EXISTS "Mods/Webmaster können Location-Fotos sehen" ON storage.objects;
DROP POLICY IF EXISTS "User können Location-Fotos hochladen" ON storage.objects;
DROP POLICY IF EXISTS "User können ihre eigenen Location-Fotos löschen" ON storage.objects;
DROP POLICY IF EXISTS "Mods können alle Location-Fotos löschen" ON storage.objects;

-- Mods/Webmaster können alle Location-Fotos sehen
CREATE POLICY "Mods/Webmaster können Location-Fotos sehen"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'locations'
    AND (
      SELECT role FROM profiles WHERE id = auth.uid()
    ) IN ('webmaster', 'moderator')
  );

-- User können Location-Fotos hochladen (zu ihren eigenen Visits)
CREATE POLICY "User können Location-Fotos hochladen"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'locations'
    AND (
      SELECT role FROM profiles WHERE id = auth.uid()
    ) NOT IN ('banned')
    -- Dateiname muss mit user_id beginnen: {user_id}/{location_id}/{filename}
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- User können ihre eigenen Location-Fotos löschen
CREATE POLICY "User können ihre eigenen Location-Fotos löschen"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'locations'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Mods/Webmaster können alle Location-Fotos löschen
CREATE POLICY "Mods können alle Location-Fotos löschen"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'locations'
    AND (
      SELECT role FROM profiles WHERE id = auth.uid()
    ) IN ('webmaster', 'moderator')
  );

-- ────────────────────────────────────────────────────────────────────────────
-- 2. AVATARS BUCKET POLICIES (PUBLIC)
-- ────────────────────────────────────────────────────────────────────────────
-- Profilbilder - öffentlich sichtbar

DROP POLICY IF EXISTS "Avatars sind öffentlich sichtbar" ON storage.objects;
DROP POLICY IF EXISTS "User können eigenen Avatar hochladen" ON storage.objects;
DROP POLICY IF EXISTS "User können eigenen Avatar updaten" ON storage.objects;
DROP POLICY IF EXISTS "User können eigenen Avatar löschen" ON storage.objects;

-- Jeder kann Avatars sehen (bucket ist public)
CREATE POLICY "Avatars sind öffentlich sichtbar"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'avatars');

-- User können eigenen Avatar hochladen
CREATE POLICY "User können eigenen Avatar hochladen"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (
      SELECT role FROM profiles WHERE id = auth.uid()
    ) NOT IN ('banned')
    -- Dateiname muss user_id sein: {user_id}.jpg
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- User können eigenen Avatar updaten
CREATE POLICY "User können eigenen Avatar updaten"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- User können eigenen Avatar löschen
CREATE POLICY "User können eigenen Avatar löschen"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ────────────────────────────────────────────────────────────────────────────
-- STRUKTUR DER STORAGE PATHS
-- ────────────────────────────────────────────────────────────────────────────
-- 
-- locations/
--   {user_id}/
--     {location_id}/
--       photo1.jpg
--       photo2.jpg
--       ...
-- 
-- avatars/
--   {user_id}.jpg
-- 
-- ────────────────────────────────────────────────────────────────────────────

-- ============================================================================
-- FERTIG! Storage Policies erstellt ✓
-- ACHTUNG: Buckets müssen noch MANUELL im Dashboard erstellt werden!
-- ============================================================================
