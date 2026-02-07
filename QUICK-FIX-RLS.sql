-- ============================================================================
-- QUICK FIX: RLS POLICY CHECK & FIX
-- ============================================================================
-- Prüft und repariert RLS Policies für profiles Tabelle
-- ============================================================================

-- 1. Zeige aktuellen Status
SELECT 
  '🔍 RLS STATUS' as info,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'profiles';

-- 2. Zeige existierende Policies
SELECT 
  '📋 EXISTIERENDE POLICIES' as info,
  policyname,
  cmd as command,
  permissive,
  roles
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles';

-- 3. Lösche ALLE alten Policies (Clean Slate)
DROP POLICY IF EXISTS "Profiles sind öffentlich lesbar" ON profiles;
DROP POLICY IF EXISTS "User kann eigenes Profile bearbeiten" ON profiles;
DROP POLICY IF EXISTS "Webmaster/Mods können alle Profiles bearbeiten" ON profiles;
DROP POLICY IF EXISTS "User können ihr eigenes Profile anlegen" ON profiles;

-- 4. Erstelle die WICHTIGSTE Policy: PUBLIC READ ACCESS
CREATE POLICY "Profiles sind öffentlich lesbar"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- 5. Erstelle UPDATE Policy
CREATE POLICY "User kann eigenes Profile bearbeiten"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())
  );

-- 6. Erstelle INSERT Policy
CREATE POLICY "User können ihr eigenes Profile anlegen"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 7. Prüfe ob es jetzt funktioniert
SELECT 
  '✅ NEUE POLICIES' as info,
  policyname,
  cmd as command
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'profiles'
ORDER BY policyname;

-- 8. Teste ob du dein Profile lesen kannst
SELECT 
  '🧪 TEST: Mein Profile' as info,
  username,
  role,
  level,
  points
FROM profiles
WHERE id = auth.uid();

-- ============================================================================
-- FERTIG! ✓
-- Wenn du jetzt dein Profile siehst → PROBLEM GELÖST!
-- Wenn nicht → Es gibt ein anderes Problem
-- ============================================================================
