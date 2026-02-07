import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import Navbar from './components/Navbar'
import Landing from './pages/Landing'
import Login from './pages/Login'
import Signup from './pages/Signup'
import Map from './pages/Map'
import LocationDetails from './pages/LocationDetails'
import AddLocation from './pages/AddLocation'
import Profile from './pages/Profile'
import AdminPortal from './pages/AdminPortal'
import ModPortal from './pages/ModPortal'

const ProtectedRoute = ({ children, minRole }) => {
  const { user, profile, loading, hasRole } = useAuth()

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Wart kurz, Oida...</p>
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  if (minRole && !hasRole(minRole)) {
    return (
      <div className="container" style={{ textAlign: 'center', marginTop: '3rem' }}>
        <h1>🚫 Gschissn!</h1>
        <p>Du Wappla host kan Zugriff auf de Seiten!</p>
        <p>Brauchst mindestens: <span className={`badge badge-${minRole}`}>{minRole}</span></p>
      </div>
    )
  }

  return children
}

function App() {
  const { loading } = useAuth()

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Wart kurz, Oida...</p>
      </div>
    )
  }

  return (
    <>
      <Navbar />
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        
        <Route path="/map" element={
          <ProtectedRoute>
            <Map />
          </ProtectedRoute>
        } />
        
        <Route path="/location/:id" element={
          <ProtectedRoute>
            <LocationDetails />
          </ProtectedRoute>
        } />
        
        <Route path="/add-location" element={
          <ProtectedRoute minRole="explorer">
            <AddLocation />
          </ProtectedRoute>
        } />
        
        <Route path="/profile" element={
          <ProtectedRoute>
            <Profile />
          </ProtectedRoute>
        } />
        
        <Route path="/mod-portal" element={
          <ProtectedRoute minRole="moderator">
            <ModPortal />
          </ProtectedRoute>
        } />
        
        <Route path="/admin-portal" element={
          <ProtectedRoute minRole="webmaster">
            <AdminPortal />
          </ProtectedRoute>
        } />
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  )
}

export default App
