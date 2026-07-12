import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type WeeklyPoint = { date: string; count: number }

const dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб']

function formatChartDate(iso: string) {
  const d = new Date(`${iso}T12:00:00`)
  return `${dayNames[d.getDay()]} ${d.getDate()}.${String(d.getMonth() + 1).padStart(2, '0')}`
}

export function DashboardPage() {
  const health = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<{ status: string }>>('/health')
      return unwrap(data)
    },
  })

  const dashboard = useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Record<string, unknown>>>('/api/admin/dashboard')
      return unwrap(data)
    },
  })

  const stats = dashboard.data
  const chartData = useMemo(() => {
    const weekly = (stats?.weeklyRegistrations as WeeklyPoint[] | undefined) ?? []
    return weekly.map((point) => ({
      name: formatChartDate(point.date),
      users: Number(point.count) || 0,
    }))
  }, [stats?.weeklyRegistrations])

  const cards = [
    { label: 'Всего пользователей', value: stats?.usersTotal ?? stats?.userCount ?? '—' },
    { label: 'Активны сегодня', value: stats?.activeToday ?? '—' },
    { label: 'Бонусов в обороте', value: stats?.totalBonusesInCirculation ?? stats?.totalBalance ?? '—' },
    { label: 'Уведомлений сегодня', value: stats?.notificationsSentToday ?? '—' },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{ru.dashboard}</h1>
        <p className="text-muted-foreground">{ru.welcome}</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">API</CardTitle>
          </CardHeader>
          <CardContent>
            <p className={health.isSuccess ? 'text-green-600' : 'text-destructive'}>
              {health.isSuccess ? ru.healthOk : ru.healthFail}
            </p>
          </CardContent>
        </Card>
        {cards.map((card) => (
          <Card key={card.label}>
            <CardHeader>
              <CardTitle className="text-base">{card.label}</CardTitle>
            </CardHeader>
            <CardContent className="text-2xl font-bold">{String(card.value)}</CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Регистрации за 7 дней</CardTitle>
        </CardHeader>
        <CardContent className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="users" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  )
}
