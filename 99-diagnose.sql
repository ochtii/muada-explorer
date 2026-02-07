-- ============================================================================
-- MUADA EXPLORER - DIAGNOSE SCRIPT
-- ============================================================================
-- Zeigt Status der Datenbank und prüft ob alles richtig eingerichtet ist
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. TABELLEN ÜBERSICHT
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '📊 TABELLEN' as check_type,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('profiles', 'locations', 'visits', 'reviews')
ORDER BY tablename;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. ZÄHLER
-- ────────────────────────────────────────────────────────────────────────────

SELECT '📈 ZÄHLER' as check_type, 'auth.users' as tabelle, COUNT(*) as anzahl FROM auth.users
UNION ALL
SELECT '📈 ZÄHLER', 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT '📈 ZÄHLER', 'locations', COUNT(*) FROM locations
UNION ALL
SELECT '📈 ZÄHLER', 'locations (approved)', COUNT(*) FROM locations WHERE approved = true
UNION ALL
SELECT '📈 ZÄHLER', 'visits', COUNT(*) FROM visits
UNION ALL
SELECT '📈 ZÄHLER', 'reviews', COUNT(*) FROM reviews;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. TRIGGER ÜBERSICHT
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '⚡ TRIGGERS' as check_type,
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as enabled
FROM pg_trigger
WHERE tgname IN (
  'on_auth_user_created',
  'profiles_updated_at',
  'locations_updated_at',
  'reviews_updated_at',
  'visits_update_gamification',
  'locations_update_gamification',
  'reviews_update_gamification',
  'visits_update_location_stats',
  'reviews_update_location_stats'
)
ORDER BY tgname;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. FUNCTIONS ÜBERSICHT
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '⚙️ FUNCTIONS' as check_type,
  proname as function_name,
  pronargs as num_args
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'handle_new_user',
    'update_timestamp',
    'calculate_user_points',
    'calculate_level',
    'update_user_gamification',
    'update_location_stats',
    'get_user_role'
  )
ORDER BY proname;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. STORAGE BUCKETS
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '🗂️ STORAGE' as check_type,
  name as bucket_name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE name IN ('locations', 'avatars')
ORDER BY name;

-- ────────────────────────────────────────────────────────────────────────────
-- 6. USER ÜBERSICHT (wenn vorhanden)
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '👥 USERS' as check_type,
  p.username,
  p.role,
  p.level,
  p.points,
  p.created_at,
  (SELECT COUNT(*) FROM locations WHERE submitted_by = p.id) as locations_submitted,
  (SELECT COUNT(*) FROM visits WHERE user_id = p.id) as visits_count,
  (SELECT COUNT(*) FROM reviews WHERE user_id = p.id) as reviews_count
FROM profiles p
ORDER BY p.created_at DESC
LIMIT 10;

-- ────────────────────────────────────────────────────────────────────────────
-- 7. RLS POLICIES ÜBERSICHT
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '🔒 RLS POLICIES' as check_type,
  schemaname,
  tablename,
  policyname,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================================
-- FERTIG! ✓
-- ============================================================================
