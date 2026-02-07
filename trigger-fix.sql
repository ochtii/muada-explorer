-- ============================================================================
-- TRIGGER SOFORT-FIX
-- Falls der Trigger nicht funktioniert, führe DAS hier aus:
-- ============================================================================

-- Schritt 1: Entferne alten Trigger (falls vorhanden)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Schritt 2: Erstelle Funktion NEU mit besserem Error Handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Versuche Profile zu erstellen
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Bei Fehler: Logge und werfe Fehler trotzdem
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Schritt 3: Erstelle Trigger NEU
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- TEST: Prüfe ob Trigger existiert
-- ============================================================================

SELECT 
  tgname as trigger_name,
  tgenabled as enabled
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created' 
  AND tgrelid = 'auth.users'::regclass;

-- ✅ Sollte eine Zeile zurückgeben mit enabled = 'O' (Origin = aktiv)
