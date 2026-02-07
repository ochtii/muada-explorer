-- ============================================================================
-- MUADA EXPLORER - Diagnose Script
-- ============================================================================

-- Zeige auth.users vs profiles Count
SELECT 'auth.users' as tabelle, COUNT(*) as anzahl FROM auth.users
UNION ALL
SELECT 'profiles' as tabelle, COUNT(*) as anzahl FROM profiles;
