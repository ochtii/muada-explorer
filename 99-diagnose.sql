-- ============================================================================
-- MUADA EXPLORER - DEBUG SCRIPT
-- ============================================================================
-- Testet ob Profile-Zugriff funktioniert und zeigt alle wichtigen Infos
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. AUTH.USERS - Zeige alle registrierten User
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '👤 AUTH.USERS' as check_type,
  id,
  email,
  raw_user_meta_data->>'username' as username_in_metadata,
  created_at
FROM auth.users
ORDER BY created_at DESC;

-- ────────────────────────────────────────────────────────────────────────────
-- 2. PROFILES - Zeige alle Profile
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '📋 PROFILES' as check_type,
  id,
  username,
  role,
  level,
  points,
  created_at
FROM profiles
ORDER BY created_at DESC;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. RLS STATUS - Ist RLS aktiviert?
-- ────────────────────────────────────────────────────────────────────────────
4. RLS POLICIES - Welche Policies existieren?
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '🔐 RLS POLICIES' as check_type,
  policyname,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'profiles'
ORDER BY policyname;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. TRIGGER - Existiert der handle_new_user Trigger?
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '⚡ TRIGGER' as check_type,
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as enabled
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';

-- ────────────────────────────────────────────────────────────────────────────
-- 6. VERGLEICH - Stimmen auth.users und profiles überein?
-- ────────────────────────────────────────────────────────────────────────────

SELECT 
  '🔍 DIFF CHECK' as check_type,
  'User in auth.users aber NICHT in profiles' as info,
  u.id,
  u.email,
  u.raw_user_meta_data->>'username' as username
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- ────────────────────────────────────────────────────────────────────────────
-- 7. ALLE TABELLEN COUNTS
-- ────────────────────────────────────────────────────────────────────────────

SELECT '📈 COUNTS' as check_type, 'auth.users' as tabelle, COUNT(*) as anzahl FROM auth.users
UNION ALL
SELECT '📈 COUNTS', 'profiles', COUNT(*) FROM profiles
UNION ALL
SELECT '📈 COUNTS', 'locations', COUNT(*) FROM locations
UNION ALL
SELECT '📈 COUNTS', 'visits', COUNT(*) FROM visits
UNION ALL
SELECT '📈 COUNTS', 'reviews', COUNT(*) FROM reviews
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
WENN DU FEHLER SIEHST:
-- ============================================================================
-- 
-- ❌ User in auth.users aber NICHT in profiles
--    → Trigger hat nicht funktioniert!
--    → Lösche den User und registriere dich neu
--    → ODER führe 02-functions.sql aus und erstelle Profile manuell:
--      INSERT INTO profiles (id, username) 
--      VALUES ('USER_ID_HIER', 'username_hier');
-- 
-- ❌ Trigger "on_auth_user_created" existiert nicht
--    → Führe 02-functions.sql aus!
-- 
-- ❌ RLS Policy fehlt
--    → Führe 03-policies.sql aus!
-- 
-- ============================================================================
-- 