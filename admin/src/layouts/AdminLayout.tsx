import { NavLink, Outlet, useLocation } from 'react-router-dom'
import {
  BarChart3,
  Bell,
  Clock,
  CreditCard,
  LayoutList,
  LayoutDashboard,
  Mail,
  Menu,
  Mountain,
  Settings,
  Users,
  Webcam,
  X,
} from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Switch } from '@/components/ui/switch'
import { useAuth } from '@/core/auth/AuthContext'
import { ru } from '@/i18n/ru'
import { cn } from '@/lib/utils'

const navItems = [
  { to: '/', label: ru.dashboard, icon: LayoutDashboard },
  { to: '/users', label: ru.users, icon: Users },
  { to: '/bonus/config', label: ru.bonusConfig, icon: Settings },
  { to: '/bonus/transactions', label: ru.bonusTransactions, icon: CreditCard },
  { to: '/pos', label: ru.posIntegration, icon: BarChart3 },
  { to: '/content', label: ru.content, icon: Mountain },
  { to: '/services', label: 'Услуги и прайс', icon: LayoutList },
  { to: '/schedule-lifts', label: 'Расписание и подъёмники', icon: Clock },
  { to: '/weather-webcams', label: ru.weatherWebcams, icon: Webcam },
  { to: '/notifications', label: ru.notifications, icon: Bell },
  { to: '/messages', label: ru.messages, icon: Mail },
]

export function AdminLayout() {
  const { user, logout } = useAuth()
  const location = useLocation()
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const [dark, setDark] = useState(document.documentElement.classList.contains('dark'))

  const toggleDark = (checked: boolean) => {
    setDark(checked)
    document.documentElement.classList.toggle('dark', checked)
  }

  const breadcrumbs = location.pathname.split('/').filter(Boolean)

  return (
    <div className="flex min-h-screen bg-background">
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-40 w-64 border-r bg-card transition-transform lg:static lg:translate-x-0',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        <div className="flex h-16 items-center border-b px-4 font-semibold">{ru.appTitle}</div>
        <nav className="space-y-1 p-3">
          {navItems.map(({ to, label, icon: Icon }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={() => setSidebarOpen(false)}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 rounded-md px-3 py-2 text-sm transition-colors hover:bg-accent',
                  isActive && 'bg-accent font-medium',
                )
              }
            >
              <Icon className="h-4 w-4" />
              {label}
            </NavLink>
          ))}
        </nav>
      </aside>

      {sidebarOpen && (
        <button
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          aria-label="Close sidebar"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <div className="flex flex-1 flex-col">
        <header className="flex h-16 items-center justify-between border-b px-4 lg:px-6">
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setSidebarOpen(true)}>
              <Menu className="h-5 w-5" />
            </Button>
            <div className="text-sm text-muted-foreground">
              {breadcrumbs.length === 0 ? ru.dashboard : breadcrumbs.join(' / ')}
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 text-sm">
              <span className="hidden sm:inline">{ru.darkMode}</span>
              <Switch checked={dark} onCheckedChange={toggleDark} />
            </div>
            <span className="hidden text-sm sm:inline">{user?.email}</span>
            <Button variant="outline" size="sm" onClick={logout}>
              {ru.logout}
            </Button>
            <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setSidebarOpen(false)}>
              <X className="h-5 w-5" />
            </Button>
          </div>
        </header>
        <main className="flex-1 p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
