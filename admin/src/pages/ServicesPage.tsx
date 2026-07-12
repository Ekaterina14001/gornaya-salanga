import { useEffect, useMemo, useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Eye, EyeOff, Pencil, Plus, RefreshCw, Trash2, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, apiErrorMessage, unwrap, type ApiEnvelope } from '@/core/api/axios'

type Service = {
  id: string
  name: string
  description?: string
  price: number
  category?: string
  sortOrder?: number
  active?: boolean
  source?: string
  externalKey?: string
}

const categoryLabels: Record<string, string> = {
  lift: 'Подъёмники',
  rental: 'Прокат',
  tubing: 'Сноутюбинг',
  snowmobile: 'Снегоходы',
  other: 'Прочее',
}

const categoryOptions = Object.entries(categoryLabels)

type ServiceForm = {
  name: string
  description: string
  price: string
  category: string
  sortOrder: string
  active: boolean
}

function emptyForm(): ServiceForm {
  return { name: '', description: '', price: '', category: 'other', sortOrder: '0', active: true }
}

function serviceToForm(service: Service): ServiceForm {
  return {
    name: service.name,
    description: service.description ?? '',
    price: String(service.price ?? 0),
    category: service.category ?? 'other',
    sortOrder: String(service.sortOrder ?? 0),
    active: service.active !== false,
  }
}

