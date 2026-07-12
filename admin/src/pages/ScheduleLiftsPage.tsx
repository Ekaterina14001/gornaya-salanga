import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, apiErrorMessage, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type ScheduleItem = {
  id: string
  serviceName: string
  dayOfWeek: number
  openTime?: string
  closeTime?: string
  closed?: boolean
}

type Lift = {
  id: string
  name: string
  description?: string
  pricesText?: string
  status?: string
  openTime?: string | { Microseconds: number; Valid: boolean }
  closeTime?: string | { Microseconds: number; Valid: boolean }
  comment?: string
  source?: string
  externalKey?: string
  active?: boolean
}

const serviceLabels: Record<string, string> = {
  reception: 'Ресепшн',
  restaurant: 'Ресторан',
  ski_lift: 'Подъёмники',
  rental: 'Прокат',
}

const dayLabels = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб']

function formatTime(value?: unknown) {
  if (!value) return ''
  if (typeof value === 'string') return value.slice(0, 5)
  if (typeof value === 'object' && value !== null && 'Microseconds' in value) {
    const ms = Number((value as { Microseconds: number }).Microseconds)
    if (!Number.isFinite(ms)) return ''
    const totalSec = Math.floor(ms / 1_000_000)
    const h = Math.floor(totalSec / 3600)
    const m = Math.floor((totalSec % 3600) / 60)
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
  }
  return String(value).slice(0, 5)
}

