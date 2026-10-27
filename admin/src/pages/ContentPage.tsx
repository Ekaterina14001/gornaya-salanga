import { useEffect, useState, type ReactNode } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { BannerImageUpload } from '@/components/BannerImageUpload'
import {
  defaultHomeBannerImage,
  nextSortOrderForNew,
  slotLabel,
} from '@/lib/homeBannerDefaults'
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

function activeHeadliners(items: Headliner[] | undefined): Headliner[] {
  return (items ?? [])
    .filter((h) => h.active !== false)
    .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))
}

function HeadlinerEditor({
  item,
  onPatch,
  onSave,
  onRemove,
  extraActions,
}: {
  item: Headliner
  onPatch: (patch: Partial<Headliner>) => void
  onSave: () => void
  onRemove: () => void
  extraActions?: ReactNode
}) {
  const sort = item.sortOrder ?? 0
  return (
    <div className="grid gap-2 rounded border p-3 md:grid-cols-2">
      <div className="flex flex-wrap items-center gap-2 md:col-span-2">
        <p className="text-sm font-medium">{slotLabel(sort)}</p>
        {extraActions}
      </div>
      <Input
        value={item.title ?? ''}
        onChange={(e) => onPatch({ title: e.target.value })}
        placeholder="Заголовок (необязательно)"
      />
      <Input
        value={item.linkUrl ?? ''}
        onChange={(e) => onPatch({ linkUrl: e.target.value })}
        placeholder="Ссылка по нажатию (необязательно)"
      />
      <BannerImageUpload
        value={item.imageUrl ?? ''}
        previewFallbackUrl={defaultHomeBannerImage(sort)}
        onChange={(url) => onPatch({ imageUrl: url })}
      />
      <div className="flex flex-wrap gap-2 md:col-span-2">
        <Button size="sm" onClick={onSave}>
          {ru.save}
        </Button>
        <Button size="sm" variant="outline" onClick={onRemove}>
          Удалить
        </Button>
      </div>
    </div>
  )
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

  useEffect(() => {
    if (query.data) {
      setDraft((d) => ({ ...d, sortOrder: nextSortOrderForNew(query.data) }))
    }
  }, [query.data])

  const create = useMutation({
    mutationFn: async () => {
      await api.post('/api/admin/content/headliners', draft)
    },
    onSuccess: async () => {
      toast.success('Баннер добавлен')
      await queryClient.invalidateQueries({ queryKey: ['admin-headliners'] })
      const items = queryClient.getQueryData<Headliner[]>(['admin-headliners'])
      setDraft({
        title: '',
        subtitle: '',
        imageUrl: '',
        linkUrl: '',
        sortOrder: nextSortOrderForNew(items),
      })
    },
    onError: () => toast.error('Ошибка'),
  })

  const update = useMutation({
    mutationFn: async (item: Headliner) => {
      await api.put(`/api/admin/content/headliners/${item.id}`, {
        title: item.title ?? '',
        subtitle: item.subtitle ?? '',
        imageUrl: item.imageUrl ?? '',
        linkUrl: item.linkUrl ?? '',
        sortOrder: item.sortOrder ?? 0,
        active: item.active,
      })
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
      toast.success('Баннер удалён')
      void queryClient.invalidateQueries({ queryKey: ['admin-headliners'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  const patchHeadliner = (id: string, patch: Partial<Headliner>) => {
    queryClient.setQueryData<Headliner[]>(['admin-headliners'], (old) =>
      old?.map((h) => (h.id === id ? { ...h, ...patch } : h)),
    )
  }

  const headlinerById = (id: string): Headliner | undefined =>
    queryClient.getQueryData<Headliner[]>(['admin-headliners'])?.find((h) => h.id === id)

  const moveCarousel = (id: string, direction: -1 | 1) => {
    const carousel = activeHeadliners(queryClient.getQueryData<Headliner[]>(['admin-headliners'])).filter(
      (h) => (h.sortOrder ?? 0) > 0,
    )
    const index = carousel.findIndex((h) => h.id === id)
    const target = index + direction
    if (index < 0 || target < 0 || target >= carousel.length) return
    const a = carousel[index]
    const b = carousel[target]
    const aOrder = a.sortOrder ?? 0
    const bOrder = b.sortOrder ?? 0
    patchHeadliner(a.id, { sortOrder: bOrder })
    patchHeadliner(b.id, { sortOrder: aOrder })
    const freshA = { ...a, sortOrder: bOrder }
    const freshB = { ...b, sortOrder: aOrder }
    update.mutate(freshA)
    update.mutate(freshB)
  }

  const active = activeHeadliners(query.data)
  const topBanners = active.filter((h) => (h.sortOrder ?? 0) === 0)
  const carouselBanners = active.filter((h) => (h.sortOrder ?? 0) > 0)

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Баннеры на главной</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-muted-foreground">
          Сначала настройте верхний баннер (слот 0) с кнопкой «Забронировать». Все остальные изображения
          попадают в нижнюю карусель (слоты 1, 2, 3…) и листаются свайпом в приложении. Текст на баннере
          необязателен. Ссылки: /bonus, /catalog или https://…
        </p>
        <div className="space-y-2">
          <h3 className="text-sm font-semibold">1. Верхний баннер</h3>
          {topBanners.length > 1 && (
            <p className="text-sm text-destructive">
              Несколько баннеров с порядком 0 — в приложении показывается только первый. Удалите лишние или
              сохраните один.
            </p>
          )}
          {topBanners.length === 0 && (
            <p className="text-sm text-muted-foreground">Верхний баннер не задан — добавьте ниже.</p>
          )}
          {topBanners.map((item) => (
            <HeadlinerEditor
              key={item.id}
              item={item}
              onPatch={(patch) => patchHeadliner(item.id, patch)}
              onSave={() => {
                const fresh = headlinerById(item.id)
                if (fresh) update.mutate(fresh)
              }}
              onRemove={() => remove.mutate(item.id)}
            />
          ))}
        </div>
        <div className="space-y-2">
          <h3 className="text-sm font-semibold">2. Нижняя карусель (свайп)</h3>
          {carouselBanners.length === 0 && (
            <p className="text-sm text-muted-foreground">
              Нет слайдов — нижний ряд в приложении скрыт, пока не добавите баннер с порядком 1 и выше.
            </p>
          )}
          {carouselBanners.map((item, index) => (
            <HeadlinerEditor
              key={item.id}
              item={item}
              onPatch={(patch) => patchHeadliner(item.id, patch)}
              onSave={() => {
                const fresh = headlinerById(item.id)
                if (fresh) update.mutate(fresh)
              }}
              onRemove={() => remove.mutate(item.id)}
              extraActions={
                <span className="flex gap-1">
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    disabled={index === 0}
                    onClick={() => moveCarousel(item.id, -1)}
                  >
                    ↑
                  </Button>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    disabled={index === carouselBanners.length - 1}
                    onClick={() => moveCarousel(item.id, 1)}
                  >
                    ↓
                  </Button>
                </span>
              }
            />
          ))}
        </div>
        <div className="grid gap-2 rounded border border-dashed p-3 md:grid-cols-2">
          <p className="text-sm font-medium md:col-span-2">
            Новый баннер · {slotLabel(draft.sortOrder)}
          </p>
          <Input
            value={draft.title}
            onChange={(e) => setDraft((d) => ({ ...d, title: e.target.value }))}
            placeholder="Заголовок (необязательно)"
          />
          <Input
            value={draft.linkUrl}
            onChange={(e) => setDraft((d) => ({ ...d, linkUrl: e.target.value }))}
            placeholder="/bonus или https://..."
          />
          <BannerImageUpload
            value={draft.imageUrl}
            previewFallbackUrl={defaultHomeBannerImage(draft.sortOrder)}
            onChange={(url) => setDraft((d) => ({ ...d, imageUrl: url }))}
          />
          <Button
            className="md:col-span-2"
            onClick={() => create.mutate()}
            disabled={create.isPending}
          >
            {draft.sortOrder === 0 ? 'Добавить верхний баннер' : 'Добавить слайд в карусель'}
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
