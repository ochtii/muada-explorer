-- ============================================================================
-- MUADA EXPLORER - WEBMASTER SETUP
-- ============================================================================
-- Setzt den ersten User (ochtii) als Webmaster
-- ============================================================================

-- Prüfe ob User ochtii existiert
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM profiles WHERE username = 'ochtii') THEN
    -- Setze ochtii als Webmaster
    UPDATE profiles 
    SET role = 'webmaster'
    WHERE username = 'ochtii';
    
    RAISE NOTICE '✅ User "ochtii" ist jetzt Webmaster!';
  ELSE
    RAISE NOTICE '⚠️ User "ochtii" existiert noch nicht!';
    RAISE NOTICE '→ Registriere dich zuerst mit Username "ochtii"';
  END IF;
END $$;

-- Zeige alle User mit ihren Rollen
SELECT 
  username,
  role,
  level,
  points,
  created_at
FROM profiles
ORDER BY created_at;

-- ============================================================================
-- FERTIG! ✓
-- Falls "ochtii" noch nicht existiert, registriere dich zuerst!
-- ============================================================================
