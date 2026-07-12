import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '@/core/auth/AuthContext'
import { ru } from '@/i18n/ru'

export function AdminRoute() {
  const { user, isLoading } = useAuth()

  if (isLoading) {
    return <div className="flex min-h-screen items-center justify-center">{ru.loading}</div>
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  return <Outlet />
}
