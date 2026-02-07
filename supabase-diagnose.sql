-- ============================================================================
-- MUADA EXPLORER - Diagnose Script
-- Zeigt detaillierte Informationen über Setup-Status
-- ============================================================================

-- 1. Prüfe ob handle_new_user Funktion existiert
SELECT 
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') 
    THEN '✅ handle_new_user Function EXISTS'
    ELSE '❌ handle_new_user Function MISSING - KRITISCH!'
  END as status;

-- 2. Prüfe ob Trigger auf auth.users existiert
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_trigger 
      WHERE tgname = 'on_auth_user_created' 
      AND tgrelid = 'auth.users'::regclass
    )
    THEN '✅ on_auth_user_created Trigger EXISTS auf auth.users'
    ELSE '❌ on_auth_user_created Trigger MISSING - KRITISCH!'
  END as status;

-- 3. Zeige alle User in auth.users (sollte leer sein wenn Registrierung fehlschlägt)
SELECT 
  'auth.users Count' as info,
  COUNT(*) as count
FROM auth.users;

-- 4. Zeige alle User in profiles (sollte gleich viele sein wie auth.users)
SELECT 
  'profiles Count' as info,
  COUNT(*) as count
FROM profiles;

-- 5. Zeige letzte 5 User aus auth.users (zum Vergleich)
SELECT 
  id,
  email,
  raw_user_meta_data->>'username' as username_from_metadata,
  created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 6. Zeige letzte 5 Profile
SELECT 
  id,
  username,
  role,
  created_at
FROM profiles
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- INTERPRETATION:
-- ============================================================================
-- 
-- Wenn auth.users Count > profiles Count:
--   → Trigger funktioniert NICHT! Profile werden nicht automatisch erstellt!
--   → Lösung: Trigger neu erstellen (siehe unten)
--
-- Wenn beide Counts gleich sind:
--   → Setup ist OK, Problem liegt woanders
--
-- ============================================================================

-- ============================================================================
-- MUADA EXPLORER - Diagnose Script
-- Zeigt an, was bereits existiert und was noch fehlt
-- ============================================================================

-- 1. Überprüfe ob Enums existieren
SELECT 
  'app_role Enum' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
  'location_category Enum' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_type WHERE typname = 'location_category') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 2. Überprüfe ob Tabellen existieren
SELECT 
  'profiles Table' as item,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'profiles') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
  'locations Table' as item,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'locations') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
  'visits Table' as item,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'visits') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
  'reviews Table' as item,
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 3. WICHTIG: Überprüfe ob der Trigger existiert
SELECT 
  'handle_new_user Function' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'handle_new_user') THEN '✅ EXISTS' ELSE '❌ MISSING - KRITISCH!' END as status;

SELECT 
  'on_auth_user_created Trigger' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN '✅ EXISTS' ELSE '❌ MISSING - KRITISCH!' END as status;

-- 4. Überprüfe Functions
SELECT 
  'calculate_user_points Function' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_user_points') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
  'has_role_or_higher Function' as item,
  CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'has_role_or_higher') THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 5. Zeige alle existierenden User in profiles (sollte leer sein wenn noch niemand registriert ist)
SELECT 
  'Existing Users' as info,
  COUNT(*) as count
FROM profiles;

-- ============================================================================
-- INTERPRETATION DER ERGEBNISSE:
-- ============================================================================
-- 
-- Wenn "handle_new_user Function" oder "on_auth_user_created Trigger" MISSING ist:
--   ➜ Das ist der Grund für den 500 Error!
--   ➜ Lösung: supabase-setup-idempotent.sql KOMPLETT ausführen
--
-- Wenn "profiles Table" MISSING ist:
--   ➜ Setup wurde noch nicht ausgeführt
--   ➜ Lösung: supabase-setup-idempotent.sql KOMPLETT ausführen
--
-- Wenn alles ✅ EXISTS ist, aber trotzdem 500 Error:
--   ➜ Trigger funktioniert möglicherweise nicht
--   ➜ Lösung: Trigger neu erstellen (siehe unten)
--
-- ============================================================================

-- NOTFALL-FIX: Wenn Trigger existiert aber nicht funktioniert, neu erstellen:
/*
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
*/
