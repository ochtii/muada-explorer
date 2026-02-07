-- ============================================================================
-- MUADA EXPLORER - Idempotent Supabase Setup (kann mehrmals ausgeführt werden)
-- ============================================================================

-- STEP 1: Create Enums (nur wenn nicht existiert)
-- ============================================================================

DO $$ BEGIN
  CREATE TYPE app_role AS ENUM ('user', 'mitglied', 'mod', 'admin', 'webmaster');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE location_category AS ENUM ('industrial', 'manor', 'hospital', 'military', 'residential', 'bunker', 'other');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- STEP 2: Create Tables (nur wenn nicht existiert)
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  avatar_url TEXT,
  role app_role DEFAULT 'user' NOT NULL,
  points INTEGER DEFAULT 0 NOT NULL,
  level_badge TEXT DEFAULT 'Urbex Newbie' NOT NULL,
  visited_count INTEGER DEFAULT 0 NOT NULL,
  added_count INTEGER DEFAULT 0 NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  coordinates TEXT NOT NULL,
  address TEXT,
  category location_category NOT NULL,
  condition INTEGER CHECK (condition BETWEEN 1 AND 5),
  security_info TEXT,
  accessibility TEXT,
  parking_info TEXT,
  description TEXT,
  images TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_approved BOOLEAN DEFAULT false NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE TABLE IF NOT EXISTS visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE NOT NULL,
  visited_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, location_id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  comment TEXT,
  rating_condition INTEGER CHECK (rating_condition BETWEEN 1 AND 5),
  rating_risk INTEGER CHECK (rating_risk BETWEEN 1 AND 5),
  rating_accessibility INTEGER CHECK (rating_accessibility BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- STEP 3: Create Indexes (nur wenn nicht existiert)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_locations_created_by ON locations(created_by);
CREATE INDEX IF NOT EXISTS idx_locations_is_approved ON locations(is_approved);
CREATE INDEX IF NOT EXISTS idx_locations_category ON locations(category);
CREATE INDEX IF NOT EXISTS idx_visits_user_id ON visits(user_id);
CREATE INDEX IF NOT EXISTS idx_visits_location_id ON visits(location_id);
CREATE INDEX IF NOT EXISTS idx_reviews_location_id ON reviews(location_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);

-- STEP 4: Functions (mit CREATE OR REPLACE = immer neu erstellen)
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_user_points(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  visit_points INTEGER;
  added_points INTEGER;
  review_points INTEGER;
  total_points INTEGER;
BEGIN
  SELECT COUNT(*) * 10 INTO visit_points FROM visits WHERE user_id = user_uuid;
  SELECT COUNT(*) * 50 INTO added_points FROM locations WHERE created_by = user_uuid AND is_approved = true;
  SELECT COUNT(*) * 5 INTO review_points FROM reviews WHERE user_id = user_uuid;
  total_points := COALESCE(visit_points, 0) + COALESCE(added_points, 0) + COALESCE(review_points, 0);
  RETURN total_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_level_badge(points INTEGER)
RETURNS TEXT AS $$
BEGIN
  IF points > 2500 THEN RETURN 'Urbex Gott';
  ELSIF points > 1000 THEN RETURN 'Profi Urbexer';
  ELSIF points > 500 THEN RETURN 'Advanced Urbexer';
  ELSIF points > 150 THEN RETURN 'Hobby Urbexer';
  ELSIF points > 50 THEN RETURN 'Temu Urbexer';
  ELSE RETURN 'Urbex Newbie';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION update_user_stats(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
  new_points INTEGER;
  new_badge TEXT;
  visit_cnt INTEGER;
  added_cnt INTEGER;
BEGIN
  new_points := calculate_user_points(user_uuid);
  new_badge := get_level_badge(new_points);
  SELECT COUNT(*) INTO visit_cnt FROM visits WHERE user_id = user_uuid;
  SELECT COUNT(*) INTO added_cnt FROM locations WHERE created_by = user_uuid AND is_approved = true;
  UPDATE profiles SET points = new_points, level_badge = new_badge, visited_count = visit_cnt, added_count = added_cnt WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS app_role AS $$
  SELECT role FROM profiles WHERE id = user_uuid;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION has_role_or_higher(user_uuid UUID, min_role app_role)
RETURNS BOOLEAN AS $$
DECLARE
  user_role app_role;
  role_hierarchy INTEGER;
  min_hierarchy INTEGER;
BEGIN
  SELECT role INTO user_role FROM profiles WHERE id = user_uuid;
  CASE user_role
    WHEN 'user' THEN role_hierarchy := 1;
    WHEN 'mitglied' THEN role_hierarchy := 2;
    WHEN 'mod' THEN role_hierarchy := 3;
    WHEN 'admin' THEN role_hierarchy := 4;
    WHEN 'webmaster' THEN role_hierarchy := 5;
    ELSE role_hierarchy := 0;
  END CASE;
  CASE min_role
    WHEN 'user' THEN min_hierarchy := 1;
    WHEN 'mitglied' THEN min_hierarchy := 2;
    WHEN 'mod' THEN min_hierarchy := 3;
    WHEN 'admin' THEN min_hierarchy := 4;
    WHEN 'webmaster' THEN min_hierarchy := 5;
    ELSE min_hierarchy := 999;
  END CASE;
  RETURN role_hierarchy >= min_hierarchy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION assign_user_role(target_user_id UUID, new_role app_role)
RETURNS BOOLEAN AS $$
DECLARE
  current_user_role app_role;
  current_role_level INTEGER;
  new_role_level INTEGER;
BEGIN
  SELECT role INTO current_user_role FROM profiles WHERE id = auth.uid();
  CASE current_user_role
    WHEN 'webmaster' THEN current_role_level := 5;
    WHEN 'admin' THEN current_role_level := 4;
    WHEN 'mod' THEN current_role_level := 3;
    WHEN 'mitglied' THEN current_role_level := 2;
    ELSE current_role_level := 1;
  END CASE;
  CASE new_role
    WHEN 'webmaster' THEN new_role_level := 5;
    WHEN 'admin' THEN new_role_level := 4;
    WHEN 'mod' THEN new_role_level := 3;
    WHEN 'mitglied' THEN new_role_level := 2;
    ELSE new_role_level := 1;
  END CASE;
  IF current_role_level > new_role_level THEN
    UPDATE profiles SET role = new_role WHERE id = target_user_id;
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- WICHTIGSTER TRIGGER: Auto-create profile on signup
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

-- Drop trigger if exists, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- STEP 5: Stats Update Triggers
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_update_stats_on_visit()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM update_user_stats(OLD.user_id);
    RETURN OLD;
  ELSE
    PERFORM update_user_stats(NEW.user_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stats_on_visit ON visits;
CREATE TRIGGER update_stats_on_visit
AFTER INSERT OR DELETE ON visits
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_visit();

CREATE OR REPLACE FUNCTION trigger_update_stats_on_review()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM update_user_stats(OLD.user_id);
    RETURN OLD;
  ELSE
    PERFORM update_user_stats(NEW.user_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stats_on_review ON reviews;
CREATE TRIGGER update_stats_on_review
AFTER INSERT OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_review();

CREATE OR REPLACE FUNCTION trigger_update_stats_on_location()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_approved != NEW.is_approved AND NEW.created_by IS NOT NULL THEN
    PERFORM update_user_stats(NEW.created_by);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_stats_on_location ON locations;
CREATE TRIGGER update_stats_on_location
AFTER UPDATE ON locations
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_location();

-- STEP 6: Enable RLS
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- STEP 7: RLS Policies (Drop if exists, then create)
-- ============================================================================

-- PROFILES
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON profiles;
CREATE POLICY "Profiles are viewable by authenticated users" ON profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id AND (role = (SELECT role FROM profiles WHERE id = auth.uid())));

DROP POLICY IF EXISTS "Admins+ can update user roles" ON profiles;
CREATE POLICY "Admins+ can update user roles" ON profiles FOR UPDATE TO authenticated
USING (has_role_or_higher(auth.uid(), 'admin'::app_role))
WITH CHECK (has_role_or_higher(auth.uid(), 'admin'::app_role));

-- LOCATIONS
DROP POLICY IF EXISTS "Users can view approved locations (limited)" ON locations;
CREATE POLICY "Users can view approved locations (limited)" ON locations FOR SELECT TO authenticated USING (is_approved = true);

DROP POLICY IF EXISTS "Authenticated users can create locations" ON locations;
CREATE POLICY "Authenticated users can create locations" ON locations FOR INSERT TO authenticated WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Mods+ can update locations" ON locations;
CREATE POLICY "Mods+ can update locations" ON locations FOR UPDATE TO authenticated
USING (has_role_or_higher(auth.uid(), 'mod'::app_role) OR created_by = auth.uid());

DROP POLICY IF EXISTS "Mods+ can delete locations" ON locations;
CREATE POLICY "Mods+ can delete locations" ON locations FOR DELETE TO authenticated USING (has_role_or_higher(auth.uid(), 'mod'::app_role));

-- VISITS
DROP POLICY IF EXISTS "Users can view own visits" ON visits;
CREATE POLICY "Users can view own visits" ON visits FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own visits" ON visits;
CREATE POLICY "Users can create own visits" ON visits FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own visits" ON visits;
CREATE POLICY "Users can delete own visits" ON visits FOR DELETE TO authenticated USING (user_id = auth.uid());

-- REVIEWS
DROP POLICY IF EXISTS "Authenticated users can view reviews" ON reviews;
CREATE POLICY "Authenticated users can view reviews" ON reviews FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Users can create reviews" ON reviews;
CREATE POLICY "Users can create reviews" ON reviews FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own reviews" ON reviews;
CREATE POLICY "Users can update own reviews" ON reviews FOR UPDATE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Mods+ can delete reviews" ON reviews;
CREATE POLICY "Mods+ can delete reviews" ON reviews FOR DELETE TO authenticated
USING (user_id = auth.uid() OR has_role_or_higher(auth.uid(), 'mod'::app_role));

-- ============================================================================
-- FERTIG! 🎉
-- ============================================================================
-- Dieses Script kann mehrmals ausgeführt werden ohne Fehler!
