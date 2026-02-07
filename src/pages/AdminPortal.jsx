import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import './AdminPortal.css'

const AdminPortal = () => {
  const { profile } = useAuth()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error

      setUsers(data || [])
    } catch (err) {
      console.error('Error fetching users:', err)
    } finally {
      setLoading(false)
    }
  }

  const handleRoleChange = async (userId, newRole) => {
    // Check if user can assign this role
    const roleHierarchy = {
      user: 1,
      mitglied: 2,
      mod: 3,
      admin: 4,
      webmaster: 5
    }

    const currentUserLevel = roleHierarchy[profile.role]
    const targetRoleLevel = roleHierarchy[newRole]

    if (currentUserLevel <= targetRoleLevel && profile.role !== 'webmaster') {
      alert('Du Wappla! Du kannst nur niedrigere Rollen vergeben als deine eigene!')
      return
    }

    try {
      const { error } = await supabase.rpc('assign_user_role', {
        target_user_id: userId,
        new_role: newRole
      })

      if (error) throw error

      alert('Fix Oida! Rolle geändert.')
      fetchUsers()
    } catch (err) {
      // Fallback if function doesn't work
      try {
        const { error: directError } = await supabase
          .from('profiles')
          .update({ role: newRole })
          .eq('id', userId)

        if (directError) throw directError

        alert('Fix Oida! Rolle geändert.')
        fetchUsers()
      } catch (directErr) {
        alert(`Schaß: ${directErr.message}`)
      }
    }
  }

  const getFilteredUsers = () => {
    if (filter === 'all') return users
    return users.filter(u => u.role === filter)
  }

  const getRoleHierarchyLevel = (role) => {
    // WICHTIG: Muss mit app_role ENUM übereinstimmen!
    const hierarchy = {
      banned: 0,
      explorer: 1,
      moderator: 2,
      webmaster: 3
    }
    return hierarchy[role] || 0
  }

  const canEditUser = (targetUserRole) => {
    if (profile.role === 'webmaster') return true
    return getRoleHierarchyLevel(profile.role) > getRoleHierarchyLevel(targetUserRole)
  }

  const availableRoles = () => {
    if (profile.role === 'webmaster') {
      return ['banned', 'explorer', 'moderator', 'webmaster']
    } else if (profile.role === 'moderator') {
      return ['banned', 'explorer']
    }
    return []
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
    <div className="admin-portal-page">
      <div className="container">
        <h1>👑 Admin Portal</h1>
        <p className="portal-description">
          Seas {profile.username}! Manage Users und deren Rollen.
        </p>

        <div className="filter-bar">
          <button
            onClick={() => setFilter('all')}
            className={`btn ${filter === 'all' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Alle ({users.length})
          </button>
          <button
            onClick={() => setFilter('explorer')}
            className={`btn ${filter === 'explorer' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Explorer ({users.filter(u => u.role === 'explorer').length})
          </button>
          <button
            onClick={() => setFilter('moderator')}
            className={`btn ${filter === 'moderator' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Moderator ({users.filter(u => u.role === 'moderator').length})
          </button>
          <button
            onClick={() => setFilter('webmaster')}
            className={`btn ${filter === 'webmaster' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Webmaster ({users.filter(u => u.role === 'webmaster').length})
          </button>
          <button
            onClick={() => setFilter('banned')}
            className={`btn ${filter === 'banned' ? 'btn-primary' : 'btn-secondary'}`}
          >
            Banned ({users.filter(u => u.role === 'banned').length})
          </button>
        </div>

        <div className="users-table card">
          <table>
            <thead>
              <tr>
                <th>Username</th>
                <th>Rolle</th>
                <th>Level</th>
                <th>Punkte</th>
                <th>Visits</th>
                <th>Locations</th>
                <th>Erstellt am</th>
                <th>Aktionen</th>
              </tr>
            </thead>
            <tbody>
              {getFilteredUsers().map((user) => (
                <tr key={user.id}>
                  <td>
                    <strong>{user.username}</strong>
                    {user.id === profile.id && <span className="badge badge-warning">Du</span>}
                  </td>
                  <td>
                    <span className={`badge badge-${user.role}`}>{user.role}</span>
                  </td>
                  <td>{user.level_badge}</td>
                  <td>{user.points}</td>
                  <td>{user.visited_count}</td>
                  <td>{user.added_count}</td>
                  <td>{new Date(user.created_at).toLocaleDateString('de-AT')}</td>
                  <td>
                    {canEditUser(user.role) && user.id !== profile.id ? (
                      <select
                        value={user.role}
                        onChange={(e) => handleRoleChange(user.id, e.target.value)}
                        className="role-select"
                      >
                        {availableRoles().map((role) => (
                          <option key={role} value={role}>{role}</option>
                        ))}
                      </select>
                    ) : (
                      <span style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                        {user.id === profile.id ? 'Du selbst' : 'Keine Berechtigung'}
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {getFilteredUsers().length === 0 && (
          <div className="card" style={{ textAlign: 'center', padding: '2rem' }}>
            <p>Keine User mit diesem Filter gfunden.</p>
          </div>
        )}
      </div>
    </div>
  )
}

export default AdminPortal
