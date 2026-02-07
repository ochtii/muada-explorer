# 🔥 MUADA Explorer - Quick Start Guide

> **Die österreichische Urbex Community Platform** 
> Built with React + Vite + Supabase

## 🚀 In 5 Minuten starten

### Schritt 1: Node Modules installieren (falls nicht vorhanden)
```bash
npm install
```

### Schritt 2: Development Server starten
```bash
npm run dev
```
✅ **App läuft auf:** http://localhost:3000/muada-explorer/

### Schritt 3: Supabase Setup (erstmals)

#### Option A: Automatisches Setup (SQL Script)
1. Öffne: https://hcjkxiwmufabnztabbeb.supabase.co
2. SQL Editor öffnen
3. Kopiere `supabase-setup.sql` → RUN
4. Kopiere `supabase-storage-policies.sql` → RUN
5. ✅ Fertig!

#### Option B: Manuelles Setup
Siehe `SETUP.md` für Details.

---

## 📁 Projekt-Struktur

```
muada-explorer/
├── src/
│   ├── components/          # Wiederverwendbare Komponenten
│   │   └── Navbar.jsx       # Navigation mit Role-based Menu
│   ├── context/
│   │   └── AuthContext.jsx  # Auth & User State Management
│   ├── pages/               # Alle Seiten
│   │   ├── Landing.jsx      # Öffentliche Startseite
│   │   ├── Login.jsx        # Login Formular
│   │   ├── Signup.jsx       # Registrierung
│   │   ├── Map.jsx          # Leaflet Map mit Markers
│   │   ├── LocationDetails  # Location Detail View + Reviews
│   │   ├── AddLocation.jsx  # Location hinzufügen (mit Upload)
│   │   ├── Profile.jsx      # User Profil + Stats
│   │   ├── ModPortal.jsx    # Location Approval (Mod+)
│   │   └── AdminPortal.jsx  # User Management (Admin+)
│   ├── utils/
│   │   └── austrianDialect.js # Alle Wienerisch Übersetzungen
│   ├── supabaseClient.js    # Supabase Init
│   ├── App.jsx              # Router + Protected Routes
│   └── main.jsx             # Entry Point
├── supabase-setup.sql       # Komplettes DB Schema + RLS
├── supabase-storage-policies.sql # Storage Bucket Policies
└── .env.local               # Supabase Credentials
```

---

## 🎭 Rollen & Permissions

| Rolle | Kann sehen | Kann tun |
|-------|-----------|----------|
| **User** | Map (ohne Coordinates), eigene Orte | Locations vorschlagen, Profil editieren |
| **Mitglied** | Map + Coordinates + Address | Alles von User + Reviews schreiben |
| **Mod** | Alles | Locations approven/ablehnen (Mod Portal) |
| **Admin** | Alles | User Rollen verwalten (Admin Portal) |
| **Webmaster** | Alles | Alles + "Muada aller Urbexer" Badge vergeben |

### Rollen-Hierarchie (wichtig!)
```
Webmaster (5) > Admin (4) > Mod (3) > Mitglied (2) > User (1)
```
**Regel:** Man kann nur Rollen **niedriger** als die eigene vergeben!

---

## ⭐ Gamification System

### Punkte-Berechnung
```javascript
Gesamt-Punkte = (Besuche × 10) + (Locations × 50) + (Reviews × 5)
```

### Level Badges
| Punkte | Badge |
|--------|-------|
| 0 - 50 | Urbex Newbie |
| 51 - 150 | Temu Urbexer |
| 151 - 500 | Hobby Urbexer |
| 501 - 1000 | Advanced Urbexer |
| 1001 - 2500 | Profi Urbexer |
| 2500+ | Urbex Gott |
| **Manual** | Muada aller Urbexer (nur Webmaster) |

**Auto-Update:** Punkte & Badges werden durch Supabase Triggers automatisch aktualisiert!

---

## 🗺️ Location hinzufügen

### Coordinates Format
```
48.2082,16.3738
```
**Wichtig:** Keine Leerzeichen! Format: `lat,lng`

### Image Upload
- **Max Size:** 5MB pro Bild
- **Formats:** JPG, PNG, WebP
- **Storage:** `locations` Bucket (Private)

