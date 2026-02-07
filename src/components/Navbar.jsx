import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import './Navbar.css'

const Navbar = () => {
  const { user, profile, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/')
  }

  return (
    <nav className="navbar">
      <div className="navbar-container">
        <Link to="/" className="navbar-logo">
          🏚️ MUADA Explorer
        </Link>

        <ul className="navbar-menu">
          {user ? (
            <>
              <li><Link to="/map">Kinetten-Karte</Link></li>
              <li><Link to="/add-location">Location hinzufügen</Link></li>
              <li><Link to="/profile">
                Profü ({profile?.username})
                <span className={`badge badge-${profile?.role}`}>
                  {profile?.role}
                </span>
              </Link></li>
              
              {profile?.role === 'moderator' || profile?.role === 'webmaster' ? (
                <li><Link to="/mod-portal">Mod Portal</Link></li>
              ) : null}
              
              {profile?.role === 'webmaster' ? (
                <li><Link to="/admin-portal">Admin Portal</Link></li>
              ) : null}
              
              <li>
                <button onClick={handleSignOut} className="btn btn-danger btn-sm">
                  Schleich di
                </button>
              </li>
            </>
          ) : (
            <>
              <li><Link to="/login" className="btn btn-secondary btn-sm">Eineloggen</Link></li>
              <li><Link to="/signup" className="btn btn-primary btn-sm">Registrieren</Link></li>
            </>
          )}
        </ul>
      </div>
    </nav>
  )
}

export default Navbar
