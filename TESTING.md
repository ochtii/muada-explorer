# ✅ MUADA Explorer - Testing Checklist

## Phase 1: Supabase Setup ✅

- [ ] SQL Script ausgeführt (`supabase-setup.sql`)
- [ ] Storage Buckets erstellt:
  - [ ] `locations` (Private, 5MB, images)
  - [ ] `avatars` (Public, 2MB, images)
- [ ] Storage Policies deployed (`supabase-storage-policies.sql`)

## Phase 2: First User (Webmaster) ✅

- [ ] Registrierung funktioniert
- [ ] User in `profiles` Tabelle sichtbar
- [ ] Webmaster Rolle zugewiesen:
  ```sql
  UPDATE profiles SET role = 'webmaster' WHERE username = 'ochtii';
  ```
- [ ] Nach Re-Login: Admin Portal sichtbar in Navbar

## Phase 3: Authentication Tests ✅

### Login/Logout
- [ ] Login mit korrekten Credentials funktioniert
- [ ] Login mit falschen Credentials zeigt Fehler
- [ ] Logout funktioniert und redirected zu Landing
- [ ] Protected Routes werden geschützt (redirect to login)

### Signup
- [ ] Neuer User kann sich registrieren
- [ ] Username wird validiert (min. 3 Zeichen)
- [ ] Email wird validiert
- [ ] Passwort min. 6 Zeichen
- [ ] Doppelte Usernames werden abgelehnt
- [ ] Nach Signup: Auto-Login

## Phase 4: Map & Locations Tests ✅

### Map Anzeige
- [ ] Map lädt und zeigt Basemap (OpenStreetMap)
- [ ] Zoom funktioniert
- [ ] Pan funktioniert
- [ ] Markers werden angezeigt (wenn Locations vorhanden)

### Location hinzufügen
- [ ] Form öffnet sich
- [ ] Koordinaten-Format wird validiert (`lat,lng`)
- [ ] Kategorie-Dropdown funktioniert
- [ ] Image Upload funktioniert (max 5MB)
- [ ] Multiple Images können hochgeladen werden
- [ ] Nach Submit: Success Message
- [ ] Location erscheint in "Meine Locations" (Pending)

### Location Details
**Als User (ohne Mitglied):**
- [ ] Location Name sichtbar
- [ ] Kategorie sichtbar
- [ ] Beschreibung sichtbar
- [ ] Coordinates **NICHT** sichtbar → "Werd erst Mitglied, du Wappla!"
- [ ] Address **NICHT** sichtbar

**Als Mitglied+:**
- [ ] Coordinates sichtbar
- [ ] Address sichtbar
- [ ] Parking Info sichtbar
- [ ] Security Info sichtbar
- [ ] "Mark as Visited" Button funktioniert
- [ ] Review Form sichtbar
- [ ] Review Submit funktioniert

## Phase 5: Gamification Tests ✅

### Punkte-System
- [ ] Initial User hat 0 Punkte
- [ ] Nach Location Visit: +10 Punkte
- [ ] Nach Location Approval: +50 Punkte
- [ ] Nach Review Submit: +5 Punkte
- [ ] Punkte werden automatisch aktualisiert (Trigger)

### Level Badges
- [ ] 0-50 Punkte → "Urbex Newbie"
- [ ] 51-150 Punkte → "Temu Urbexer"
- [ ] 151-500 Punkte → "Hobby Urbexer"
- [ ] 501-1000 Punkte → "Advanced Urbexer"
- [ ] 1001-2500 Punkte → "Profi Urbexer"
- [ ] 2500+ Punkte → "Urbex Gott"
- [ ] Badge wird automatisch aktualisiert

### Profile Anzeige
- [ ] Username angezeigt
- [ ] Avatar angezeigt (oder Placeholder)
- [ ] Role Badge angezeigt
- [ ] Level Badge angezeigt
- [ ] Punkte angezeigt
- [ ] Punkteberechnung sichtbar
- [ ] Visited Count korrekt
- [ ] Added Count korrekt
- [ ] Meine Visits Liste angezeigt
- [ ] Meine Locations Liste angezeigt

## Phase 6: Mod Portal Tests ✅

**Voraussetzung:** Rolle mindestens 'mod'

### Pending Locations
- [ ] Mod Portal in Navbar sichtbar
- [ ] Pending Locations werden angezeigt
- [ ] "Approve" Button funktioniert
- [ ] Nach Approve: Location verschwindet aus Liste
- [ ] Location erscheint auf Map
- [ ] Creator bekommt +50 Punkte

### Delete Location
- [ ] "Delete" Button funktioniert
- [ ] Location wird entfernt
- [ ] Confirmation Dialog erscheint (optional)

## Phase 7: Admin Portal Tests ✅

**Voraussetzung:** Rolle mindestens 'admin'

### User Management
- [ ] Admin Portal in Navbar sichtbar
- [ ] Alle User werden angezeigt
- [ ] Filter funktionieren (All, User, Mitglied, Mod)
- [ ] Role Dropdown zeigt verfügbare Rollen
  - Admin sieht: User, Mitglied, Mod
  - Webmaster sieht: User, Mitglied, Mod, Admin, Webmaster