export function ScheduleLiftsPage() {
  const queryClient = useQueryClient()

  const scheduleQuery = useQuery({
    queryKey: ['admin-schedule'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<ScheduleItem[]>>('/api/admin/content/schedule')
      return unwrap(data)
    },
  })

  const liftsQuery = useQuery({
    queryKey: ['admin-lifts'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Lift[]>>('/api/admin/content/lifts')
      return unwrap(data)
    },
  })

  const saveSchedule = useMutation({
    mutationFn: async (item: ScheduleItem) => {
      await api.put(`/api/admin/content/schedule/${item.id}`, {
        openTime: item.openTime || null,
        closeTime: item.closeTime || null,
        closed: item.closed ?? false,
      })
    },
    onSuccess: () => {
      toast.success('Расписание сохранено')
      void queryClient.invalidateQueries({ queryKey: ['admin-schedule'] })
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const syncLifts = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<{ imported: number; sourceUrl: string }>>(
        '/api/admin/content/lifts/sync-salanga',
      )
      return unwrap(data)
    },
    onSuccess: (data) => {
      toast.success(`Импортировано ${data.imported} подъёмников с salanga.ru`)
      void queryClient.invalidateQueries({ queryKey: ['admin-lifts'] })
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const saveLift = useMutation({
    mutationFn: async (lift: Lift) => {
      await api.put(`/api/admin/content/lifts/${lift.id}`, {
        name: lift.name,
        description: lift.description,
        pricesText: lift.pricesText,
        status: lift.status,
        openTime: formatTime(lift.openTime) || null,
        closeTime: formatTime(lift.closeTime) || null,
        comment: lift.comment,
        active: lift.active ?? true,
      })
    },
    onSuccess: () => {
      toast.success('Подъёмник сохранён')
      void queryClient.invalidateQueries({ queryKey: ['admin-lifts'] })
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const updateScheduleField = (id: string, patch: Partial<ScheduleItem>) => {
    queryClient.setQueryData<ScheduleItem[]>(['admin-schedule'], (old) =>
      old?.map((row) => (row.id === id ? { ...row, ...patch } : row)),
    )
  }

  const updateLiftField = (id: string, patch: Partial<Lift>) => {
    queryClient.setQueryData<Lift[]>(['admin-lifts'], (old) =>
      old?.map((row) => (row.id === id ? { ...row, ...patch } : row)),
    )
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Расписание и подъёмники</h1>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Расписание работы</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Отображается в приложении в каталоге → вкладка «Расписание».
          </p>
          {scheduleQuery.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
          {(scheduleQuery.data ?? []).map((item) => (
            <div key={item.id} className="grid gap-3 rounded border p-3 md:grid-cols-4">
              <div>
                <p className="font-medium">{serviceLabels[item.serviceName] ?? item.serviceName}</p>
                <p className="text-sm text-muted-foreground">{dayLabels[item.dayOfWeek] ?? item.dayOfWeek}</p>
              </div>
              <div>
                <Label>Открытие</Label>
                <Input
                  type="time"
                  value={formatTime(item.openTime)}
                  onChange={(e) => updateScheduleField(item.id, { openTime: e.target.value })}
                />
              </div>
              <div>
                <Label>Закрытие</Label>
                <Input
                  type="time"
                  value={formatTime(item.closeTime)}
                  onChange={(e) => updateScheduleField(item.id, { closeTime: e.target.value })}
                />
              </div>
              <div className="flex flex-col justify-end gap-2">
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={item.closed ?? false}
                    onChange={(e) => updateScheduleField(item.id, { closed: e.target.checked })}
                  />
                  Закрыто
                </label>
                <Button size="sm" onClick={() => saveSchedule.mutate(item)} disabled={saveSchedule.isPending}>
                  {ru.save}
                </Button>
              </div>
            </div>
          ))}
          {!scheduleQuery.isLoading && !scheduleQuery.data?.length && (
            <p className="text-muted-foreground">Нет записей расписания</p>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-4">
          <CardTitle className="text-base">Подъёмники</CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() => syncLifts.mutate()}
            disabled={syncLifts.isPending}
          >
            {syncLifts.isPending ? 'Импорт...' : 'Импорт с salanga.ru'}
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Данные с{' '}
            <a
              href="https://www.salanga.ru/services/Poemniki/"
              target="_blank"
              rel="noreferrer"
              className="underline"
            >
              salanga.ru/services/Poemniki
            </a>
            : время работы, описание и цены. После импорта можно редактировать вручную.
          </p>
          {liftsQuery.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
          {(liftsQuery.data ?? []).map((lift) => (
            <div key={lift.id} className="grid gap-3 rounded border p-3 md:grid-cols-2">
              <div className="md:col-span-2 flex flex-wrap items-center gap-2 text-sm text-muted-foreground">
                {lift.source === 'salanga' && (
                  <span className="rounded bg-muted px-2 py-0.5">salanga.ru</span>
                )}
                {lift.active === false && (
                  <span className="rounded bg-red-100 px-2 py-0.5 text-red-800">скрыт</span>
                )}
              </div>
              <div>
                <Label>Название</Label>
                <Input
                  value={lift.name}
                  onChange={(e) => updateLiftField(lift.id, { name: e.target.value })}
                />
              </div>
              <div>
                <Label>Статус</Label>
                <select
                  className="mt-1 flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
                  value={lift.status ?? 'closed'}
                  onChange={(e) => updateLiftField(lift.id, { status: e.target.value })}
                >
                  <option value="open">open — работает</option>
                  <option value="closed">closed — закрыт</option>
                </select>
              </div>
              <div>
                <Label>Открытие</Label>
                <Input
                  type="time"
                  value={formatTime(lift.openTime)}
                  onChange={(e) => updateLiftField(lift.id, { openTime: e.target.value })}
                />
              </div>
              <div>
                <Label>Закрытие</Label>
                <Input
                  type="time"
                  value={formatTime(lift.closeTime)}
                  onChange={(e) => updateLiftField(lift.id, { closeTime: e.target.value })}
                />
              </div>
              <div className="md:col-span-2">
                <Label>Описание</Label>
                <textarea
                  className="mt-1 flex min-h-[72px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  value={lift.description ?? ''}
                  onChange={(e) => updateLiftField(lift.id, { description: e.target.value })}
                />
              </div>
              <div className="md:col-span-2">
                <Label>Цены (текст)</Label>
                <textarea
                  className="mt-1 flex min-h-[120px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm font-mono"
                  value={lift.pricesText ?? ''}
                  onChange={(e) => updateLiftField(lift.id, { pricesText: e.target.value })}
                />
              </div>
              <div className="md:col-span-2">
                <Label>Комментарий</Label>
                <Input
                  value={lift.comment ?? ''}
                  onChange={(e) => updateLiftField(lift.id, { comment: e.target.value })}
                  placeholder="Например: технический перерыв"
                />
              </div>
              <div className="md:col-span-2">
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={lift.active ?? true}
                    onChange={(e) => updateLiftField(lift.id, { active: e.target.checked })}
                  />
                  Показывать в приложении
                </label>
              </div>
              <Button size="sm" className="md:col-span-2 w-fit" onClick={() => saveLift.mutate(lift)} disabled={saveLift.isPending}>
                {ru.save}
              </Button>
            </div>
          ))}
          {!liftsQuery.isLoading && !liftsQuery.data?.length && (
            <p className="text-muted-foreground">
              Нет подъёмников. Нажмите «Импорт с salanga.ru» для загрузки данных с сайта.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
