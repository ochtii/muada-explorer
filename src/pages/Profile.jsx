import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import './Profile.css'

const Profile = () => {
  const { user, profile, updateProfile, refreshProfile } = useAuth()
  const [visits, setVisits] = useState([])
  const [myLocations, setMyLocations] = useState([])
  const [loading, setLoading] = useState(true)
  const [editMode, setEditMode] = useState(false)
  const [newUsername, setNewUsername] = useState('')
  const [avatarFile, setAvatarFile] = useState(null)
  const [avatarPreview, setAvatarPreview] = useState(null)
  const [uploadingAvatar, setUploadingAvatar] = useState(false)

  useEffect(() => {
    if (profile) {
      setNewUsername(profile.username)
      fetchUserData()
    }
  }, [profile])

  const fetchUserData = async () => {
    try {
      // Fetch visits with location info
      const { data: visitsData } = await supabase
        .from('visits')
        .select(`
          *,
          locations (id, name, category)
        `)
        .eq('user_id', user.id)
        .order('visited_at', { ascending: false })

      setVisits(visitsData || [])

      // Fetch locations created by user
      const { data: locationsData } = await supabase
        .from('locations')
        .select('*')
        .eq('created_by', user.id)
        .order('created_at', { ascending: false })

      setMyLocations(locationsData || [])
    } catch (err) {
      console.error('Error fetching user data:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleAvatarChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        alert('Bild zu groß! Maximum 2MB, Oida!')
        return
      }
      setAvatarFile(file)
      setAvatarPreview(URL.createObjectURL(file))
    }
  }

  const handleAvatarUpload = async () => {
    if (!avatarFile) return

    setUploadingAvatar(true)

    try {
      const fileExt = avatarFile.name.split('.').pop()
      const fileName = `${user.id}/avatar.${fileExt}`

      // Upload to storage
      const { error: uploadError } = await supabase.storage
        .from('avatars')
        .upload(fileName, avatarFile, { upsert: true })

      if (uploadError) throw uploadError

      // Get public URL
      const { data: publicUrlData } = supabase.storage
        .from('avatars')
        .getPublicUrl(fileName)

      // Update profile
      await updateProfile({ avatar_url: publicUrlData.publicUrl })

      alert('Fix Oida! Avatar hochgeladen!')
      setAvatarFile(null)
      setAvatarPreview(null)
      refreshProfile()
    } catch (err) {
      alert(`Schaß: ${err.message}`)
    } finally {
      setUploadingAvatar(false)
    }
  }

  const handleUpdateUsername = async () => {
    if (newUsername === profile.username) {
      setEditMode(false)
      return
    }

    if (newUsername.length < 3) {
      alert('Username muss mindestens 3 Zeichen hobn!')
      return
    }

    const { error } = await updateProfile({ username: newUsername })

    if (error) {
      alert(`Schaß: ${error}`)
    } else {
      alert('Fix! Username geändert.')
      setEditMode(false)
      refreshProfile()
    }
  }

  const getRoleBadgeEmoji = (role) => {
    const emojis = {
      user: '👤',
      mitglied: '✅',
      mod: '⭐',
      admin: '👑',
      webmaster: '🔥'
    }
    return emojis[role] || '👤'
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
    <div className="profile-page">
      <div className="container">
        <h1>👤 Mei Profü</h1>

        <div className="profile-content">
          {/* Profile Card */}
          <div className="card profile-card">
            <div className="avatar-section">
              {avatarPreview ? (
                <img src={avatarPreview} alt="Avatar Preview" className="avatar-preview" />
              ) : profile.avatar_url ? (
                <img src={profile.avatar_url} alt={profile.username} className="avatar" />
              ) : (
                <div className="avatar-placeholder">
                  {profile.username.charAt(0).toUpperCase()}
                </div>
              )}

              <input
                type="file"
                accept="image/*"
                onChange={handleAvatarChange}
                style={{ display: 'none' }}
                id="avatar-upload"
              />
              <label htmlFor="avatar-upload" className="btn btn-secondary btn-sm">
                📸 Avatar ändern
              </label>

              {avatarFile && (
                <button
                  onClick={handleAvatarUpload}
                  className="btn btn-primary btn-sm"
                  disabled={uploadingAvatar}
                >
                  {uploadingAvatar ? 'Uploading...' : 'Hochladen'}
                </button>
              )}
            </div>

            <div className="profile-info">
              {editMode ? (
                <div className="edit-username">
                  <input
                    type="text"
                    value={newUsername}
                    onChange={(e) => setNewUsername(e.target.value)}
                  />
                  <button onClick={handleUpdateUsername} className="btn btn-primary btn-sm">
                    Speichern
                  </button>
                  <button onClick={() => setEditMode(false)} className="btn btn-secondary btn-sm">
                    Abbrechen
                  </button>
                </div>
              ) : (
                <div className="username-display">
                  <h2>{profile.username}</h2>
                  <button onClick={() => setEditMode(true)} className="btn btn-secondary btn-sm">
                    ✏️ Bearbeiten
                  </button>
                </div>
              )}

              <div className="role-badge-large">
                {getRoleBadgeEmoji(profile.role)}
                <span className={`badge badge-${profile.role}`}>{profile.role}</span>
              </div>

              <div className="level-badge-large">
                <h3>{profile.level_badge}</h3>
                <p>{profile.points} Punkte</p>
              </div>
            </div>
          </div>

          {/* Stats Card */}
          <div className="card stats-card">
            <h2>📊 Statistiken</h2>
            <div className="stats-grid">
              <div className="stat-item">
                <div className="stat-icon">📍</div>
                <div className="stat-value">{profile.visited_count}</div>
                <div className="stat-label">Besucht</div>
                <div className="stat-calculation">× 10 = {profile.visited_count * 10} Punkte</div>
              </div>

              <div className="stat-item">
                <div className="stat-icon">➕</div>
                <div className="stat-value">{profile.added_count}</div>
                <div className="stat-label">Hinzugfügt</div>
                <div className="stat-calculation">× 50 = {profile.added_count * 50} Punkte</div>
              </div>

              <div className="stat-item">
                <div className="stat-icon">⭐</div>
                <div className="stat-value">{profile.points}</div>
                <div className="stat-label">Gesamt Punkte</div>
              </div>
            </div>
            
            <div className="points-breakdown">
              <small>
                💡 Punkte-Berechnung: (Visits × 10) + (Locations × 50) + (Reviews × 5) = {profile.points} Punkte
              </small>
            </div>
          </div>

          {/* My Visits */}
          <div className="card">
            <h2>🗺️ Meine Visits ({visits.length})</h2>
            {visits.length > 0 ? (
              <div className="visits-list">
                {visits.map((visit) => (
                  <div key={visit.id} className="visit-item">
                    <div>
                      <strong>{visit.locations.name}</strong>
                      <small>{new Date(visit.visited_at).toLocaleDateString('de-AT')}</small>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="empty-state">Noch kane Locations besucht. Los geht's, Oida!</p>
            )}
          </div>

          {/* My Locations */}
          <div className="card">
            <h2>📍 Meine Locations ({myLocations.length})</h2>
            {myLocations.length > 0 ? (
              <div className="locations-list">
                {myLocations.map((location) => (
                  <div key={location.id} className="location-item">
                    <div>
                      <strong>{location.name}</strong>
                      <small>{location.category}</small>
                    </div>
                    <span className={`badge ${location.is_approved ? 'badge-success' : 'badge-warning'}`}>
                      {location.is_approved ? '✅ Approved' : '⏳ Pending'}
                    </span>
                  </div>
                ))}
              </div>
            ) : (
              <p className="empty-state">Noch kane Locations hinzugfügt. Füg deine erste hinzu!</p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default Profile
