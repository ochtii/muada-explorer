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
    console.log('🔍 fetchProfile() aufgerufen für userId:', userId)
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()

      console.log('📊 Supabase Response:', { data, error })

      if (error) {
        // Wenn kein Profile existiert, zeige hilfreichen Fehler
        if (error.code === 'PGRST116') {
          console.error('⚠️ KEIN PROFILE GEFUNDEN! Trigger hat wsl versagt.')
          console.error('→ User existiert in auth.users aber NICHT in profiles Tabelle')
          console.error('→ Führe 99-diagnose.sql aus um zu prüfen welche User fehlen')
          console.error('→ Dann führe 02-functions.sql aus und registriere dich neu')
          alert('⚠️ KEIN PROFILE!\n\nDu wurdest registriert aber dein Profile wurde nicht erstellt.\n\n1. Geh zu Supabase SQL Editor\n2. Führe 99-diagnose.sql aus\n3. Führe 02-functions.sql aus\n4. Lösche deinen User und registriere dich neu')
        } else if (error.code === '42501') {
          console.error('🔒 PERMISSION DENIED! RLS Policy fehlt oder ist falsch')
          console.error('→ Führe 03-policies.sql aus!')
          alert('🔒 PERMISSION DENIED!\n\nDu kannst dein Profile nicht lesen.\n\n→ Führe 03-policies.sql im Supabase SQL Editor aus')
        } else {
          console.error('❌ Unbekannter Fehler beim Profile laden:', error)
        }
        throw error
      }
      
      console.log('✅ Profile geladen:', data)
      setProfile(data)
    } catch (error) {
      console.error('💥 Schaß beim Profile laden:', error.message, error)
      setProfile(null)
    } finally {
      console.log('🏁 fetchProfile() beendet - setLoading(false)')
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
      return { data, error: null }
    } catch (error) {
      return { data: null, error: error.message }
    }
  }

  const hasRole = (minRole) => {
    if (!profile) return false

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
