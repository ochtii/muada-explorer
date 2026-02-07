-- ============================================================================
-- MUADA EXPLORER - FUNCTIONS & TRIGGERS
-- ============================================================================
-- Erstellt alle Datenbank-Funktionen und Trigger
-- Kann mehrmals ausgeführt werden (idempotent)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. PROFILE CREATION TRIGGER
-- ────────────────────────────────────────────────────────────────────────────
-- Erstellt automatisch ein Profile wenn sich User registriert
-- Mit Exception Handling damit Registration nicht blockiert wird!

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Versuche Profile zu erstellen
  BEGIN
    INSERT INTO public.profiles (id, username, role, points, level)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
      'explorer',
      0,
      1
    );
    
    RETURN NEW;
    
  EXCEPTION
    WHEN unique_violation THEN
      -- Profile existiert bereits - kein Problem
      RETURN NEW;
    WHEN OTHERS THEN
      -- Anderer Fehler - loggen aber Registration NICHT blockieren!
      RAISE WARNING 'Fehler beim Profile erstellen für User %: %', NEW.id, SQLERRM;
      RETURN NEW;
  END;
END;
$$;

-- Trigger erstellen (zuerst löschen falls vorhanden)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ────────────────────────────────────────────────────────────────────────────
-- 2. UPDATE TIMESTAMP TRIGGER
-- ────────────────────────────────────────────────────────────────────────────
-- Setzt updated_at automatisch auf NOW() bei UPDATE

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Trigger für profiles
DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- Trigger für locations
DROP TRIGGER IF EXISTS locations_updated_at ON locations;
CREATE TRIGGER locations_updated_at
  BEFORE UPDATE ON locations
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- Trigger für reviews
DROP TRIGGER IF EXISTS reviews_updated_at ON reviews;
CREATE TRIGGER reviews_updated_at
  BEFORE UPDATE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_timestamp();

-- ────────────────────────────────────────────────────────────────────────────
-- 3. GAMIFICATION: PUNKTE BERECHNEN
-- ────────────────────────────────────────────────────────────────────────────
-- Berechnet Punkte basierend auf Aktivitäten:
-- - Visit: 10 Punkte
-- - Location eingereicht: 50 Punkte (bei Approval)
-- - Review: 5 Punkte

