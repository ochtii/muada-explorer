-- ============================================================================
-- MUADA EXPLORER - VIEWS
-- ============================================================================
-- Erstellt Views für spezielle Zugriffsmuster
-- Kann mehrmals ausgeführt werden (idempotent)
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. LOCATIONS VIEW (Koordinaten-Schutz!)
-- ────────────────────────────────────────────────────────────────────────────
-- Diese View zeigt:
-- - Für NORMALE USER: Alle Daten OHNE genaue Koordinaten (nur Region)
-- - Für MODS/WEBMASTER: Alle Daten INKLUSIVE exakter Koordinaten
-- ────────────────────────────────────────────────────────────────────────────

DROP VIEW IF EXISTS locations_view CASCADE;

CREATE VIEW locations_view AS
SELECT 
  l.id,
  l.name,
  l.description,
  l.category,
  
  -- KOORDINATEN: Nur für Mods/Webmaster sichtbar!
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('webmaster', 'moderator')
    ) THEN l.latitude
    ELSE NULL
  END AS latitude,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid()
        AND p.role IN ('webmaster', 'moderator')
    ) THEN l.longitude
    ELSE NULL
  END AS longitude,
  
  -- META
  l.submitted_by,
  l.approved,
  l.approved_by,
  l.approved_at,
  
  -- STATISTIK
  l.visit_count,
  l.rating_avg,
  l.review_count,
  
  -- TIMESTAMPS
  l.created_at,
  l.updated_at,
  
  -- ZUSATZ: Username des Submitters
  (SELECT username FROM profiles WHERE id = l.submitted_by) AS submitted_by_username,
  
  -- ZUSATZ: Username des Approvers
  (SELECT username FROM profiles WHERE id = l.approved_by) AS approved_by_username
  
FROM locations l;

-- Grant Zugriff
GRANT SELECT ON locations_view TO authenticated;

-- ────────────────────────────────────────────────────────────────────────────
-- HINWEIS:
-- ────────────────────────────────────────────────────────────────────────────
-- Diese View zeigt für normale User latitude/longitude als NULL!
-- Nur Moderatoren und Webmaster sehen die echten Koordinaten.
-- 
-- Im Frontend muss geprüft werden:
-- - Wenn latitude IS NULL → "Koordinaten nur für Mods sichtbar"
-- - Sonst → Zeige Marker auf der Karte
-- ────────────────────────────────────────────────────────────────────────────

-- ============================================================================
-- FERTIG! Views erstellt ✓
-- ============================================================================
