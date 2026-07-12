import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { api, apiErrorMessage, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type Message = {
  id: string
  subject: string
  body: string
  status: string
  adminReply?: string
  createdAt?: string
  repliedAt?: string
  userEmail?: string
  userName?: string
}

function formatDate(value?: string) {
  if (!value) return '—'
  const d = new Date(value)
  if (Number.isNaN(d.getTime())) return value
  return d.toLocaleString('ru-RU')
}

export function MessagesPage() {
  const [replyText, setReplyText] = useState<Record<string, string>>({})
  const [statusFilter, setStatusFilter] = useState<'all' | 'unread' | 'replied'>('all')
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: ['admin-messages', statusFilter],
    queryFn: async () => {
      const params = statusFilter === 'all' ? {} : { status: statusFilter }
      const { data } = await api.get<ApiEnvelope<Message[]>>('/api/admin/messages', { params })
      return unwrap(data)
    },
  })

  const reply = useMutation({
    mutationFn: async ({ id, text }: { id: string; text: string }) => {
      await api.post(`/api/admin/messages/${id}/reply`, { reply: text })
    },
    onSuccess: () => {
      toast.success('Ответ отправлен — гость получит уведомление в приложении')
      setReplyText({})
      void queryClient.invalidateQueries({ queryKey: ['admin-messages'] })
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const unreadCount = (query.data ?? []).filter((m) => m.status === 'unread').length

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">{ru.messages}</h1>
        {unreadCount > 0 && statusFilter === 'all' && (
          <span className="rounded-full bg-primary/10 px-3 py-1 text-sm text-primary">
            Новых: {unreadCount}
          </span>
        )}
      </div>

      <div className="flex flex-wrap gap-2">
        {(
          [
            ['all', 'Все'],
            ['unread', 'Новые'],
            ['replied', 'С ответом'],
          ] as const
        ).map(([value, label]) => (
          <Button
            key={value}
            size="sm"
            variant={statusFilter === value ? 'default' : 'outline'}
            onClick={() => setStatusFilter(value)}
          >
            {label}
          </Button>
        ))}
      </div>

      <div className="space-y-4">
        {query.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
        {query.isError && <p className="text-destructive">Не удалось загрузить сообщения</p>}
        {(query.data ?? []).map((msg) => (
          <Card key={msg.id} className={msg.status === 'unread' ? 'border-primary/40' : undefined}>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">{msg.subject}</CardTitle>
              <p className="text-sm text-muted-foreground">
                {msg.userName || 'Гость'}
                {msg.userEmail ? ` · ${msg.userEmail}` : ''} · {formatDate(msg.createdAt)}
              </p>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm whitespace-pre-wrap">{msg.body}</p>
              <p className="text-xs text-muted-foreground">
                {ru.status}: {msg.status === 'unread' ? 'новое' : msg.status === 'replied' ? 'отвечено' : msg.status}
              </p>
              {msg.adminReply && (
                <div className="rounded bg-muted p-3 text-sm">
                  <p className="font-medium mb-1">Ваш ответ {msg.repliedAt ? `· ${formatDate(msg.repliedAt)}` : ''}</p>
                  <p className="whitespace-pre-wrap">{msg.adminReply}</p>
                </div>
              )}
              {msg.status !== 'replied' && (
                <div className="flex flex-col gap-2 sm:flex-row">
                  <Input
                    placeholder="Текст ответа"
                    value={replyText[msg.id] ?? ''}
                    onChange={(e) => setReplyText((s) => ({ ...s, [msg.id]: e.target.value }))}
                  />
                  <Button
                    className="shrink-0"
                    onClick={() => reply.mutate({ id: msg.id, text: replyText[msg.id] ?? '' })}
                    disabled={!replyText[msg.id]?.trim() || reply.isPending}
                  >
                    {ru.reply}
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
        {!query.isLoading && !query.data?.length && (
          <p className="text-muted-foreground">{ru.noData}</p>
        )}
      </div>
    </div>
  )
}
