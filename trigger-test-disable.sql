-- ============================================================================
-- TEST: Trigger DEAKTIVIEREN zum Debuggen
-- ============================================================================

-- Deaktiviere den Trigger temporär
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- JETZT: Versuche dich zu registrieren
-- Wenn es funktioniert → Problem liegt am Trigger
-- Wenn es NICHT funktioniert → Problem liegt woanders

-- ============================================================================
-- NACH DEM TEST: Trigger wieder aktivieren mit besserem Error Handling
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Logge für Debugging
  RAISE NOTICE 'Creating profile for user: %, email: %', NEW.id, NEW.email;
  
  -- Erstelle Profile
  INSERT INTO public.profiles (id, username, avatar_url, role, points, level_badge, visited_count, added_count)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    'user',
    0,
    'Urbex Newbie',
    0,
    0
  );
  
  RAISE NOTICE 'Profile created successfully for user: %', NEW.id;
  
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    RAISE WARNING 'Profile already exists for user: %', NEW.id;
    RETURN NEW;
  WHEN OTHERS THEN
    RAISE WARNING 'Error creating profile: % - %', SQLERRM, SQLSTATE;
    -- WICHTIG: Werfe Fehler NICHT weiter, damit User trotzdem erstellt wird
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
