# 🏚️ MUADA Explorer - Urbex Community Platform

**Die geilste Lost Place Community in ganz Österreich, Oida!**

Eine private Urbex (Urban Exploration) Community-Plattform für Österreich, gebaut mit React (Vite), Supabase und österreichischem Dialekt.

## 🎯 Features

- **🗺️ Interaktive Karte** - Alle Lost Places auf einer Leaflet-Karte
- **📍 Location Management** - Locations hinzufügen, bewerten und besuchen
- **🏆 Gamification System** - Punkte sammeln und im Ranking aufsteigen
- **👥 Rollen-System** - User, Mitglied, Mod, Admin, Webmaster
- **⭐ Reviews & Bewertungen** - Teile deine Erfahrungen
- **🔒 Sensible Daten geschützt** - Nur Mitglieder sehen Koordinaten
- **📸 Bilder Upload** - Fotos direkt hochladen

## 🚀 Setup & Installation

### 1. Supabase Setup

1. Gehe zu [Supabase](https://supabase.com) und erstelle ein neues Projekt (falls noch nicht geschehen)
2. Öffne den SQL Editor in deinem Supabase Dashboard
3. Kopiere den Inhalt von `supabase-setup.sql` und führe ihn aus
4. Erstelle die Storage Buckets:
   - Gehe zu Storage → Buckets
   - Erstelle Bucket `locations` (Private, Max 5MB)
   - Erstelle Bucket `avatars` (Public, Max 2MB)
5. Führe `supabase-storage-policies.sql` aus für Storage Policies

### 2. Projekt Setup

```bash
# Dependencies installieren
npm install

# Environment Variables setzen
# .env.local ist bereits konfiguriert mit den richtigen Credentials

# Development Server starten
npm run dev
```

### 3. Erster User (Webmaster Setup)

1. Starte die App und registriere dich mit dem Username `ochtii`
2. Gehe zu Supabase Dashboard → SQL Editor
3. Führe aus:
```sql
UPDATE profiles 
SET role = 'webmaster'
WHERE username = 'ochtii';
```

## 📦 Deployment (GitHub Pages)

```bash
# Build erstellen
npm run build

# Preview des Builds
npm run preview
```

Für GitHub Pages:
1. Pushe den Code zu GitHub
2. Gehe zu Repository Settings → Pages
3. Source: GitHub Actions
4. Erstelle `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm install
        
      - name: Build
        run: npm run build
        
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

## 🎮 Verwendung

### User Rollen

| Rolle | Berechtigung |
|-------|--------------|
| **User** | Sieht Locations auf Karte, aber keine Koordinaten |
| **Mitglied** | Sieht volle Koordinaten & Adressen |
| **Mod** | Kann Locations freigeben/löschen |
| **Admin** | Kann User-Rollen verwalten |
| **Webmaster** | God Mode - kann alles |

### Ranking System

- **Urbex Newbie** (0-50 Punkte)
- **Temu Urbexer** (51-150 Punkte)
- **Hobby Urbexer** (151-500 Punkte)
- **Advanced Urbexer** (501-1000 Punkte)
- **Profi Urbexer** (1001-2500 Punkte)
- **Urbex Gott** (2500+ Punkte)

**Punkte sammeln:**
- Location besucht: +10 Punkte
- Location hinzugefügt (approved): +50 Punkte
- Review geschrieben: +5 Punkte

## 🛠️ Technologie Stack

- **Frontend:** React 18 + Vite
- **Backend:** Supabase (PostgreSQL + Auth + Storage)
- **Map:** Leaflet + React-Leaflet
- **Routing:** React Router v6
- **Styling:** Vanilla CSS (Dark Theme)
- **Deployment:** GitHub Pages

## 📁 Projektstruktur

```
muada-explorer/
├── src/
│   ├── components/
│   │   └── Navbar.jsx
│   ├── context/
│   │   └── AuthContext.jsx
│   ├── pages/
│   │   ├── Landing.jsx
│   │   ├── Login.jsx
│   │   ├── Signup.jsx
│   │   ├── Map.jsx
│   │   ├── LocationDetails.jsx
│   │   ├── AddLocation.jsx
│   │   ├── Profile.jsx
│   │   ├── ModPortal.jsx
│   │   └── AdminPortal.jsx
│   ├── App.jsx
│   ├── main.jsx
│   ├── supabaseClient.js
│   └── index.css
├── supabase-setup.sql
├── supabase-storage-policies.sql
└── README.md
```

## 🔒 Sicherheit

- RLS (Row Level Security) ist aktiviert für alle Tabellen
- Sensible Daten (Koordinaten, Adressen) nur für Mitglieder+
- Service Keys werden NICHT im Frontend verwendet
- Storage Buckets haben separate RLS Policies
- Rollen-basierte Zugriffskontrolle

## 🤝 Contributing

Da dies eine private Community ist, kontaktiere bitte den Webmaster (ochtii) für Zugang.

## 📝 License

ISC

---

**Made with 🏚️ by ochtii**

Fix Oida! Viel Spaß beim Urbexen!