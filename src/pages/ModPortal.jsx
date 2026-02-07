import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import './ModPortal.css'

const ModPortal = () => {
  const { profile } = useAuth()
  const [pendingLocations, setPendingLocations] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedLocation, setSelectedLocation] = useState(null)

  useEffect(() => {
    fetchPendingLocations()
  }, [])

  const fetchPendingLocations = async () => {
    try {
      const { data, error } = await supabase
        .from('locations')
        .select(`
          *,
          profiles (username, role)
        `)
        .eq('is_approved', false)
        .order('created_at', { ascending: false })

      if (error) throw error

      setPendingLocations(data || [])
    } catch (err) {
      console.error('Error fetching pending locations:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleApprove = async (locationId) => {
    try {
      const { error } = await supabase
        .from('locations')
        .update({ is_approved: true })
        .eq('id', locationId)

      if (error) throw error

      alert('Fix Oida! Location approved.')
      fetchPendingLocations()
      setSelectedLocation(null)
    } catch (err) {
      alert(`Schaß: ${err.message}`)
    }
  }

  const handleReject = async (locationId) => {
    if (!confirm('Wirklich löschen? Des geht ned rückgängig zu machen!')) {
      return
    }

    try {
      const { error } = await supabase
        .from('locations')
        .delete()
        .eq('id', locationId)

      if (error) throw error

      alert('Location gelöscht.')
      fetchPendingLocations()
      setSelectedLocation(null)
    } catch (err) {
      alert(`Schaß: ${err.message}`)
    }
  }

  const getCategoryLabel = (category) => {
    const labels = {
      industrial: '🏭 Tschick-Fabrik',
      manor: '🏰 Oides Schloss',
      hospital: '🏥 Krankenheisl',
      military: '💣 Militär',
      residential: '🏚️ Oides Heisl',
      bunker: '⚠️ Bunker-Loch',
      other: '❓ Sonstiges'
    }
    return labels[category] || category
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Wart kurz...</p>
      </div>
    )
  }

  return (
    <div className="mod-portal-page">
      <div className="container">
        <h1>⭐ Mod Portal</h1>
        <p className="portal-description">
          Seas {profile.username}! Do kannst Locations freigeben oder löschen.
        </p>

        {pendingLocations.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '3rem' }}>
            <h2>✅ Leiwand!</h2>
            <p>Momentan keine Locations zum Reviewen.</p>
          </div>
        ) : (
          <div className="pending-locations-grid">
            {pendingLocations.map((location) => (
              <div key={location.id} className="card location-card">
                <h3>{location.name}</h3>
                <p><strong>Kategorie:</strong> {getCategoryLabel(location.category)}</p>
                <p><strong>Zustand:</strong> {'⭐'.repeat(location.condition || 0)}</p>
                <p><strong>Erstellt von:</strong> {location.profiles.username}</p>
                <p><strong>📍 Koordinaten:</strong> {location.coordinates}</p>
                <p><strong>🏠 Adresse:</strong> {location.address || 'Keine Angabe'}</p>

                {location.security_info && (
                  <p><strong>⚠️ Sicherheit:</strong> {location.security_info}</p>
                )}

                {location.description && (
                  <div className="description-box">
                    <strong>Beschreibung:</strong>
                    <p>{location.description}</p>
                  </div>
                )}

                {location.images && location.images.length > 0 && (
                  <div className="location-images">
                    {location.images.map((img, idx) => (
                      <img key={idx} src={img} alt={`Image ${idx + 1}`} />
                    ))}
                  </div>
                )}

                <div className="action-buttons">
                  <button
                    onClick={() => handleApprove(location.id)}
                    className="btn btn-primary"
                  >
                    ✅ Freigeben
                  </button>
                  <button
                    onClick={() => handleReject(location.id)}
                    className="btn btn-danger"
                  >
                    ❌ Löschen
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default ModPortal
