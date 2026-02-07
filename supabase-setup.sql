-- ============================================================================
-- MUADA EXPLORER - Supabase Database Setup
-- Urbex Community Platform
-- ============================================================================

-- STEP 1: Create Custom Enums
-- ============================================================================

CREATE TYPE app_role AS ENUM (
  'user',
  'mitglied',
  'mod',
  'admin',
  'webmaster'
);

CREATE TYPE location_category AS ENUM (
  'industrial',
  'manor',
  'hospital',
  'military',
  'residential',
  'bunker',
  'other'
);

-- STEP 2: Create Tables
-- ============================================================================

-- Profiles Table (Extends auth.users)
CREATE TABLE profiles (
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

-- Locations Table
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  coordinates TEXT NOT NULL, -- Format: "lat,lng"
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

-- Visits Table (Tracks who went where)
CREATE TABLE visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE NOT NULL,
  visited_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(user_id, location_id)
);

-- Reviews Table
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID REFERENCES locations(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  comment TEXT,
  rating_condition INTEGER CHECK (rating_condition BETWEEN 1 AND 5),
  rating_risk INTEGER CHECK (rating_risk BETWEEN 1 AND 5),
  rating_accessibility INTEGER CHECK (rating_accessibility BETWEEN 1 AND 5),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- STEP 3: Create Indexes for Performance
-- ============================================================================

CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_locations_created_by ON locations(created_by);
CREATE INDEX idx_locations_is_approved ON locations(is_approved);
CREATE INDEX idx_locations_category ON locations(category);
CREATE INDEX idx_visits_user_id ON visits(user_id);
CREATE INDEX idx_visits_location_id ON visits(location_id);
CREATE INDEX idx_reviews_location_id ON reviews(location_id);
CREATE INDEX idx_reviews_user_id ON reviews(user_id);

-- STEP 4: Functions for Gamification
-- ============================================================================

-- Function: Calculate user points dynamically
CREATE OR REPLACE FUNCTION calculate_user_points(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  visit_points INTEGER;
  added_points INTEGER;
  review_points INTEGER;
  total_points INTEGER;
BEGIN
  -- Visited locations: 10 points each
  SELECT COUNT(*) * 10 INTO visit_points
  FROM visits
  WHERE user_id = user_uuid;
  
  -- Added locations (approved): 50 points each
  SELECT COUNT(*) * 50 INTO added_points
  FROM locations
  WHERE created_by = user_uuid AND is_approved = true;
  
  -- Reviews: 5 points each
  SELECT COUNT(*) * 5 INTO review_points
  FROM reviews
  WHERE user_id = user_uuid;
  
  total_points := COALESCE(visit_points, 0) + COALESCE(added_points, 0) + COALESCE(review_points, 0);
  
  RETURN total_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get level badge based on points
CREATE OR REPLACE FUNCTION get_level_badge(points INTEGER)
RETURNS TEXT AS $$
BEGIN
  IF points > 2500 THEN
    RETURN 'Profi Urbexer';
  ELSIF points > 1000 THEN
    RETURN 'Advanced Urbexer';
  ELSIF points > 500 THEN
    RETURN 'Hobby Urbexer';
  ELSIF points > 150 THEN
    RETURN 'Temu Urbexer';
  ELSIF points > 50 THEN
    RETURN 'Hobby Urbexer';
  ELSE
    RETURN 'Urbex Newbie';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Update user stats
CREATE OR REPLACE FUNCTION update_user_stats(user_uuid UUID)
RETURNS VOID AS $$
DECLARE
  new_points INTEGER;
  new_badge TEXT;
  visit_cnt INTEGER;
  added_cnt INTEGER;
BEGIN
  -- Calculate points
  new_points := calculate_user_points(user_uuid);
  
  -- Get badge
  new_badge := get_level_badge(new_points);
  
  -- Count visits
  SELECT COUNT(*) INTO visit_cnt FROM visits WHERE user_id = user_uuid;
  
  -- Count added locations (approved)
  SELECT COUNT(*) INTO added_cnt FROM locations WHERE created_by = user_uuid AND is_approved = true;
  
  -- Update profile
  UPDATE profiles
  SET 
    points = new_points,
    level_badge = new_badge,
    visited_count = visit_cnt,
    added_count = added_cnt
  WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 5: Triggers for Automatic Stats Update
-- ============================================================================

-- Trigger: After visit insert/delete
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

CREATE TRIGGER update_stats_on_visit
AFTER INSERT OR DELETE ON visits
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_visit();

-- Trigger: After review insert/delete
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

CREATE TRIGGER update_stats_on_review
AFTER INSERT OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_review();

-- Trigger: After location approval status change
CREATE OR REPLACE FUNCTION trigger_update_stats_on_location()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.is_approved != NEW.is_approved AND NEW.created_by IS NOT NULL THEN
    PERFORM update_user_stats(NEW.created_by);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stats_on_location
AFTER UPDATE ON locations
FOR EACH ROW EXECUTE FUNCTION trigger_update_stats_on_location();

-- Trigger: Auto-create profile on signup
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

-- STEP 6: Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Helper function to check user role
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS app_role AS $$
  SELECT role FROM profiles WHERE id = user_uuid;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper function to check if user has minimum role
CREATE OR REPLACE FUNCTION has_role_or_higher(user_uuid UUID, min_role app_role)
RETURNS BOOLEAN AS $$
DECLARE
  user_role app_role;
  role_hierarchy INTEGER;
  min_hierarchy INTEGER;
BEGIN
  SELECT role INTO user_role FROM profiles WHERE id = user_uuid;
  
  -- Role hierarchy: user=1, mitglied=2, mod=3, admin=4, webmaster=5
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

-- PROFILES Policies
-- ============================================================================

-- Anyone can read basic profile info
CREATE POLICY "Profiles are viewable by authenticated users"
ON profiles FOR SELECT
TO authenticated
USING (true);

-- Users can update their own profile (but not role)
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id 
  AND (role = (SELECT role FROM profiles WHERE id = auth.uid()))
);

-- Only higher roles can update other users' roles
CREATE POLICY "Admins+ can update user roles"
ON profiles FOR UPDATE
TO authenticated
USING (
  has_role_or_higher(auth.uid(), 'admin'::app_role)
)
WITH CHECK (
  has_role_or_higher(auth.uid(), 'admin'::app_role)
);

-- LOCATIONS Policies
-- ============================================================================

-- Public: No access (Landing page shows nothing)
-- Users: Can read basic info (name, category, condition, security_info) but NOT coordinates/address
CREATE POLICY "Users can view approved locations (limited)"
ON locations FOR SELECT
TO authenticated
USING (
  is_approved = true
);

-- Mitglied+: Can read full location data including coordinates
-- Note: We'll handle coordinate hiding in the application layer with a view/function

-- Anyone authenticated can insert locations (pending approval)
CREATE POLICY "Authenticated users can create locations"
ON locations FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = created_by
);

