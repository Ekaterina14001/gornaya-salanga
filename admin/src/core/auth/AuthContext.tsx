import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { api, apiErrorMessage, unwrap, type ApiEnvelope } from '../api/axios'
import { REFRESH_KEY, TOKEN_KEY } from '../config'

interface AuthUser {
  id: string
  email: string
  role: string
  firstName: string
  lastName: string
}

interface AuthContextValue {
  user: AuthUser | null
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const loadProfile = useCallback(async () => {
    const token = localStorage.getItem(TOKEN_KEY)
    if (!token) {
      setUser(null)
      setIsLoading(false)
      return
    }
    try {
      const { data } = await api.get<ApiEnvelope<AuthUser>>('/api/users/me')
      const profile = unwrap(data)
      if (profile.role !== 'admin') {
        throw new Error('admin access required')
      }
      setUser(profile)
    } catch {
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(REFRESH_KEY)
      setUser(null)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadProfile()
  }, [loadProfile])

  const login = useCallback(async (email: string, password: string) => {
    const { data } = await api.post<
      ApiEnvelope<{
        accessToken: string
        refreshToken: string
        user: AuthUser
      }>
    >('/api/auth/login', { email, password })
    const payload = unwrap(data)
    if (payload.user.role !== 'admin') {
      throw new Error('Доступ только для администраторов')
    }
    localStorage.setItem(TOKEN_KEY, payload.accessToken)
    localStorage.setItem(REFRESH_KEY, payload.refreshToken)
    setUser(payload.user)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(REFRESH_KEY)
    setUser(null)
  }, [])

  const value = useMemo(
    () => ({ user, isLoading, login, logout }),
    [user, isLoading, login, logout],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}

export { apiErrorMessage }
