import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import L from 'leaflet'
import './Map.css'

// Fix für Leaflet default icons
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
})

// Custom Icons für visited/not visited
const visitedIcon = new L.Icon({
  iconUrl: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNSIgaGVpZ2h0PSI0MSI+PHBhdGggZmlsbD0iIzI4YTc0NSIgZD0iTTEyLjUgMEMxOS40IDAgMjUgNS42IDI1IDEyLjVjMCAxMC41LTEyLjUgMjguNS0xMi41IDI4LjVTMCAyMyAwIDEyLjVDMCA1LjYgNS42IDAgMTIuNSAweiIvPjwvc3ZnPg==',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: markerShadow,
  shadowSize: [41, 41]
})

const notVisitedIcon = new L.Icon({
  iconUrl: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNSIgaGVpZ2h0PSI0MSI+PHBhdGggZmlsbD0iI2ZmNmIzNSIgZD0iTTEyLjUgMEMxOS40IDAgMjUgNS42IDI1IDEyLjVjMCAxMC41LTEyLjUgMjguNS0xMi41IDI4LjVTMCAyMyAwIDEyLjVDMCA1LjYgNS42IDAgMTIuNSAweiIvPjwvc3ZnPg==',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowUrl: markerShadow,
  shadowSize: [41, 41]
})

const Map = () => {
  const [locations, setLocations] = useState([])
  const [visits, setVisits] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const { user, profile, hasRole } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    fetchLocations()
    fetchVisits()
  }, [])

  const fetchLocations = async () => {
    try {
      const { data, error } = await supabase
        .from('locations_view')
        .select('*')
        .eq('is_approved', true)

      if (error) throw error

      setLocations(data || [])
    } catch (err) {
      setError(`Schaß beim Locations laden: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  const fetchVisits = async () => {
    try {
      const { data, error } = await supabase
        .from('visits')
        .select('location_id')
        .eq('user_id', user.id)

      if (error) throw error

      setVisits(data.map(v => v.location_id))
    } catch (err) {
      console.error('Error fetching visits:', err)
    }
  }

  const isVisited = (locationId) => visits.includes(locationId)

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
        <p>Wart kurz, load de Kinetten...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="container" style={{ textAlign: 'center', marginTop: '3rem' }}>
        <h1>❌ Gschissn!</h1>
        <p>{error}</p>
      </div>
    )
  }

  return (
    <div className="map-page">
      <div className="map-header">
        <h1>🗺️ Kinetten-Karte</h1>
        <p>
          <span className="badge badge-success">✅ Besucht: {visits.length}</span>
          <span className="badge badge-warning">📍 Gesamt: {locations.length}</span>
        </p>
      </div>

      <div className="map-container-wrapper">
        <MapContainer
          center={[47.5, 14.5]}
          zoom={8}
          className="leaflet-map"
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {locations.map((location) => {
            // Nur Mitglied+ sehen Koordinaten
            if (!location.coordinates && !hasRole('mitglied')) {
              return null
            }

            if (!location.coordinates) return null

            const [lat, lng] = location.coordinates.split(',').map(Number)

            return (
              <Marker
                key={location.id}
                position={[lat, lng]}
                icon={isVisited(location.id) ? visitedIcon : notVisitedIcon}
              >
                <Popup>
                  <div className="popup-content">
                    <h3>{location.name}</h3>
                    <p><strong>Kategorie:</strong> {getCategoryLabel(location.category)}</p>
                    <p><strong>Zustand:</strong> {'⭐'.repeat(location.condition || 0)}</p>
                    {location.security_info && (
                      <p><strong>⚠️ Sicherheit:</strong> {location.security_info}</p>
                    )}
                    <button
                      onClick={() => navigate(`/location/${location.id}`)}
                      className="btn btn-primary btn-sm"
                      style={{ marginTop: '0.5rem' }}
                    >
                      Details anzeigen
                    </button>
                  </div>
                </Popup>
              </Marker>
            )
          })}
        </MapContainer>
      </div>

      {!hasRole('mitglied') && (
        <div className="warning-banner">
          <h3>⚠️ Du Wappla!</h3>
          <p>
            Du siehst nur de Marker, oba kane Koordinaten oder genaue Infos!
            Werd erst <span className="badge badge-mitglied">Mitglied</span> um alles zu sehen.
          </p>
        </div>
      )}
    </div>
  )
}

export default Map
