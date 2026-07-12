import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type Webcam = {
  id: string
  name: string
  streamUrl?: string
  locationDescription?: string
  sortOrder?: number
}

type Trail = {
  id: string
  name: string
  difficulty?: string
  status?: string
  comment?: string
}

const emptyWebcam = { name: '', streamUrl: '', locationDescription: '' }
const emptyTrail = { name: '', difficulty: 'blue', status: 'closed', comment: '' }

export function WeatherWebcamsPage() {
  const queryClient = useQueryClient()
  const [webcamDraft, setWebcamDraft] = useState(emptyWebcam)
  const [trailDraft, setTrailDraft] = useState(emptyTrail)

  const weatherQuery = useQuery({
    queryKey: ['weather'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Record<string, unknown>>>('/api/content/weather')
      return unwrap(data)
    },
  })

  const webcamsQuery = useQuery({
    queryKey: ['webcams'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Webcam[]>>('/api/content/webcams')
      return unwrap(data)
    },
  })

  const trailsQuery = useQuery({
    queryKey: ['trails'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Trail[]>>('/api/content/trails')
      return unwrap(data)
    },
  })

  const saveWebcam = useMutation({
    mutationFn: async (cam: Webcam) => {
      await api.put(`/api/admin/content/webcams/${cam.id}`, {
        name: cam.name,
        streamUrl: cam.streamUrl,
        locationDescription: cam.locationDescription,
        sortOrder: cam.sortOrder,
      })
    },
    onSuccess: () => {
      toast.success('Веб-камера сохранена')
      void queryClient.invalidateQueries({ queryKey: ['webcams'] })
    },
    onError: () => toast.error('Ошибка сохранения'),
  })

  const createWebcam = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<Webcam>>('/api/admin/content/webcams', {
        name: webcamDraft.name,
        streamUrl: webcamDraft.streamUrl,
        locationDescription: webcamDraft.locationDescription,
        sortOrder: 0,
      })
      return unwrap(data)
    },
    onSuccess: () => {
      toast.success('Веб-камера добавлена')
      setWebcamDraft(emptyWebcam)
      void queryClient.invalidateQueries({ queryKey: ['webcams'] })
    },
    onError: () => toast.error('Не удалось добавить камеру'),
  })

  const saveTrail = useMutation({
    mutationFn: async (trail: Trail) => {
      await api.put(`/api/admin/content/trails/${trail.id}`, {
        name: trail.name,
        difficulty: trail.difficulty,
        status: trail.status,
        comment: trail.comment,
      })
    },
    onSuccess: () => {
      toast.success('Трасса сохранена')
      void queryClient.invalidateQueries({ queryKey: ['trails'] })
    },
    onError: () => toast.error('Ошибка сохранения'),
  })

  const createTrail = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<Trail>>('/api/admin/content/trails', {
        name: trailDraft.name,
        difficulty: trailDraft.difficulty,
        status: trailDraft.status,
        comment: trailDraft.comment,
        sortOrder: 0,
      })
      return unwrap(data)
    },
    onSuccess: () => {
      toast.success('Трасса добавлена')
      setTrailDraft(emptyTrail)
      void queryClient.invalidateQueries({ queryKey: ['trails'] })
    },
    onError: () => toast.error('Не удалось добавить трассу'),
  })

  const updateWebcamField = (id: string, field: keyof Webcam, value: string | number) => {
    queryClient.setQueryData<Webcam[]>(['webcams'], (old) =>
      old?.map((c) => (c.id === id ? { ...c, [field]: value } : c)),
    )
  }

  const updateTrailField = (id: string, field: keyof Trail, value: string) => {
    queryClient.setQueryData<Trail[]>(['trails'], (old) =>
      old?.map((t) => (t.id === id ? { ...t, [field]: value } : t)),
    )
  }

  const w = weatherQuery.data
  const forecast = Array.isArray(w?.forecast) ? w.forecast : []

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.weatherWebcams}</h1>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Погода (salanga.ru)</CardTitle>
        </CardHeader>
        <CardContent className="text-sm space-y-1">
          {w ? (
            <>
              <p>
                <strong>{String(w.description ?? '—')}</strong>, днём {String(w.tempDay ?? w.temperature ?? '—')}°C
                {w.tempNight != null ? `, ночью ${String(w.tempNight)}°C` : ''}
              </p>
              {forecast.length > 0 && (
                <div className="mt-3 space-y-1 text-muted-foreground">
                  {forecast.slice(0, 7).map((day, index) => {
                    const item = day as Record<string, unknown>
                    return (
                      <p key={index}>
                        {String(item.label ?? `День ${index + 1}`)}: {String(item.tempDay ?? '—')}°C / ночью{' '}
                        {String(item.tempNight ?? '—')}°C
                      </p>
                    )
                  })}
                </div>
              )}
              <p className="text-muted-foreground">Источник: {String(w.source ?? '—')}</p>
            </>
          ) : (
            <p className="text-muted-foreground">Загрузка...</p>
          )}
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Веб-камеры</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {(webcamsQuery.data ?? []).map((cam) => (
            <div key={cam.id} className="grid gap-2 rounded border p-3 md:grid-cols-2">
              <div>
                <Label>Название</Label>
                <Input value={cam.name} onChange={(e) => updateWebcamField(cam.id, 'name', e.target.value)} />
              </div>
              <div>
                <Label>Описание</Label>
                <Input
                  value={cam.locationDescription ?? ''}
                  onChange={(e) => updateWebcamField(cam.id, 'locationDescription', e.target.value)}
                />
              </div>
              <div className="md:col-span-2">
                <Label>URL потока (rtsp.ru embed)</Label>
                <Input
                  value={cam.streamUrl ?? ''}
                  onChange={(e) => updateWebcamField(cam.id, 'streamUrl', e.target.value)}
                />
              </div>
              <Button size="sm" className="md:col-span-2" onClick={() => saveWebcam.mutate(cam)}>
                Сохранить
              </Button>
            </div>
          ))}
          <div className="grid gap-2 rounded border border-dashed p-3 md:grid-cols-2">
            <div>
              <Label>Новая камера</Label>
              <Input
                value={webcamDraft.name}
                onChange={(e) => setWebcamDraft((d) => ({ ...d, name: e.target.value }))}
                placeholder="Название"
              />
            </div>
            <div>
              <Label>Описание</Label>
              <Input
                value={webcamDraft.locationDescription}
                onChange={(e) => setWebcamDraft((d) => ({ ...d, locationDescription: e.target.value }))}
              />
            </div>
            <div className="md:col-span-2">
              <Label>URL потока</Label>
              <Input
                value={webcamDraft.streamUrl}
                onChange={(e) => setWebcamDraft((d) => ({ ...d, streamUrl: e.target.value }))}
                placeholder="https://rtsp.ru/embed/..."
              />
            </div>
            <Button
              size="sm"
              className="md:col-span-2 w-fit"
              disabled={!webcamDraft.name || !webcamDraft.streamUrl || createWebcam.isPending}
              onClick={() => createWebcam.mutate()}
            >
              Добавить камеру
            </Button>
          </div>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Трассы</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {(trailsQuery.data ?? []).map((trail) => (
            <div key={trail.id} className="grid gap-2 rounded border p-3 md:grid-cols-2">
              <div>
                <Label>Название</Label>
                <Input value={trail.name} onChange={(e) => updateTrailField(trail.id, 'name', e.target.value)} />
              </div>
              <div>
                <Label>Сложность (blue/red/black)</Label>
                <Input
                  value={trail.difficulty ?? ''}
                  onChange={(e) => updateTrailField(trail.id, 'difficulty', e.target.value)}
                />
              </div>
              <div>
                <Label>Статус (open/closed)</Label>
                <Input
                  value={trail.status ?? ''}
                  onChange={(e) => updateTrailField(trail.id, 'status', e.target.value)}
                />
              </div>
              <div>
                <Label>Комментарий</Label>
                <Input
                  value={trail.comment ?? ''}
                  onChange={(e) => updateTrailField(trail.id, 'comment', e.target.value)}
                />
              </div>
              <Button size="sm" className="md:col-span-2" onClick={() => saveTrail.mutate(trail)}>
                Сохранить
              </Button>
            </div>
          ))}
          <div className="grid gap-2 rounded border border-dashed p-3 md:grid-cols-2">
            <div>
              <Label>Новая трасса</Label>
              <Input
                value={trailDraft.name}
                onChange={(e) => setTrailDraft((d) => ({ ...d, name: e.target.value }))}
                placeholder="Название"
              />
            </div>
            <div>
              <Label>Сложность</Label>
              <Input
                value={trailDraft.difficulty}
                onChange={(e) => setTrailDraft((d) => ({ ...d, difficulty: e.target.value }))}
              />
            </div>
            <div>
              <Label>Статус</Label>
              <Input
                value={trailDraft.status}
                onChange={(e) => setTrailDraft((d) => ({ ...d, status: e.target.value }))}
              />
            </div>
            <div>
              <Label>Комментарий</Label>
              <Input
                value={trailDraft.comment}
                onChange={(e) => setTrailDraft((d) => ({ ...d, comment: e.target.value }))}
              />
            </div>
            <Button
              size="sm"
              className="md:col-span-2 w-fit"
              disabled={!trailDraft.name || createTrail.isPending}
              onClick={() => createTrail.mutate()}
            >
              Добавить трассу
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
