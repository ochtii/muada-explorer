# MUADA Explorer - Setup Anleitung

## 🎯 Schritt-für-Schritt Setup

### Phase 1: Supabase Setup ✅

1. **SQL Schema ausführen:**
   - Öffne Supabase Dashboard: https://hcjkxiwmufabnztabbeb.supabase.co
   - Gehe zu SQL Editor
   - Kopiere den kompletten Inhalt von `supabase-setup.sql`
   - Klick auf "RUN"
   - ✅ Wenn "Success" angezeigt wird, ist alles fertig!

2. **Storage Buckets erstellen:**
   - Gehe zu Storage → Buckets → "New bucket"
   
   **Bucket 1: locations**
   - Name: `locations`
   - Public: ❌ (Private)
   - File size limit: 5242880 (5MB)
   - Allowed MIME types: `image/jpeg,image/png,image/webp`
   
   **Bucket 2: avatars**
   - Name: `avatars`
   - Public: ✅ (Public)
   - File size limit: 2097152 (2MB)
   - Allowed MIME types: `image/jpeg,image/png,image/webp`

3. **Storage Policies ausführen:**
   - Gehe zurück zu SQL Editor
   - Kopiere den Inhalt von `supabase-storage-policies.sql`
   - Klick auf "RUN"

### Phase 2: Lokale Entwicklung ✅

```bash
# Dependencies sind bereits installiert
npm install

# Development Server starten
npm run dev
```

Die App läuft auf: http://localhost:3000

### Phase 3: Erster User Setup (Webmaster)

1. **Registrieren:**
   - Gehe zu http://localhost:3000/signup
   - Username: `ochtii`
   - Email: deine@email.at
   - Passwort: min. 6 Zeichen
   - Klick "Registrieren, Oida!"

2. **Webmaster Rolle zuweisen:**
   - Gehe zu Supabase Dashboard → SQL Editor
   - Führe aus:
   ```sql
   UPDATE profiles 
   SET role = 'webmaster'
   WHERE username = 'ochtii';
   ```
   - Logout und Login in der App
   - ✅ Du solltest jetzt Admin Portal und Mod Portal sehen!

### Phase 4: Testen

**Test Checklist:**

- [ ] Login funktioniert
- [ ] Map zeigt sich (leer ist OK)
- [ ] Location hinzufügen funktioniert (Format: `48.2082,16.3738`)
- [ ] Mod Portal zeigt pending Location
- [ ] Location approved → erscheint auf Map
- [ ] Profile zeigt Stats
- [ ] Admin Portal zeigt User-Tabelle

### Phase 5: GitHub Pages Deployment

1. **Secrets in GitHub setzen:**
   - Gehe zu GitHub Repository → Settings → Secrets and variables → Actions
   - Erstelle:
     - `VITE_SUPABASE_URL` = `https://hcjkxiwmufabnztabbeb.supabase.co`
     - `VITE_SUPABASE_ANON_KEY` = `sb_publishable_REcD9tSc1OvzbWH9x8pOXQ_YWEJ7nI5`

2. **GitHub Pages aktivieren:**
   - Gehe zu Settings → Pages
   - Source: GitHub Actions
   - ✅ Speichern

3. **Deployen:**
   ```bash
   git add .
   git commit -m "Initial deployment"
   git push origin main
   ```

4. **Live URL:**
   - Nach ~2 Minuten ist die App live auf:
   - `https://ochtii.github.io/muada-explorer/`

## 🎮 Erste Schritte

1. **Als Webmaster:**
   - Erstelle mindestens 1 Test-Location
   - Erstelle einen zweiten User-Account (zum Testen)
   - Ändere die Rolle des zweiten Users zu "mitglied"

2. **Als Mitglied:**
   - Login mit zweitem Account
   - Gehe zur Map → solltest Koordinaten sehen
   - Markiere Location als besucht → +10 Punkte
   - Schreibe Review → +5 Punkte

3. **Ranking testen:**
   - Füge 5+ Locations hinzu (als Webmaster approved)
   - Besuche 5+ Locations
   - Schreibe Reviews
   - Check dein Level Badge im Profile

## 🔧 Troubleshooting

**Problem: Login funktioniert nicht**
- Check ob Email bestätigt (Supabase Dashboard → Authentication)
- Check Browser Console für Errors

**Problem: Map zeigt keine Marker**
- Check ob Locations approved sind (Mod Portal)
- Check ob `is_approved = true` in Database

**Problem: Koordinaten werden nicht angezeigt**
- Check User Role (muss `mitglied` oder höher sein)
- Check `locations_view` in Supabase

**Problem: Images uploaden geht nicht**
- Check Storage Buckets existieren
- Check Storage Policies wurden ausgeführt

## 📞 Support

Bei Problemen: Check die Browser Console (F12) für Error Messages.

---

**Viel Erfolg, Oida! 🏚️**
