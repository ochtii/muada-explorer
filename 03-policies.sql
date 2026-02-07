-- ============================================================================
-- MUADA EXPLORER - ROW LEVEL SECURITY POLICIES
-- ============================================================================
-- Erstellt alle RLS Policies für Zugriffskontrolle
-- Kann mehrmals ausgeführ werden (idempotent)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- HILFSFUNKTION: CURRENT USER ROLE
-- ────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS app_role
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT role FROM profiles WHERE id = user_uuid;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. PROFILES POLICIES
-- ────────────────────────────────────────────────────────────────────────────

-- Alle Policies löschen
DROP POLICY IF EXISTS "Profiles sind öffentlich lesbar" ON profiles;
DROP POLICY IF EXISTS "User kann eigenes Profile bearbeiten" ON profiles;
DROP POLICY IF EXISTS "Webmaster/Mods können alle Profiles bearbeiten" ON profiles;
DROP POLICY IF EXISTS "User können ihr eigenes Profile anlegen" ON profiles;

-- Jeder kann alle Profiles lesen (für Leaderboard, etc.)
CREATE POLICY "Profiles sind öffentlich lesbar"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- User kann eigenes Profile bearbeiten
CREATE POLICY "User kann eigenes Profile bearbeiten"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT role FROM profiles WHERE id = auth.uid()) -- Role darf nicht selbst geändert werden
  );

-- Webmaster/Mods können alle Profiles bearbeiten (inkl. Role)
CREATE POLICY "Webmaster/Mods können alle Profiles bearbeiten"
  ON profiles FOR UPDATE
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('webmaster', 'moderator')
  );

-- User können ihr eigenes Profile beim Registration anlegen (via Trigger)
CREATE POLICY "User können ihr eigenes Profile anlegen"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. LOCATIONS POLICIES
-- ────────────────────────────────────────────────────────────────────────────

-- Alte Policies löschen
DROP POLICY IF EXISTS "Approved Locations sind lesbar" ON locations;
DROP POLICY IF EXISTS "Eigene Locations sind immer lesbar" ON locations;
DROP POLICY IF EXISTS "Mods/Webmaster sehen alle Locations" ON locations;
DROP POLICY IF EXISTS "User können Locations einreichen" ON locations;
DROP POLICY IF EXISTS "Mods/Webmaster können Locations bearbeiten" ON locations;
DROP POLICY IF EXISTS "Mods/Webmaster können Locations löschen" ON locations;

-- Approved Locations für alle sichtbar (aber OHNE Koordinaten!)
CREATE POLICY "Approved Locations sind lesbar"
  ON locations FOR SELECT
  TO authenticated
  USING (approved = true);

-- User sieht seine eigenen eingereichten Locations (auch wenn nicht approved)
CREATE POLICY "Eigene Locations sind immer lesbar"
  ON locations FOR SELECT
  TO authenticated
  USING (submitted_by = auth.uid());

-- Mods/Webmaster sehen ALLE Locations (inkl. Koordinaten!)
CREATE POLICY "Mods/Webmaster sehen alle Locations"
  ON locations FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('webmaster', 'moderator')
  );

-- User können Locations einreichen
CREATE POLICY "User können Locations einreichen"
  ON locations FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role(auth.uid()) NOT IN ('banned')
    AND submitted_by = auth.uid()
    AND approved = false -- Muss erst approved werden!
  );

-- Mods/Webmaster können Locations bearbeiten & approven
CREATE POLICY "Mods/Webmaster können Locations bearbeiten"
  ON locations FOR UPDATE
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('webmaster', 'moderator')
  );

-- Nur Webmaster kann Locations löschen
CREATE POLICY "Mods/Webmaster können Locations löschen"
  ON locations FOR DELETE
  TO authenticated
  USING (
    get_user_role(auth.uid()) = 'webmaster'
  );

-- ────────────────────────────────────────────────────────────────────────────
-- 3. VISITS POLICIES
-- ────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "User sieht eigene Visits" ON visits;
DROP POLICY IF EXISTS "Mods/Webmaster sehen alle Visits" ON visits;
DROP POLICY IF EXISTS "User können Visits anlegen" ON visits;
DROP POLICY IF EXISTS "User können eigene Visits bearbeiten" ON visits;
DROP POLICY IF EXISTS "User können eigene Visits löschen" ON visits;

-- User sieht nur eigene Visits
CREATE POLICY "User sieht eigene Visits"
  ON visits FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Mods/Webmaster sehen alle Visits
CREATE POLICY "Mods/Webmaster sehen alle Visits"
  ON visits FOR SELECT
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('webmaster', 'moderator')
  );

-- User können Visits für approved Locations anlegen
CREATE POLICY "User können Visits anlegen"
  ON visits FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role(auth.uid()) NOT IN ('banned')
    AND user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM locations
      WHERE id = location_id AND approved = true
    )
  );

-- User können eigene Visits bearbeiten
CREATE POLICY "User können eigene Visits bearbeiten"
  ON visits FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- User können eigene Visits löschen
CREATE POLICY "User können eigene Visits löschen"
  ON visits FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ────────────────────────────────────────────────────────────────────────────
-- 4. REVIEWS POLICIES
-- ────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Reviews sind öffentlich lesbar" ON reviews;
DROP POLICY IF EXISTS "User können Reviews für approved Locations schreiben" ON reviews;
DROP POLICY IF EXISTS "User können eigene Reviews bearbeiten" ON reviews;
DROP POLICY IF EXISTS "User können eigene Reviews löschen" ON reviews;
DROP POLICY IF EXISTS "Mods/Webmaster können Reviews löschen" ON reviews;

-- Alle können Reviews lesen
CREATE POLICY "Reviews sind öffentlich lesbar"
  ON reviews FOR SELECT
  TO authenticated
  USING (true);

-- User können Reviews für approved Locations schreiben (nur wenn sie sie besucht haben!)
CREATE POLICY "User können Reviews für approved Locations schreiben"
  ON reviews FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role(auth.uid()) NOT IN ('banned')
    AND user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM locations
      WHERE id = location_id AND approved = true
    )
    AND EXISTS (
      SELECT 1 FROM visits
      WHERE location_id = reviews.location_id
        AND user_id = auth.uid()
    )
  );

-- User können eigene Reviews bearbeiten
CREATE POLICY "User können eigene Reviews bearbeiten"
  ON reviews FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- User können eigene Reviews löschen
CREATE POLICY "User können eigene Reviews löschen"
  ON reviews FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Mods/Webmaster können Reviews moderieren
CREATE POLICY "Mods/Webmaster können Reviews löschen"
  ON reviews FOR DELETE
  TO authenticated
  USING (
    get_user_role(auth.uid()) IN ('webmaster', 'moderator')
  );

-- ============================================================================
-- FERTIG! RLS Policies erstellt ✓
-- ============================================================================