function ServiceModal({
  title,
  initial,
  onClose,
  onSave,
  saving,
}: {
  title: string
  initial: ServiceForm
  onClose: () => void
  onSave: (form: ServiceForm) => void
  saving: boolean
}) {
  const [form, setForm] = useState(initial)
  const dialogRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    dialogRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const price = Number(form.price.replace(',', '.'))
  const canSave = form.name.trim().length > 0 && Number.isFinite(price) && price >= 0

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-black/50 p-4 sm:items-center"
      onClick={onClose}
      role="presentation"
    >
      <div
        ref={dialogRef}
        tabIndex={-1}
        role="dialog"
        aria-modal="true"
        className="relative w-full max-w-lg rounded-lg border bg-background shadow-xl outline-none"
        onClick={(e) => e.stopPropagation()}
      >
        <Card className="border-0 shadow-none">
          <CardHeader className="flex flex-row items-start justify-between gap-4 border-b bg-muted/40">
            <CardTitle className="text-lg">{title}</CardTitle>
            <Button type="button" variant="outline" size="icon" onClick={onClose} aria-label="Закрыть">
              <X className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent className="space-y-4 pt-4">
            <div>
              <Label htmlFor="svc-name">Название</Label>
              <Input
                id="svc-name"
                value={form.name}
                onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
                className="mt-1"
              />
            </div>
            <div>
              <Label htmlFor="svc-desc">Описание / цена текстом</Label>
              <Input
                id="svc-desc"
                value={form.description}
                onChange={(e) => setForm((f) => ({ ...f, description: e.target.value }))}
                placeholder="Например: 2 часа — 1500 ₽"
                className="mt-1"
              />
            </div>
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label htmlFor="svc-price">Цена (₽)</Label>
                <Input
                  id="svc-price"
                  inputMode="decimal"
                  value={form.price}
                  onChange={(e) => setForm((f) => ({ ...f, price: e.target.value }))}
                  className="mt-1"
                />
              </div>
              <div>
                <Label htmlFor="svc-sort">Порядок</Label>
                <Input
                  id="svc-sort"
                  inputMode="numeric"
                  value={form.sortOrder}
                  onChange={(e) => setForm((f) => ({ ...f, sortOrder: e.target.value }))}
                  className="mt-1"
                />
              </div>
            </div>
            <div>
              <Label htmlFor="svc-cat">Категория</Label>
              <select
                id="svc-cat"
                className="mt-1 flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
                value={form.category}
                onChange={(e) => setForm((f) => ({ ...f, category: e.target.value }))}
              >
                {categoryOptions.map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={form.active}
                onChange={(e) => setForm((f) => ({ ...f, active: e.target.checked }))}
              />
              Показывать в приложении
            </label>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="outline" onClick={onClose}>
                Отмена
              </Button>
              <Button type="button" disabled={!canSave || saving} onClick={() => onSave(form)}>
                {saving ? 'Сохранение…' : 'Сохранить'}
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export function ServicesPage() {
  const [search, setSearch] = useState('')
  const [editService, setEditService] = useState<Service | null>(null)
  const [creating, setCreating] = useState(false)
  const queryClient = useQueryClient()

  const query = useQuery({
    queryKey: ['admin-services'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Service[]>>('/api/admin/content/services')
      return unwrap(data)
    },
  })

  const invalidate = () => void queryClient.invalidateQueries({ queryKey: ['admin-services'] })

  const sync = useMutation({
    mutationFn: async () => {
      const { data } = await api.post<ApiEnvelope<{ imported: number; tables: number }>>(
        '/api/admin/content/services/sync-salanga',
      )
      return unwrap(data)
    },
    onSuccess: (data) => {
      toast.success(`Импортировано ${data.imported} услуг из ${data.tables} таблиц`)
      invalidate()
    },
    onError: () => toast.error('Не удалось импортировать прайс'),
  })

  const create = useMutation({
    mutationFn: async (form: ServiceForm) => {
      const price = Number(form.price.replace(',', '.'))
      const sortOrder = parseInt(form.sortOrder, 10) || 0
      const { data } = await api.post<ApiEnvelope<Service>>('/api/admin/content/services', {
        name: form.name.trim(),
        description: form.description.trim(),
        price,
        category: form.category,
        sortOrder,
      })
      return unwrap(data)
    },
    onSuccess: () => {
      toast.success('Услуга добавлена')
      setCreating(false)
      invalidate()
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const update = useMutation({
    mutationFn: async ({ id, form }: { id: string; form: ServiceForm }) => {
      const price = Number(form.price.replace(',', '.'))
      const sortOrder = parseInt(form.sortOrder, 10) || 0
      const { data } = await api.put<ApiEnvelope<Service>>(`/api/admin/content/services/${id}`, {
        name: form.name.trim(),
        description: form.description.trim(),
        price,
        category: form.category,
        sortOrder,
        active: form.active,
      })
      return unwrap(data)
    },
    onSuccess: () => {
      toast.success('Услуга обновлена')
      setEditService(null)
      invalidate()
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const toggleActive = useMutation({
    mutationFn: async ({ id, active }: { id: string; active: boolean }) => {
      await api.put(`/api/admin/content/services/${id}`, { active })
    },
    onSuccess: (_, { active }) => {
      toast.success(active ? 'Услуга показана' : 'Услуга скрыта')
      invalidate()
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const remove = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/api/admin/content/services/${id}`)
    },
    onSuccess: () => {
      toast.success('Услуга удалена')
      invalidate()
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase()
    const items = query.data ?? []
    if (!q) return items
    return items.filter(
      (s) =>
        s.name.toLowerCase().includes(q) ||
        (s.description ?? '').toLowerCase().includes(q) ||
        (s.category ?? '').toLowerCase().includes(q),
    )
  }, [query.data, search])

  const grouped = useMemo(() => {
    const map = new Map<string, Service[]>()
    for (const item of filtered) {
      const cat = item.category ?? 'other'
      if (!map.has(cat)) map.set(cat, [])
      map.get(cat)!.push(item)
    }
    return [...map.entries()]
  }, [filtered])

  const handleDelete = (service: Service) => {
    if (!window.confirm(`Удалить «${service.name}»?`)) return
    remove.mutate(service.id)
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">Услуги и прайс</h1>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setCreating(true)}>
            <Plus className="h-4 w-4" />
            Добавить
          </Button>
          <Button onClick={() => sync.mutate()} disabled={sync.isPending}>
            <RefreshCw className={`h-4 w-4 ${sync.isPending ? 'animate-spin' : ''}`} />
            {sync.isPending ? 'Импорт…' : 'Обновить с salanga.ru'}
          </Button>
        </div>
      </div>

      <Input
        placeholder="Поиск по названию или категории"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="max-w-md"
      />

      <Card>
        <CardHeader>
          <CardTitle className="text-base">
            Всего позиций: {query.data?.length ?? 0}
            {search ? ` (найдено: ${filtered.length})` : ''}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {query.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
          {query.isError && <p className="text-destructive">Не удалось загрузить услуги</p>}
          {!query.isLoading && grouped.length === 0 && (
            <p className="text-muted-foreground">
              Нет услуг. Нажмите «Обновить с salanga.ru» или добавьте вручную.
            </p>
          )}
          {grouped.map(([category, items]) => (
            <div key={category}>
              <h2 className="mb-2 font-semibold">{categoryLabels[category] ?? category}</h2>
              <div className="overflow-x-auto rounded border">
                <table className="w-full text-sm">
                  <thead className="bg-muted/50">
                    <tr className="text-left">
                      <th className="p-2">Название</th>
                      <th className="p-2">Цена / описание</th>
                      <th className="p-2">Источник</th>
                      <th className="p-2">Статус</th>
                      <th className="p-2 w-28">Действия</th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((s) => (
                      <tr key={s.id} className="border-t">
                        <td className="p-2 font-medium">{s.name}</td>
                        <td className="p-2 text-muted-foreground">
                          {s.description || `${s.price} ₽`}
                        </td>
                        <td className="p-2">{s.source === 'salanga' ? 'salanga.ru' : 'ручной'}</td>
                        <td className="p-2">{s.active ? 'активна' : 'скрыта'}</td>
                        <td className="p-2">
                          <div className="flex gap-1">
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              title="Редактировать"
                              onClick={() => setEditService(s)}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              title={s.active ? 'Скрыть' : 'Показать'}
                              disabled={toggleActive.isPending}
                              onClick={() => toggleActive.mutate({ id: s.id, active: !s.active })}
                            >
                              {s.active ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              title="Удалить"
                              disabled={remove.isPending}
                              onClick={() => handleDelete(s)}
                            >
                              <Trash2 className="h-4 w-4 text-destructive" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          ))}
        </CardContent>
      </Card>

      {creating && (
        <ServiceModal
          title="Новая услуга"
          initial={emptyForm()}
          onClose={() => setCreating(false)}
          saving={create.isPending}
          onSave={(form) => create.mutate(form)}
        />
      )}

      {editService && (
        <ServiceModal
          title="Редактирование услуги"
          initial={serviceToForm(editService)}
          onClose={() => setEditService(null)}
          saving={update.isPending}
          onSave={(form) => update.mutate({ id: editService.id, form })}
        />
      )}
    </div>
  )
}
