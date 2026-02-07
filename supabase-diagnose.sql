-- ============================================================================
-- MUADA EXPLORER - Diagnose Script
-- Zeigt nur die Anzahl existierender User an
-- ============================================================================

-- Zeige alle existierenden User in profiles (sollte 0 sein wenn noch niemand registriert ist)
SELECT COUNT(*) as existing_users FROM profiles;

