import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import './AddLocation.css'

const AddLocation = () => {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    coordinates: '',
    address: '',
    category: 'residential',
    condition: 3,
    security_info: '',
    accessibility: '',
    parking_info: '',
    description: ''
  })
  const [images, setImages] = useState([])
  const [previewUrls, setPreviewUrls] = useState([])

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const handleImageChange = (e) => {
    const files = Array.from(e.target.files)
    if (files.length > 5) {
      alert('Maximum 5 Bilder erlaubt, Oida!')
      return
    }

    setImages(files)

    // Create preview URLs
    const urls = files.map(file => URL.createObjectURL(file))
    setPreviewUrls(urls)
  }

  const uploadImages = async () => {
    const uploadedUrls = []

    for (let i = 0; i < images.length; i++) {
      const file = images[i]
      const fileExt = file.name.split('.').pop()
      const fileName = `${user.id}/${Date.now()}_${i}.${fileExt}`

      const { data, error } = await supabase.storage
        .from('locations')
        .upload(fileName, file)

      if (error) {
        console.error('Upload error:', error)
        continue
      }

      const { data: publicUrlData } = supabase.storage
        .from('locations')
        .getPublicUrl(fileName)

      uploadedUrls.push(publicUrlData.publicUrl)
    }

    return uploadedUrls
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)

    try {
      // Validate coordinates format (lat,lng)
      const coordPattern = /^-?\d+\.?\d*,-?\d+\.?\d*$/
      if (!coordPattern.test(formData.coordinates)) {
        alert('Koordinaten müssen im Format "lat,lng" sein (z.B. 48.2082,16.3738)')
        setLoading(false)
        return
      }

      // Upload images
      let imageUrls = []
      if (images.length > 0) {
        imageUrls = await uploadImages()
      }

      // Insert location
      const { data, error } = await supabase
        .from('locations')
        .insert({
          ...formData,
          images: imageUrls,
          created_by: user.id,
          is_approved: false
        })
        .select()
        .single()

      if (error) throw error

      alert('Fix Oida! Location erstellt! Warat jetzt auf Freigabe vom Mod.')
      navigate('/map')
    } catch (err) {
      alert(`Schaß: ${err.message}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="add-location-page">
      <div className="container">
        <h1>📍 Neue Location hinzufügen</h1>
        <p className="page-description">
          Host an geilen Lost Place gfunden? Tua eini in unsere Datenbank!
          A Mod muss de Location erst freigeben, bevor se für alle sichtbar wird.
        </p>

        <form onSubmit={handleSubmit} className="add-location-form card">
          <div className="form-group">
            <label htmlFor="name">Name der Location *</label>
            <input
              id="name"
              name="name"
              type="text"
              value={formData.name}
              onChange={handleInputChange}
              placeholder="z.B. Oides Krankenhaus Wiener Neustadt"
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="coordinates">Koordinaten (lat,lng) *</label>
              <input
                id="coordinates"
                name="coordinates"
                type="text"
                value={formData.coordinates}
                onChange={handleInputChange}
                placeholder="z.B. 48.2082,16.3738"
                required
              />
              <small>Format: latitude,longitude (Google Maps kopieren)</small>
            </div>

            <div className="form-group">
              <label htmlFor="category">Kategorie *</label>
              <select
                id="category"
                name="category"
                value={formData.category}
                onChange={handleInputChange}
                required
              >
                <option value="industrial">🏭 Tschick-Fabrik / Industrial</option>
                <option value="manor">🏰 Oides Schloss / Manor</option>
                <option value="hospital">🏥 Krankenheisl</option>
                <option value="military">💣 Militär</option>
                <option value="residential">🏚️ Oides Heisl</option>
                <option value="bunker">⚠️ Bunker-Loch</option>
                <option value="other">❓ Sonstiges</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="address">Adresse (optional)</label>
            <input
              id="address"
              name="address"
              type="text"
              value={formData.address}
              onChange={handleInputChange}
              placeholder="z.B. Hauptstraße 123, 1234 Wien"
            />
          </div>

          <div className="form-group">
            <label htmlFor="condition">Zustand: {formData.condition}/5</label>
            <input
              id="condition"
              name="condition"
              type="range"
              min="1"
              max="5"
              value={formData.condition}
              onChange={handleInputChange}
            />
            <small>1 = Total verfallen, 5 = Noch gut erhalten</small>
          </div>

          <div className="form-group">
            <label htmlFor="security_info">⚠️ Sicherheitsinfos</label>
            <textarea
              id="security_info"
              name="security_info"
              value={formData.security_info}
              onChange={handleInputChange}
              placeholder="z.B. Wachdienst, Kameras, Nachbarn schauen, etc."
              rows="3"
            />
          </div>

          <div className="form-group">
            <label htmlFor="accessibility">🚪 Zugang / Wie reinkommt man?</label>
            <textarea
              id="accessibility"
              name="accessibility"
              value={formData.accessibility}
              onChange={handleInputChange}
              placeholder="z.B. Durch Loch im Zaun, offene Tür, ..."
              rows="3"
            />
          </div>

          <div className="form-group">
            <label htmlFor="parking_info">🅿️ Parkplatz-Infos</label>
            <input
              id="parking_info"
              name="parking_info"
              type="text"
              value={formData.parking_info}
              onChange={handleInputChange}
              placeholder="z.B. 200m entfernt, Seitenstraße"
            />
          </div>

          <div className="form-group">
            <label htmlFor="description">Beschreibung</label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Wos gibt's do zu sehen? Wos is speziell?"
              rows="5"
            />
          </div>

          <div className="form-group">
            <label htmlFor="images">📸 Bilder (max. 5)</label>
            <input
              id="images"
              type="file"
              accept="image/*"
              multiple
              onChange={handleImageChange}
            />
            {previewUrls.length > 0 && (
              <div className="image-previews">
                {previewUrls.map((url, idx) => (
                  <img key={idx} src={url} alt={`Preview ${idx + 1}`} />
                ))}
              </div>
            )}
          </div>

          <button type="submit" className="btn btn-primary btn-block btn-lg" disabled={loading}>
            {loading ? 'Wart kurz, Oida...' : '✅ Location eintragen'}
          </button>
        </form>
      </div>
    </div>
  )
}

export default AddLocation
