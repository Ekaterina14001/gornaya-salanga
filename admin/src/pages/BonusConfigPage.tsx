import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

const schema = z.object({
  earnPercentageGlobal: z.coerce.number().min(0).max(100),
  earnPercentageShelter: z.coerce.number().min(0).max(100),
  earnPercentageBars: z.coerce.number().min(0).max(100),
  earnPercentageRKeeper: z.coerce.number().min(0).max(100),
  maxSpendPercentage: z.coerce.number().min(0).max(100),
  minReceiptAmount: z.coerce.number().min(0),
  bonusExpiryDays: z.coerce.number().min(1),
  qrTtlSeconds: z.coerce.number().min(30),
})

type FormData = z.infer<typeof schema>

export function BonusConfigPage() {
  const queryClient = useQueryClient()
  const configQuery = useQuery({
    queryKey: ['bonus-config'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<FormData>>('/api/admin/bonus/config')
      return unwrap(data)
    },
  })

  const auditQuery = useQuery({
    queryKey: ['bonus-config-audit'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Array<Record<string, unknown>>>>('/api/admin/bonus/config/audit')
      return unwrap(data)
    },
  })

  const { register, handleSubmit, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    values: configQuery.data,
  })

  const saveMutation = useMutation({
    mutationFn: async (data: FormData) => {
      await api.put('/api/admin/bonus/config', data)
    },
    onSuccess: () => {
      toast.success('Конфигурация сохранена')
      void queryClient.invalidateQueries({ queryKey: ['bonus-config'] })
      void queryClient.invalidateQueries({ queryKey: ['bonus-config-audit'] })
    },
    onError: () => toast.error('Ошибка сохранения'),
  })

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.bonusConfig}</h1>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Параметры начисления</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit((d) => saveMutation.mutate(d))} className="grid max-w-lg gap-4">
            <div>
              <Label>% начисления (глобальный)</Label>
              <Input type="number" step="0.1" {...register('earnPercentageGlobal')} />
            </div>
            <div>
              <Label>% начисления (Shelter)</Label>
              <Input type="number" step="0.1" {...register('earnPercentageShelter')} />
            </div>
            <div>
              <Label>% начисления (Bars)</Label>
              <Input type="number" step="0.1" {...register('earnPercentageBars')} />
            </div>
            <div>
              <Label>% начисления (RKeeper)</Label>
              <Input type="number" step="0.1" {...register('earnPercentageRKeeper')} />
            </div>
            <div>
              <Label>Макс. % оплаты бонусами</Label>
              <Input type="number" step="0.1" {...register('maxSpendPercentage')} />
            </div>
            <div>
              <Label>Мин. сумма чека</Label>
              <Input type="number" {...register('minReceiptAmount')} />
            </div>
            <div>
              <Label>Срок жизни бонусов (дней)</Label>
              <Input type="number" {...register('bonusExpiryDays')} />
            </div>
            <div>
              <Label>QR TTL (сек)</Label>
              <Input type="number" {...register('qrTtlSeconds')} />
            </div>
            <Button type="submit" disabled={saveMutation.isPending}>
              {ru.save}
            </Button>
            <Button type="button" variant="outline" onClick={() => reset()}>
              Сбросить
            </Button>
          </form>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Журнал изменений</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2 text-sm">
            {(auditQuery.data ?? []).map((entry, i) => (
              <li key={i} className="rounded border p-2">
                {JSON.stringify(entry)}
              </li>
            ))}
            {!auditQuery.data?.length && <p className="text-muted-foreground">{ru.noData}</p>}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}
