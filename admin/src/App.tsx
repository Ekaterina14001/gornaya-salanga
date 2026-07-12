import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sonner'
import { AdminRoute } from '@/components/AdminRoute'
import { AuthProvider, useAuth } from '@/core/auth/AuthContext'
import { AdminLayout } from '@/layouts/AdminLayout'
import { BonusConfigPage } from '@/pages/BonusConfigPage'
import { BonusTransactionsPage } from '@/pages/BonusTransactionsPage'
import { ContentPage } from '@/pages/ContentPage'
import { DashboardPage } from '@/pages/DashboardPage'
import { LoginPage } from '@/pages/LoginPage'
import { MessagesPage } from '@/pages/MessagesPage'
import { NotificationsPage } from '@/pages/NotificationsPage'
import { PosIntegrationPage } from '@/pages/PosIntegrationPage'
import { ScheduleLiftsPage } from '@/pages/ScheduleLiftsPage'
import { ServicesPage } from '@/pages/ServicesPage'
import { UsersPage } from '@/pages/UsersPage'
import { WeatherWebcamsPage } from '@/pages/WeatherWebcamsPage'

const queryClient = new QueryClient()

function LoginRedirect({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth()
  if (isLoading) return null
  if (user) return <Navigate to="/" replace />
  return <>{children}</>
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route
              path="/login"
              element={
                <LoginRedirect>
                  <LoginPage />
                </LoginRedirect>
              }
            />
            <Route element={<AdminRoute />}>
              <Route element={<AdminLayout />}>
                <Route index element={<DashboardPage />} />
                <Route path="users" element={<UsersPage />} />
                <Route path="bonus/config" element={<BonusConfigPage />} />
                <Route path="bonus/transactions" element={<BonusTransactionsPage />} />
                <Route path="pos" element={<PosIntegrationPage />} />
                <Route path="content" element={<ContentPage />} />
                <Route path="services" element={<ServicesPage />} />
                <Route path="schedule-lifts" element={<ScheduleLiftsPage />} />
                <Route path="weather-webcams" element={<WeatherWebcamsPage />} />
                <Route path="notifications" element={<NotificationsPage />} />
                <Route path="messages" element={<MessagesPage />} />
              </Route>
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
        <Toaster richColors position="top-right" />
      </AuthProvider>
    </QueryClientProvider>
  )
}
