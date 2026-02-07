-- ============================================================================
-- MUADA EXPLORER - DATABASE SCHEMA
-- ============================================================================
-- Erstellt Typen und Tabellen
-- Kann mehrmals ausgeführt werden (idempotent)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. CUSTOM TYPES
-- ────────────────────────────────────────────────────────────────────────────

-- App Role Enum
DROP TYPE IF EXISTS app_role CASCADE;
CREATE TYPE app_role AS ENUM (
  'webmaster',    -- Vollzugriff
  'moderator',    -- Kann Locations verwalten
  'explorer',     -- Normaler User
  'banned'        -- Gesperrt
);

-- Location Category Enum
DROP TYPE IF EXISTS location_category CASCADE;
CREATE TYPE location_category AS ENUM (
  'industrial',   -- Industrie (Fabriken, etc.)
  'residential',  -- Wohngebäude (Villen, Häuser)
  'medical',      -- Medizin (Krankenhäuser, Sanatorien)
  'military',     -- Militär (Kasernen, Bunker)
  'religious',    -- Religion (Kirchen, Klöster)
  'educational',  -- Bildung (Schulen, Unis)
  'commercial',   -- Gewerbe (Hotels, Geschäfte)
  'transport',    -- Verkehr (Bahnhöfe, Flughäfen)
  'entertainment',-- Unterhaltung (Kinos, Freizeitparks)
  'other'         -- Sonstiges
);

-- ────────────────────────────────────────────────────────────────────────────
-- 2. PROFILES TABLE
-- ────────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS profiles CASCADE;
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  role app_role DEFAULT 'explorer' NOT NULL,
  points INTEGER DEFAULT 0 NOT NULL,
  level INTEGER DEFAULT 1 NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
  CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$'),
  CONSTRAINT points_positive CHECK (points >= 0),
  CONSTRAINT level_positive CHECK (level >= 1 AND level <= 100)
);

-- Indexes für Performance
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_points ON profiles(points DESC);

-- RLS aktivieren
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. LOCATIONS TABLE
-- ────────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS locations CASCADE;
CREATE TABLE locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  category location_category NOT NULL,
  
  -- Koordinaten (NUR für Moderatoren/Webmaster sichtbar!)
  latitude DECIMAL(10, 8) NOT NULL,
  longitude DECIMAL(11, 8) NOT NULL,
  
  -- Metadaten
  submitted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved BOOLEAN DEFAULT FALSE NOT NULL,
  approved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  
  -- Statistik
  visit_count INTEGER DEFAULT 0 NOT NULL,
  rating_avg DECIMAL(2, 1) DEFAULT 0.0 NOT NULL,
  review_count INTEGER DEFAULT 0 NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT name_length CHECK (char_length(name) >= 3 AND char_length(name) <= 100),
  CONSTRAINT description_length CHECK (char_length(description) >= 20),
  CONSTRAINT latitude_range CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT longitude_range CHECK (longitude BETWEEN -180 AND 180),
  CONSTRAINT visit_count_positive CHECK (visit_count >= 0),
  CONSTRAINT rating_range CHECK (rating_avg BETWEEN 0.0 AND 5.0),
  CONSTRAINT review_count_positive CHECK (review_count >= 0)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_locations_submitted_by ON locations(submitted_by);
CREATE INDEX IF NOT EXISTS idx_locations_approved ON locations(approved);
CREATE INDEX IF NOT EXISTS idx_locations_category ON locations(category);
CREATE INDEX IF NOT EXISTS idx_locations_rating ON locations(rating_avg DESC);
CREATE INDEX IF NOT EXISTS idx_locations_created_at ON locations(created_at DESC);

-- RLS aktivieren
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────────────────
-- 4. VISITS TABLE
-- ────────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS visits CASCADE;
CREATE TABLE visits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  photos TEXT[] DEFAULT '{}' NOT NULL, -- Array von Storage URLs
  notes TEXT,
  visited_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Ein User kann eine Location nur 1x besuchen
  CONSTRAINT unique_visit UNIQUE (location_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_visits_location ON visits(location_id);
CREATE INDEX IF NOT EXISTS idx_visits_user ON visits(user_id);
CREATE INDEX IF NOT EXISTS idx_visits_visited_at ON visits(visited_at DESC);

-- RLS aktivieren
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────────────────
-- 5. REVIEWS TABLE
-- ────────────────────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS reviews CASCADE;
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id UUID NOT NULL REFERENCES locations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT rating_range CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT comment_length CHECK (comment IS NULL OR char_length(comment) >= 10),
  
  -- Ein User kann eine Location nur 1x bewerten
  CONSTRAINT unique_review UNIQUE (location_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_reviews_location ON reviews(location_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);

-- RLS aktivieren
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- FERTIG! Schema erstellt ✓
-- ============================================================================