-- Mod+ can approve/edit locations
CREATE POLICY "Mods+ can update locations"
ON locations FOR UPDATE
TO authenticated
USING (
  has_role_or_higher(auth.uid(), 'mod'::app_role)
  OR created_by = auth.uid()
);

-- Mod+ can delete locations
CREATE POLICY "Mods+ can delete locations"
ON locations FOR DELETE
TO authenticated
USING (
  has_role_or_higher(auth.uid(), 'mod'::app_role)
);

-- VISITS Policies
-- ============================================================================

-- Users can view their own visits
CREATE POLICY "Users can view own visits"
ON visits FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Users can insert their own visits
CREATE POLICY "Users can create own visits"
ON visits FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can delete their own visits
CREATE POLICY "Users can delete own visits"
ON visits FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- REVIEWS Policies
-- ============================================================================

-- Anyone authenticated can read reviews
CREATE POLICY "Authenticated users can view reviews"
ON reviews FOR SELECT
TO authenticated
USING (true);

-- Users can insert their own reviews
CREATE POLICY "Users can create reviews"
ON reviews FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can update their own reviews
CREATE POLICY "Users can update own reviews"
ON reviews FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- Mods+ can delete any review
CREATE POLICY "Mods+ can delete reviews"
ON reviews FOR DELETE
TO authenticated
USING (
  user_id = auth.uid() 
  OR has_role_or_higher(auth.uid(), 'mod'::app_role)
);