CREATE OR REPLACE FUNCTION calculate_user_points(user_uuid UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  total_points INTEGER := 0;
  visit_points INTEGER := 0;
  location_points INTEGER := 0;
  review_points INTEGER := 0;
BEGIN
  -- Punkte aus Visits
  SELECT COALESCE(COUNT(*) * 10, 0) INTO visit_points
  FROM visits
  WHERE user_id = user_uuid;
  
  -- Punkte aus eingereichten & approved Locations
  SELECT COALESCE(COUNT(*) * 50, 0) INTO location_points
  FROM locations
  WHERE submitted_by = user_uuid AND approved = TRUE;
  
  -- Punkte aus Reviews
  SELECT COALESCE(COUNT(*) * 5, 0) INTO review_points
  FROM reviews
  WHERE user_id = user_uuid;
  
  total_points := visit_points + location_points + review_points;
  
  RETURN total_points;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. GAMIFICATION: LEVEL BERECHNEN
-- ────────────────────────────────────────────────────────────────────────────
-- Level basierend auf Punkten:
-- Level 1: 0-99 Punkte
-- Level 2: 100-249 Punkte
-- Level 3: 250-499 Punkte
-- Level 4: 500-999 Punkte
-- Level 5+: je 500 Punkte ein Level

CREATE OR REPLACE FUNCTION calculate_level(points INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
BEGIN
  CASE
    WHEN points < 100 THEN RETURN 1;
    WHEN points < 250 THEN RETURN 2;
    WHEN points < 500 THEN RETURN 3;
    WHEN points < 1000 THEN RETURN 4;
    ELSE RETURN LEAST(5 + ((points - 1000) / 500), 100);
  END CASE;
END;
$$;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. GAMIFICATION: AUTO-UPDATE TRIGGER
-- ────────────────────────────────────────────────────────────────────────────
-- Updated automatisch Punkte & Level wenn sich Aktivitäten ändern

CREATE OR REPLACE FUNCTION update_user_gamification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  affected_user_id UUID;
  new_points INTEGER;
  new_level INTEGER;
BEGIN
  -- Bestimme welcher User betroffen ist
  IF TG_TABLE_NAME = 'visits' THEN
    affected_user_id := COALESCE(NEW.user_id, OLD.user_id);
  ELSIF TG_TABLE_NAME = 'locations' THEN
    affected_user_id := COALESCE(NEW.submitted_by, OLD.submitted_by);
  ELSIF TG_TABLE_NAME = 'reviews' THEN
    affected_user_id := COALESCE(NEW.user_id, OLD.user_id);
  END IF;
  
  -- Berechne neue Punkte und Level
  IF affected_user_id IS NOT NULL THEN
    new_points := calculate_user_points(affected_user_id);
    new_level := calculate_level(new_points);
    
    -- Update Profile
    UPDATE profiles
    SET points = new_points,
        level = new_level
    WHERE id = affected_user_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger für visits
DROP TRIGGER IF EXISTS visits_update_gamification ON visits;
CREATE TRIGGER visits_update_gamification
  AFTER INSERT OR DELETE ON visits
  FOR EACH ROW
  EXECUTE FUNCTION update_user_gamification();

-- Trigger für locations (nur bei approval)
DROP TRIGGER IF EXISTS locations_update_gamification ON locations;
CREATE TRIGGER locations_update_gamification
  AFTER INSERT OR UPDATE OF approved ON locations
  FOR EACH ROW
  WHEN (NEW.approved = TRUE)
  EXECUTE FUNCTION update_user_gamification();

-- Trigger für reviews
DROP TRIGGER IF EXISTS reviews_update_gamification ON reviews;
CREATE TRIGGER reviews_update_gamification
  AFTER INSERT OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_user_gamification();

-- ────────────────────────────────────────────────────────────────────────────
-- 6. LOCATION STATISTIK UPDATE
-- ────────────────────────────────────────────────────────────────────────────
-- Updated automatisch visit_count, rating_avg, review_count

CREATE OR REPLACE FUNCTION update_location_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  loc_id UUID;
  new_visit_count INTEGER;
  new_review_count INTEGER;
  new_rating_avg DECIMAL(2,1);
BEGIN
  -- Bestimme betroffene Location
  loc_id := COALESCE(NEW.location_id, OLD.location_id);
  
  IF loc_id IS NOT NULL THEN
    -- Visit Count
    SELECT COUNT(*) INTO new_visit_count
    FROM visits
    WHERE location_id = loc_id;
    
    -- Review Count & Rating Average
    SELECT COUNT(*), COALESCE(AVG(rating), 0.0)
    INTO new_review_count, new_rating_avg
    FROM reviews
    WHERE location_id = loc_id;
    
    -- Update Location
    UPDATE locations
    SET visit_count = new_visit_count,
        review_count = new_review_count,
        rating_avg = new_rating_avg
    WHERE id = loc_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

-- Trigger für visits
DROP TRIGGER IF EXISTS visits_update_location_stats ON visits;
CREATE TRIGGER visits_update_location_stats
  AFTER INSERT OR DELETE ON visits
  FOR EACH ROW
  EXECUTE FUNCTION update_location_stats();

-- Trigger für reviews
DROP TRIGGER IF EXISTS reviews_update_location_stats ON reviews;
CREATE TRIGGER reviews_update_location_stats
  AFTER INSERT OR UPDATE OR DELETE ON reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_location_stats();

-- ============================================================================
-- FERTIG! Functions & Triggers erstellt ✓
-- ============================================================================
