import { Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Landing.css'

const Landing = () => {
  const { user } = useAuth()

  return (
    <div className="landing">
      <div className="hero-section">
        <div className="hero-content">
          <h1 className="hero-title">
            🏚️ MUADA Explorer
          </h1>
          <p className="hero-subtitle">
            De geilste Urbex Community in ganz Österreich, Oida!
          </p>
          <p className="hero-description">
            Lost Places, oidn Fabriken, verfallene Krankenhäuser - olle versteckten Schätze auf ana Kinetten-Karte!
          </p>

          {user ? (
            <div className="hero-buttons">
              <Link to="/map" className="btn btn-primary btn-lg">
                Zur Karte, Oida!
              </Link>
              <Link to="/profile" className="btn btn-secondary btn-lg">
                Mei Profü
              </Link>
            </div>
          ) : (
            <div className="hero-buttons">
              <Link to="/signup" className="btn btn-primary btn-lg">
                Jetzt registrieren!
              </Link>
              <Link to="/login" className="btn btn-secondary btn-lg">
                Scho dabei? Eineloggen
              </Link>
            </div>
          )}
        </div>
      </div>

      <div className="features-section container">
        <h2>Wos ma do machen können</h2>
        <div className="features-grid">
          <div className="feature-card">
            <div className="feature-icon">🗺️</div>
            <h3>Kinetten-Karte</h3>
            <p>Entdeck Lost Places in ganz Österreich auf unsera interaktiven Karte</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">📍</div>
            <h3>Locations hinzufügen</h3>
            <p>Host an geilen Spot gfunden? Tua eini in unsere Datenbank!</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">⭐</div>
            <h3>Reviews & Bewertungen</h3>
            <p>Bewert de Locations und schreib wie easy oda gschissn da Zugang woa</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">🏆</div>
            <h3>Ranking System</h3>
            <p>Sammel Punkte und werd vom Newbie zum Urbex Gott!</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">🔒</div>
            <h3>Private Community</h3>
            <p>Nur verifizierte Mitglieder sehen de genauen Koordinaten</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">📸</div>
            <h3>Bilder & Infos</h3>
            <p>Fotos, Sicherheitsinfos, Parkplatz-Tipps und mehr</p>
          </div>
        </div>
      </div>

      <div className="level-system-section">
        <div className="container">
          <h2>Des Ranking System</h2>
          <p className="section-description">
            Besuch Locations, füg neue hinzu und gib Reviews - so steigstn auf!
          </p>

          <div className="levels-grid">
            <div className="level-badge-display">
              <span className="badge badge-user">Urbex Newbie</span>
              <span>0 - 50 Punkte</span>
            </div>
            <div className="level-badge-display">
              <span className="badge badge-mitglied">Temu Urbexer</span>
              <span>51 - 150 Punkte</span>
            </div>
            <div className="level-badge-display">
              <span className="badge badge-mitglied">Hobby Urbexer</span>
              <span>151 - 500 Punkte</span>
            </div>
            <div className="level-badge-display">
              <span className="badge badge-mod">Advanced Urbexer</span>
              <span>501 - 1000 Punkte</span>
            </div>
            <div className="level-badge-display">
              <span className="badge badge-admin">Profi Urbexer</span>
              <span>1001 - 2500 Punkte</span>
            </div>
            <div className="level-badge-display">
              <span className="badge badge-webmaster">Urbex Gott</span>
              <span>2500+ Punkte</span>
            </div>
          </div>

          <div className="points-info">
            <h3>So kriagst Punkte:</h3>
            <ul>
              <li>✅ Location besucht: <strong>+10 Punkte</strong></li>
              <li>📍 Location hinzugfügt (approved): <strong>+50 Punkte</strong></li>
              <li>⭐ Review gschriebn: <strong>+5 Punkte</strong></li>
            </ul>
          </div>
        </div>
      </div>

      <footer className="footer">
        <div className="container">
          <p>&copy; 2026 MUADA Explorer - Urbex Community Austria</p>
          <p>Made with 🏚️ by ochtii</p>
        </div>
      </footer>
    </div>
  )
}

export default Landing