---

## 🛠️ Entwickler-Commands

```bash
# Development
npm run dev          # Start Dev Server (Port 3000)

# Build
npm run build        # Production Build

# Preview
npm run preview      # Preview Production Build

# Deployment
git push origin main # Auto-Deploy via GitHub Actions
```

---

## 🌍 Deployment (GitHub Pages)

### Automatisch via GitHub Actions

1. **Secrets setzen** (Repository → Settings → Secrets):
   ```
   VITE_SUPABASE_URL = https://hcjkxiwmufabnztabbeb.supabase.co
   VITE_SUPABASE_ANON_KEY = eyJhbGciOi[...]REcD9tSc1OvzbWH9x8pOXQ_YWEJ7nI5
   ```

2. **GitHub Pages aktivieren** (Settings → Pages):
   - Source: **GitHub Actions**

3. **Pushen:**
   ```bash
   git add .
   git commit -m "Deploy"
   git push
   ```

4. **Live URL:**
   ```
   https://ochtii.github.io/muada-explorer/
   ```

---

## 🔐 Security Best Practices

### ✅ IMMER beachten:
- **Row Level Security (RLS)** ist auf ALLEN Tabellen aktiviert
- Sensitive Daten (Coordinates, Address) nur für Mitglied+
- Nie das Service Key in Frontend Code!
- Nur Anon Key in `.env.local`

### RLS Policies (Auto-Setup via SQL Script):
```sql
-- Beispiel: Locations Select Policy
CREATE POLICY "Users see basic info, Mitglied+ see coordinates"
ON locations FOR SELECT
USING (
  CASE 
    WHEN has_role_or_higher(auth.uid(), 'mitglied') THEN true
    WHEN auth.uid() IS NOT NULL THEN (coordinates IS NULL)
    ELSE false
  END
);
```

---

## 🇦🇹 Austrian Dialect Cheat Sheet

Nutze die `austrianDialect.js` Utility für konsistente Übersetzungen!

```javascript
import { austrianDialect, getRandomSuccess } from './utils/austrianDialect'

// Beispiele:
console.log(austrianDialect.buttons.save) 
// → "Speichern, Oida"

alert(getRandomSuccess()) 
// → "Fix Oida!" oder "Passt!" oder "Leiwand!"
```

### Wichtige Phrases:
- **Success:** Fix Oida!, Passt!, Leiwand!
- **Error:** Gschissn, Schaß, Heisl
- **Loading:** Wart kurz, Oida...
- **No Permission:** Werd erst Mitglied, du Wappla!
- **Logout:** Schleich di

---

## 🐛 Troubleshooting

### Problem: "Failed to fetch"
**Lösung:** Überprüfe `.env.local` - sind die Supabase Keys korrekt?

### Problem: "RLS Policy violation"
**Lösung:** 
1. Ist der User eingeloggt?
2. Hat der User die richtige Rolle?
3. Sind die RLS Policies deployed? (`supabase-setup.sql`)

### Problem: Images werden nicht angezeigt
**Lösung:**
1. Sind die Storage Buckets erstellt? (`locations`, `avatars`)
2. Sind die Storage Policies deployed? (`supabase-storage-policies.sql`)
3. Ist `avatars` Bucket **public**?

### Problem: Punkte werden nicht aktualisiert
**Lösung:** 
- Sind die Trigger erstellt? (im `supabase-setup.sql`)
- Test: Manuell aufrufen:
  ```sql
  SELECT update_user_stats('[USER_UUID]');
  ```

---

## 📚 Weitere Ressourcen

- **Supabase Docs:** https://supabase.com/docs
- **React Router:** https://reactrouter.com
- **Leaflet Maps:** https://leafletjs.com
- **Vite:** https://vitejs.dev

---

## 🎯 Nächste Features (Roadmap)

- [ ] Location Bilder Slideshow
- [ ] User Notifications
- [ ] Location Favoriten
- [ ] Advanced Search & Filter
- [ ] Export visits to GPX
- [ ] Mobile App (React Native)

---

**Built with 🔥 by ochtii**  
*"Für de, de wissn wos leiwand is!"*
