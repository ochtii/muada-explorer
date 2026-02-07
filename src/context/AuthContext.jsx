import { createContext, useContext, useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'

const AuthContext = createContext({})

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check active session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      if (session?.user) {
        fetchProfile(session.user.id)
      } else {
        setLoading(false)
      }
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        setUser(session?.user ?? null)
        if (session?.user) {
          await fetchProfile(session.user.id)
        } else {
          setProfile(null)
          setLoading(false)
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const fetchProfile = async (userId) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()

      if (error) {
        // Wenn kein Profile existiert, zeige hilfreichen Fehler
        if (error.code === 'PGRST116') {
          console.error('⚠️ KEIN PROFILE GEFUNDEN! Trigger hat wsl versagt.')
          console.error('→ Geh zum Supabase Dashboard und führe 02-functions.sql aus!')
          alert('Schaß! Dein Profile konnte ned erstellt werden.\n\nGeh zum Supabase Dashboard und führe 02-functions.sql aus, dann meld di neu an!')
        }
        throw error
      }
      setProfile(data)
    } catch (error) {
      console.error('Schaß beim Profile laden:', error.message)
      setProfile(null)
    } finally {
      setLoading(false)
    }
  }

  const signUp = async (email, password, username) => {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            username: username
          }
        }
      })

      if (error) throw error

      return { data, error: null }
    } catch (error) {
      return { data: null, error: error.message }
    }
  }

  const signIn = async (email, password) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) throw error

      return { data, error: null }
    } catch (error) {
      return { data: null, error: error.message }
    }
  }

  const signOut = async () => {
    try {
      const { error } = await supabase.auth.signOut()
      if (error) throw error
      setUser(null)
      setProfile(null)
    } catch (error) {
      console.error('Schaß beim Ausloggen:', error.message)
    }
  }

  const updateProfile = async (updates) => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single()

      if (error) throw error

      setProfile(data)
    // WICHTIG: Diese Rollen müssen mit app_role ENUM übereinstimmen!
    // Datenbank: 'banned', 'explorer', 'moderator', 'webmaster'
    const roleHierarchy = {
      banned: 0,      // Gesperrt
      explorer: 1,    // Normaler User
      moderator: 2,   // Moderator
      webmaster: 3    // Admin/Webmaster
    }

    const userLevel = roleHierarchy[profile.role]
    const minLevel = roleHierarchy[minRole]
    
    // Wenn Role unbekannt ist, logge Warnung
    if (userLevel === undefined) {
      console.warn('⚠️ Unbekannte User-Role:', profile.role)
      return false
    }
    if (minLevel === undefined) {
      console.warn('⚠️ Unbekannte Min-Role:', minRole)
      return false
    }

    return userLevel >= minLevel
    const roleHierarchy = {
      user: 1,
      mitglied: 2,
      mod: 3,
      admin: 4,
      webmaster: 5
    }

    return roleHierarchy[profile.role] >= roleHierarchy[minRole]
  }

  const refreshProfile = () => {
    if (user) {
      fetchProfile(user.id)
    }
  }

  const value = {
    user,
    profile,
    loading,
    signUp,
    signIn,
    signOut,
    updateProfile,
    hasRole,
    refreshProfile
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
