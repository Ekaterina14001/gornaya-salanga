import { useEffect, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type Headliner = {
  id: string
  title: string
  subtitle?: string
  imageUrl?: string
  linkUrl?: string
  sortOrder?: number
  active?: boolean
}

function HeadlinersSection() {
  const queryClient = useQueryClient()
  const [draft, setDraft] = useState({ title: '', subtitle: '', imageUrl: '', linkUrl: '', sortOrder: 0 })

  const query = useQuery({
    queryKey: ['admin-headliners'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Headliner[]>>('/api/admin/content/headliners')
      return unwrap(data)
    },
  })

  const create = useMutation({
    mutationFn: async () => {
      await api.post('/api/admin/content/headliners', draft)
    },
    onSuccess: () => {
      toast.success('Баннер добавлен')
      setDraft({ title: '', subtitle: '', imageUrl: '', linkUrl: '', sortOrder: 0 })
      void queryClient.invalidateQueries({ queryKey: ['admin-headliners'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  const update = useMutation({
    mutationFn: async (item: Headliner) => {
      await api.put(`/api/admin/content/headliners/${item.id}`, item)
    },
    onSuccess: () => {
      toast.success('Сохранено')
      void queryClient.invalidateQueries({ queryKey: ['admin-headliners'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  const remove = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/api/admin/content/headliners/${id}`)
    },
    onSuccess: () => {
      toast.success('Баннер скрыт')
      void queryClient.invalidateQueries({ queryKey: ['admin-headliners'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Баннеры на главной (headliners)</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-muted-foreground">
          Карусель на главном экране приложения. Внутренние ссылки: /bonus, /catalog.
        </p>
        {query.data?.map((item) => (
          <div key={item.id} className="grid gap-2 rounded border p-3 md:grid-cols-2">
            <Input
              value={item.title}
              onChange={(e) =>
                queryClient.setQueryData<Headliner[]>(['admin-headliners'], (old) =>
                  old?.map((h) => (h.id === item.id ? { ...h, title: e.target.value } : h)),
                )
              }
              placeholder="Заголовок"
            />
            <Input
              value={item.subtitle ?? ''}
              onChange={(e) =>
                queryClient.setQueryData<Headliner[]>(['admin-headliners'], (old) =>
                  old?.map((h) => (h.id === item.id ? { ...h, subtitle: e.target.value } : h)),
                )
              }
              placeholder="Подзаголовок"
            />
            <Input
              value={item.imageUrl ?? ''}
              onChange={(e) =>
                queryClient.setQueryData<Headliner[]>(['admin-headliners'], (old) =>
                  old?.map((h) => (h.id === item.id ? { ...h, imageUrl: e.target.value } : h)),
                )
              }
              placeholder="URL изображения"
            />
            <Input
              value={item.linkUrl ?? ''}
              onChange={(e) =>
                queryClient.setQueryData<Headliner[]>(['admin-headliners'], (old) =>
                  old?.map((h) => (h.id === item.id ? { ...h, linkUrl: e.target.value } : h)),
                )
              }
              placeholder="Ссылка"
            />
            <div className="flex gap-2 md:col-span-2">
              <Button size="sm" onClick={() => update.mutate(item)}>
                {ru.save}
              </Button>
              <Button size="sm" variant="outline" onClick={() => remove.mutate(item.id)}>
                Скрыть
              </Button>
            </div>
          </div>
        ))}
        <div className="grid gap-2 rounded border border-dashed p-3 md:grid-cols-2">
          <Input
            value={draft.title}
            onChange={(e) => setDraft((d) => ({ ...d, title: e.target.value }))}
            placeholder="Новый заголовок"
          />
          <Input
            value={draft.subtitle}
            onChange={(e) => setDraft((d) => ({ ...d, subtitle: e.target.value }))}
            placeholder="Подзаголовок"
          />
          <Input
            value={draft.imageUrl}
            onChange={(e) => setDraft((d) => ({ ...d, imageUrl: e.target.value }))}
            placeholder="URL изображения"
          />
          <Input
            value={draft.linkUrl}
            onChange={(e) => setDraft((d) => ({ ...d, linkUrl: e.target.value }))}
            placeholder="/bonus или https://..."
          />
          <Button className="md:col-span-2" onClick={() => create.mutate()} disabled={!draft.title || create.isPending}>
            Добавить баннер
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

type Rule = {
  id?: string
  ruleType: string
  title: string
  bodyMarkdown?: string
}

const ruleTypeLabels: Record<string, string> = {
  visiting: 'Правила посещения',
  bonus: 'Бонусная программа',
}

function RulesSection() {
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: ['content-rules'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Rule[]>>('/api/content/rules')
      return unwrap(data)
    },
  })

  const save = useMutation({
    mutationFn: async (rule: Rule) => {
      await api.put(`/api/admin/content/rules/${rule.ruleType}`, {
        title: rule.title,
        bodyMarkdown: rule.bodyMarkdown ?? '',
      })
    },
    onSuccess: () => {
      toast.success('Правила сохранены')
      void queryClient.invalidateQueries({ queryKey: ['content-rules'] })
    },
    onError: () => toast.error('Ошибка сохранения'),
  })

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Правила курорта</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {(query.data ?? []).map((rule) => (
          <div key={rule.ruleType} className="space-y-2 rounded border p-3">
            <p className="text-sm font-medium">{ruleTypeLabels[rule.ruleType] ?? rule.ruleType}</p>
            <Input
              value={rule.title}
              onChange={(e) =>
                queryClient.setQueryData<Rule[]>(['content-rules'], (old) =>
                  old?.map((r) => (r.ruleType === rule.ruleType ? { ...r, title: e.target.value } : r)),
                )
              }
              placeholder="Заголовок"
            />
            <textarea
              className="min-h-[120px] w-full rounded-md border border-input bg-background p-3 text-sm"
              value={rule.bodyMarkdown ?? ''}
              onChange={(e) =>
                queryClient.setQueryData<Rule[]>(['content-rules'], (old) =>
                  old?.map((r) =>
                    r.ruleType === rule.ruleType ? { ...r, bodyMarkdown: e.target.value } : r,
                  ),
                )
              }
            />
            <Button size="sm" onClick={() => save.mutate(rule)} disabled={save.isPending}>
              {ru.save}
            </Button>
          </div>
        ))}
        {query.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
      </CardContent>
    </Card>
  )
}

function SyncSalangaPricesButton() {
  const sync = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<{ imported: number; tables: number; fetchedAt: string }>>(
        '/api/admin/content/services/sync-salanga',
      )
      return unwrap(data)
    },
    onSuccess: (data) => {
      toast.success(`Импортировано ${data.imported} услуг из ${data.tables} таблиц`)
    },
    onError: () => toast.error('Не удалось импортировать прайс'),
  })

  return (
    <Button onClick={() => sync.mutate()} disabled={sync.isPending}>
      {sync.isPending ? 'Импорт…' : 'Импортировать прайс с сайта'}
    </Button>
  )
}

export function ContentPage() {
  const queryClient = useQueryClient()
  const aboutQuery = useQuery({
    queryKey: ['content-about'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<{ title?: string; bodyMarkdown?: string }>>('/api/content/about')
      return unwrap(data)
    },
  })

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')

  useEffect(() => {
    if (aboutQuery.data) {
      setTitle(aboutQuery.data.title ?? '')
      setBody(aboutQuery.data.bodyMarkdown ?? '')
    }
  }, [aboutQuery.data])

  const saveAbout = useMutation({
    mutationFn: async () => {
      await api.put('/api/admin/content/about', { title, bodyMarkdown: body, photos: [] })
    },
    onSuccess: () => {
      toast.success('Контент сохранён')
      void queryClient.invalidateQueries({ queryKey: ['content-about'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.content}</h1>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">О курорте</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>{ru.title}</Label>
            <Input value={title || aboutQuery.data?.title || ''} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div>
            <Label>Markdown</Label>
            <textarea
              className="min-h-[200px] w-full rounded-md border border-input bg-background p-3 text-sm"
              value={body || aboutQuery.data?.bodyMarkdown || ''}
              onChange={(e) => setBody(e.target.value)}
            />
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="rounded border p-4 prose prose-sm dark:prose-invert">
              <h4 className="mb-2 font-medium">Предпросмотр</h4>
              <p className="whitespace-pre-wrap">{body || aboutQuery.data?.bodyMarkdown || ''}</p>
            </div>
          </div>
          <Button onClick={() => saveAbout.mutate()} disabled={saveAbout.isPending}>
            {ru.save}
          </Button>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Прайс-лист с salanga.ru</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-sm text-muted-foreground">
            Импорт цен с{' '}
            <a
              href="https://www.salanga.ru/pricelist-ski/"
              target="_blank"
              rel="noreferrer"
              className="underline"
            >
              salanga.ru/pricelist-ski
            </a>
            : подъёмники, прокат, сноутюбинг, снегоходы.
          </p>
          <SyncSalangaPricesButton />
        </CardContent>
      </Card>
      <RulesSection />
      <HeadlinersSection />
    </div>
  )
}
