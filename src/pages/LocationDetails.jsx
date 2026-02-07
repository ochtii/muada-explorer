import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import './LocationDetails.css'

const LocationDetails = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const { user, profile, hasRole } = useAuth()
  const [location, setLocation] = useState(null)
  const [reviews, setReviews] = useState([])
  const [isVisited, setIsVisited] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [newReview, setNewReview] = useState({
    comment: '',
    rating_condition: 3,
    rating_risk: 3,
    rating_accessibility: 3
  })
  const [reviewLoading, setReviewLoading] = useState(false)

  useEffect(() => {
    fetchLocationDetails()
    fetchReviews()
    checkIfVisited()
  }, [id])

  const fetchLocationDetails = async () => {
    try {
      const { data, error } = await supabase
        .from('locations_view')
        .select('*')
        .eq('id', id)
        .single()

      if (error) throw error

      setLocation(data)
    } catch (err) {
      setError(`Schaß beim Location laden: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  const fetchReviews = async () => {
    try {
      const { data, error } = await supabase
        .from('reviews')
        .select(`
          *,
          profiles (username, role)
        `)
        .eq('location_id', id)
        .order('created_at', { ascending: false })

      if (error) throw error

      setReviews(data || [])
    } catch (err) {
      console.error('Error fetching reviews:', err)
    }
  }

  const checkIfVisited = async () => {
    try {
      const { data, error } = await supabase
        .from('visits')
        .select('id')
        .eq('user_id', user.id)
        .eq('location_id', id)
        .single()

      setIsVisited(!!data)
    } catch (err) {
      setIsVisited(false)
    }
  }

  const handleMarkAsVisited = async () => {
    if (isVisited) {
      // Remove visit
      try {
        const { error } = await supabase
          .from('visits')
          .delete()
          .eq('user_id', user.id)
          .eq('location_id', id)

        if (error) throw error

        setIsVisited(false)
        alert('Fix! Visit entfernt.')
      } catch (err) {
        alert(`Schaß: ${err.message}`)
      }
    } else {
      // Add visit
      try {
        const { error } = await supabase
          .from('visits')
          .insert({
            user_id: user.id,
            location_id: id
          })

        if (error) throw error

        setIsVisited(true)
        alert('Leiwand! Als besucht markiert.')
      } catch (err) {
        alert(`Schaß: ${err.message}`)
      }
    }
  }

  const handleReviewSubmit = async (e) => {
    e.preventDefault()
    setReviewLoading(true)

    try {
      const { error } = await supabase
        .from('reviews')
        .insert({
          location_id: id,
          user_id: user.id,
          ...newReview
        })

      if (error) throw error

      alert('Fix Oida! Review gschrieben!')
      setNewReview({
        comment: '',
        rating_condition: 3,
        rating_risk: 3,
        rating_accessibility: 3
      })
      fetchReviews()
    } catch (err) {
      alert(`Schaß: ${err.message}`)
    } finally {
      setReviewLoading(false)
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

  if (error || !location) {
    return (
      <div className="container" style={{ textAlign: 'center', marginTop: '3rem' }}>
        <h1>❌ Gschissn!</h1>
        <p>{error || 'Location ned gfunden'}</p>
        <button onClick={() => navigate('/map')} className="btn btn-primary">
          Zruck zur Karte
        </button>
      </div>
    )
  }

  const canSeeCoordinates = hasRole('mitglied')

  return (
    <div className="location-details-page">
      <div className="container">
        <button onClick={() => navigate('/map')} className="btn btn-secondary">
          ← Zruck zur Karte
        </button>

        <div className="location-header">
          <h1>{location.name}</h1>
          <div className="location-meta">
            <span className="badge badge-mitglied">{getCategoryLabel(location.category)}</span>
            <span className="badge badge-warning">Zustand: {'⭐'.repeat(location.condition || 0)}</span>
            {isVisited && <span className="badge badge-success">✅ Besucht</span>}
          </div>
        </div>

        <div className="location-content">
          {location.images && location.images.length > 0 && (
            <div className="location-images">
              {location.images.map((img, idx) => (
                <img key={idx} src={img} alt={`${location.name} ${idx + 1}`} />
              ))}
            </div>
          )}

          <div className="location-info card">
            <h2>Infos</h2>

            {canSeeCoordinates ? (
              <>
                <p><strong>📍 Koordinaten:</strong> {location.coordinates}</p>
                <p><strong>🏠 Adresse:</strong> {location.address || 'Keine Angabe'}</p>
                <p><strong>🅿️ Parkplatz:</strong> {location.parking_info || 'Keine Angabe'}</p>
              </>
            ) : (
              <div className="access-denied">
                <h3>⚠️ Du Wappla!</h3>
                <p>Werd erst <span className="badge badge-mitglied">Mitglied</span> um de Koordinaten und Adresse zu sehen!</p>
              </div>
            )}

            <p><strong>⚠️ Sicherheit:</strong> {location.security_info || 'Keine Angabe'}</p>
            <p><strong>🚪 Zugang:</strong> {location.accessibility || 'Keine Angabe'}</p>

            {location.description && (
              <>
                <h3>Beschreibung</h3>
                <p>{location.description}</p>
              </>
            )}

            <button
              onClick={handleMarkAsVisited}
              className={`btn ${isVisited ? 'btn-secondary' : 'btn-primary'} btn-block`}
              style={{ marginTop: '1rem' }}
            >
              {isVisited ? '❌ Visit entfernen' : '✅ Als besucht markieren'}
            </button>
          </div>

          {/* Reviews Section */}
          <div className="reviews-section">
            <h2>Reviews ({reviews.length})</h2>

            {/* Add Review Form */}
            <div className="card">
              <h3>Schreib a Review, Oida!</h3>
              <form onSubmit={handleReviewSubmit} className="review-form">
                <div className="rating-group">
                  <label>Zustand: {newReview.rating_condition}/5</label>
                  <input
                    type="range"
                    min="1"
                    max="5"
                    value={newReview.rating_condition}
                    onChange={(e) => setNewReview({...newReview, rating_condition: parseInt(e.target.value)})}
                  />
                </div>

                <div className="rating-group">
                  <label>Risiko: {newReview.rating_risk}/5</label>
                  <input
                    type="range"
                    min="1"
                    max="5"
                    value={newReview.rating_risk}
                    onChange={(e) => setNewReview({...newReview, rating_risk: parseInt(e.target.value)})}
                  />
                </div>

                <div className="rating-group">
                  <label>Zugang: {newReview.rating_accessibility}/5</label>
                  <input
                    type="range"
                    min="1"
                    max="5"
                    value={newReview.rating_accessibility}
                    onChange={(e) => setNewReview({...newReview, rating_accessibility: parseInt(e.target.value)})}
                  />
                </div>

                <textarea
                  placeholder="Wie wars? Wos host gsehn? Wos sollt ma aufpassn?"
                  value={newReview.comment}
                  onChange={(e) => setNewReview({...newReview, comment: e.target.value})}
                  rows="4"
                  required
                />

                <button type="submit" className="btn btn-primary" disabled={reviewLoading}>
                  {reviewLoading ? 'Wart kurz...' : 'Review absenden'}
                </button>
              </form>
            </div>

            {/* Display Reviews */}
            <div className="reviews-list">
              {reviews.map((review) => (
                <div key={review.id} className="card review-card">
                  <div className="review-header">
                    <div>
                      <strong>{review.profiles.username}</strong>
                      <span className={`badge badge-${review.profiles.role}`}>{review.profiles.role}</span>
                    </div>
                    <small>{new Date(review.created_at).toLocaleDateString('de-AT')}</small>
                  </div>

                  <div className="review-ratings">
                    <span>Zustand: {'⭐'.repeat(review.rating_condition)}</span>
                    <span>Risiko: {'⚠️'.repeat(review.rating_risk)}</span>
                    <span>Zugang: {'🚪'.repeat(review.rating_accessibility)}</span>
                  </div>

                  <p className="review-comment">{review.comment}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default LocationDetails
