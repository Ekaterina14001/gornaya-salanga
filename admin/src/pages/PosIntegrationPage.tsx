import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'
import { useState } from 'react'

export function PosIntegrationPage() {
  const [system, setSystem] = useState('Shelter')
  const queryClient = useQueryClient()

  const keysQuery = useQuery({
    queryKey: ['pos-keys'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Array<Record<string, unknown>>>>('/api/admin/pos/keys')
      return unwrap(data)
    },
  })

  const logsQuery = useQuery({
    queryKey: ['pos-logs'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<{ items: Array<Record<string, unknown>>; total: number }>>('/api/admin/pos/logs')
      return unwrap(data)
    },
  })

  const createKey = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<Record<string, unknown>>>('/api/admin/pos/keys', { system })
      return unwrap(data)
    },
    onSuccess: (data) => {
      toast.success(`Ключ создан: ${String(data.prefix ?? '')}…`)
      void queryClient.invalidateQueries({ queryKey: ['pos-keys'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  const revokeKey = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/api/admin/pos/keys/${id}`)
    },
    onSuccess: () => {
      toast.success('Ключ отозван')
      void queryClient.invalidateQueries({ queryKey: ['pos-keys'] })
    },
  })

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.posIntegration}</h1>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">API-ключи POS</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Input value={system} onChange={(e) => setSystem(e.target.value)} placeholder="Shelter / Bars / RKeeper" />
            <Button onClick={() => createKey.mutate()} disabled={createKey.isPending}>
              Создать ключ
            </Button>
          </div>
          <ul className="space-y-2 text-sm">
            {(keysQuery.data ?? []).map((key) => (
              <li key={String(key.id)} className="flex items-center justify-between rounded border p-2">
                <span>
                  {String(key.system)} — {String(key.prefix)}…
                </span>
                <Button size="sm" variant="destructive" onClick={() => revokeKey.mutate(String(key.id))}>
                  Отозвать
                </Button>
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Журнал запросов</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-1 text-sm">
            {(logsQuery.data?.items ?? []).map((log, i) => (
              <li key={i} className="rounded border p-2">
                {JSON.stringify(log)}
              </li>
            ))}
            {!logsQuery.data?.items?.length && <p className="text-muted-foreground">{ru.noData}</p>}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}