-- STEP 7: Create Secure View for Locations (Role-based coordinate access)
-- ============================================================================

CREATE OR REPLACE VIEW locations_view AS
SELECT 
  l.id,
  l.name,
  l.category,
  l.condition,
  l.security_info,
  l.accessibility,
  l.description,
  l.images,
  l.created_by,
  l.is_approved,
  l.created_at,
  -- Only show coordinates/address/parking to Mitglied+
  CASE 
    WHEN has_role_or_higher(auth.uid(), 'mitglied'::app_role) THEN l.coordinates
    ELSE NULL
  END AS coordinates,
  CASE 
    WHEN has_role_or_higher(auth.uid(), 'mitglied'::app_role) THEN l.address
    ELSE NULL
  END AS address,
  CASE 
    WHEN has_role_or_higher(auth.uid(), 'mitglied'::app_role) THEN l.parking_info
    ELSE NULL
  END AS parking_info
FROM locations l
WHERE l.is_approved = true;

-- Grant access to the view
GRANT SELECT ON locations_view TO authenticated;

-- STEP 8: Storage Buckets Setup
-- ============================================================================
-- Note: Storage buckets must be created via Supabase Dashboard or via API
-- after running this script. Create the following buckets:
--
-- 1. Bucket name: "locations"
--    - Public: false
--    - File size limit: 5MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- 2. Bucket name: "avatars"
--    - Public: true
--    - File size limit: 2MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp
--
-- RLS Policies for Storage (Run in Storage Policies section):

-- For locations bucket:
-- INSERT: Authenticated users can upload
-- SELECT: Mitglied+ can view
-- UPDATE: Owner or Mod+ can update
-- DELETE: Owner or Mod+ can delete

-- For avatars bucket:
-- INSERT: Authenticated users can upload
-- SELECT: Anyone can view (public)
-- UPDATE: Owner can update
-- DELETE: Owner can delete

-- STEP 9: Create Admin Functions
-- ============================================================================

-- Function: Assign role (only by higher role)
CREATE OR REPLACE FUNCTION assign_user_role(
  target_user_id UUID,
  new_role app_role
)
RETURNS BOOLEAN AS $$
DECLARE
  current_user_role app_role;
  current_role_level INTEGER;
  new_role_level INTEGER;
BEGIN
  -- Get current user's role
  SELECT role INTO current_user_role FROM profiles WHERE id = auth.uid();
  
  -- Role hierarchy levels
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
  
  -- Only allow if current user has higher role than target role
  IF current_role_level > new_role_level THEN
    UPDATE profiles SET role = new_role WHERE id = target_user_id;
    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 10: Insert Initial Webmaster (ochtii)
-- ============================================================================
-- Note: This should be run AFTER the first user signs up
-- Replace 'USER_UUID_HERE' with ochtii's actual UUID after signup

-- UPDATE profiles 
-- SET role = 'webmaster'
-- WHERE username = 'ochtii';

-- ============================================================================
-- END OF SETUP SCRIPT
-- ============================================================================

-- Post-Setup Checklist:
-- [ ] Run this entire script in Supabase SQL Editor
-- [ ] Create storage buckets: "locations" and "avatars"
-- [ ] Set up storage RLS policies
-- [ ] Sign up the first user (ochtii) via the app
-- [ ] Manually update ochtii's role to 'webmaster'
-- [ ] Test authentication and role-based access

