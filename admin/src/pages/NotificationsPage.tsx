import { useMutation, useQuery } from '@tanstack/react-query'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

const schema = z.object({
  title: z.string().min(3),
  body: z.string().min(3),
  audience: z.string().min(1),
  linkUrl: z.string().optional(),
})

type FormData = z.infer<typeof schema>

export function NotificationsPage() {
  const pushStatus = useQuery({
    queryKey: ['push-status'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<{ pushEnabled: boolean }>>('/api/admin/notifications/push-status')
      return unwrap(data)
    },
  })

  const { register, handleSubmit, reset } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { audience: 'all' },
  })

  const broadcast = useMutation({
    mutationFn: async (data: FormData) => {
      const { data: res } = await api.post<ApiEnvelope<{ sent: number }>>('/api/admin/notifications/broadcast', {
        title: data.title,
        body: data.body,
        audience: data.audience,
        type: 'news',
        data: data.linkUrl ? { linkUrl: data.linkUrl } : undefined,
      })
      return unwrap(res)
    },
    onSuccess: (data) => {
      toast.success(`Рассылка отправлена (${data.sent} получателей)`)
      reset()
    },
    onError: () => toast.error('Ошибка рассылки'),
  })

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">{ru.notifications}</h1>
        <span
          className={`rounded-full px-3 py-1 text-sm ${
            pushStatus.data?.pushEnabled
              ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
              : 'bg-muted text-muted-foreground'
          }`}
        >
          Push (FCM): {pushStatus.data?.pushEnabled ? 'включён' : 'выключен — задайте FCM_CREDENTIALS_FILE'}
        </span>
      </div>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">{ru.broadcast}</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Сообщение сохраняется в приложении и отправляется push-уведомлением на зарегистрированные устройства.
          </p>
          <form onSubmit={handleSubmit((d) => broadcast.mutate(d))} className="max-w-lg space-y-4">
            <div>
              <Label>{ru.title}</Label>
              <Input {...register('title')} />
            </div>
            <div>
              <Label>{ru.body}</Label>
              <Input {...register('body')} />
            </div>
            <div>
              <Label>{ru.audience}</Label>
              <Input {...register('audience')} placeholder="all / guests / admins" />
            </div>
            <div>
              <Label>Ссылка в приложении (необязательно)</Label>
              <Input {...register('linkUrl')} placeholder="/bonus, /catalog, /weather" />
            </div>
            <Button type="submit" disabled={broadcast.isPending}>
              {ru.send}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