### Role Assignment
- [ ] Admin kann User → Mitglied ändern ✅
- [ ] Admin kann Mitglied → Mod ändern ✅
- [ ] Admin **KANN NICHT** User → Admin ändern ❌
- [ ] Admin **KANN NICHT** Admin editieren ❌
- [ ] Webmaster kann ALLE Rollen ändern ✅
- [ ] Nach Role Change: Success Message
- [ ] User Liste aktualisiert sich

### Role Hierarchy Validation
- [ ] User mit Role "Admin" kann keine Admin-Rolle vergeben
- [ ] User mit Role "Mod" hat KEINEN Zugriff auf Admin Portal
- [ ] Error Message: "Du Wappla! Du kannst nur niedrigere Rollen vergeben..."

## Phase 8: Image Upload Tests ✅

### Avatar Upload
- [ ] File Picker öffnet sich
- [ ] Image Preview wird angezeigt
- [ ] Upload zu `avatars` Bucket funktioniert
- [ ] Avatar wird im Profil angezeigt
- [ ] Avatar wird in Navbar angezeigt

### Location Image Upload
- [ ] Multiple Images können ausgewählt werden
- [ ] Preview wird angezeigt
- [ ] Upload zu `locations` Bucket funktioniert
- [ ] Images werden in Location Details angezeigt
- [ ] Max 5MB Limit wird validiert

## Phase 9: Reviews & Visits Tests ✅

### Review Submit
- [ ] Review Form sichtbar (nur Mitglied+)
- [ ] Rating Sliders funktionieren (1-5)
- [ ] Comment Textarea funktioniert
- [ ] Submit funktioniert
- [ ] Review erscheint in Liste
- [ ] User bekommt +5 Punkte

### Mark as Visited
- [ ] Button funktioniert
- [ ] Success Message erscheint
- [ ] Visit erscheint in Profil → "Meine Visits"
- [ ] User bekommt +10 Punkte
- [ ] Marker auf Map ändert Farbe (Visited)

## Phase 10: RLS Policy Tests ✅

### Unauthorized Access
- [ ] Nicht-eingeloggte User sehen keine Locations
- [ ] User ohne Mitglied-Rolle sehen keine Coordinates
- [ ] User können nur eigene Profiles editieren

### Storage Access
- [ ] `avatars` Bucket ist public (jeder kann lesen)
- [ ] `locations` Bucket ist private (nur Mitglied+ kann lesen)
- [ ] User können nur eigene Avatars uploaden
- [ ] User können nur für eigene Locations uploaden

## Phase 11: UI/UX Tests ✅

### Austrian Dialect
- [ ] Buttons verwenden Wienerisch ("Speichern, Oida")
- [ ] Error Messages verwenden Wienerisch ("Gschissn")
- [ ] Success Messages verwenden Wienerisch ("Fix Oida!")
- [ ] Loading States verwenden Wienerisch ("Wart kurz...")
- [ ] Categories verwenden Wienerisch ("Tschick-Fabrik")

### Responsive Design
- [ ] Mobile View funktioniert (< 768px)
- [ ] Tablet View funktioniert (768px - 1024px)
- [ ] Desktop View funktioniert (> 1024px)
- [ ] Map funktioniert auf Mobile
- [ ] Forms funktionieren auf Mobile

### Navigation
- [ ] Navbar zeigt richtige Links basierend auf Role
- [ ] Active Link wird hervorgehoben
- [ ] Logout Button funktioniert
- [ ] Logo/Brand click → Home

## Phase 12: Performance Tests ✅

### Load Times
- [ ] Initial Load < 3 Sekunden
- [ ] Map Rendering < 2 Sekunden
- [ ] Location Details < 1 Sekunde
- [ ] Image Upload < 5 Sekunden (5MB)

### Optimizations
- [ ] Lazy Loading für Images
- [ ] Debounce für Search (optional)
- [ ] Pagination für große Listen (optional)

## Phase 13: Deployment Tests 🚀

### GitHub Pages
- [ ] GitHub Actions Workflow läuft erfolgreich
- [ ] Build erstellt dist/ Ordner
- [ ] Deployment auf GitHub Pages erfolgreich
- [ ] Live URL funktioniert
- [ ] Routes funktionieren (mit Hash Router)
- [ ] Environment Variables werden geladen

### Production Checks
- [ ] Console Errors geprüft (keine kritischen Errors)
- [ ] Network Requests geprüft (keine 404s)
- [ ] Supabase Connection funktioniert
- [ ] Auth funktioniert in Production
- [ ] Image Upload funktioniert in Production

---

## 🎯 Kritische Bugs (sofort fixen!)

- [ ] Auth funktioniert NICHT → `.env.local` prüfen
- [ ] RLS Policies fehlen → SQL Script nochmal laufen lassen
- [ ] Coordinates für User sichtbar → **SECURITY RISK!** → RLS Policies prüfen
- [ ] Webmaster kann keine Rollen ändern → `assign_user_role` Funktion prüfen

---

## ✅ Alles grün? → READY TO DEPLOY! 🚀

**Finale Steps:**
1. `git add .`
2. `git commit -m "🚀 Ready for production"`
3. `git push origin main`
4. Warte 2 Minuten
5. Öffne `https://ochtii.github.io/muada-explorer/`
6. **🎉 FIX OIDA! 🎉**

---

**Viel Erfolg, Oida!** 🔥
