import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
  type SortingState,
} from '@tanstack/react-table'
import { Eye, X } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { api, apiErrorMessage, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type User = {
  id: string
  email: string
  phone: string
  firstName: string
  lastName: string
  role: string
  blocked: boolean
  phoneVerified: boolean
  emailVerified: boolean
  createdAt: string
}

type Paginated<T> = {
  items: T[]
  total: number
  page: number
  pageSize: number
}

type UserDetail = {
  user: User
  bonusAccount?: { balance: number; totalEarned: number; totalSpent: number }
  recentTransactions?: Array<{
    id: string
    type: string
    amount: number
    description?: string
    createdAt: string
  }>
}

const columnHelper = createColumnHelper<User>()

function parseAmount(raw: string): number | null {
  const normalized = raw.trim().replace(',', '.')
  if (!normalized) return null
  const value = Number(normalized)
  if (!Number.isFinite(value) || value <= 0) return null
  return value
}

function UserDetailModal({ userId, onClose }: { userId: string; onClose: () => void }) {
  const queryClient = useQueryClient()
  const [amount, setAmount] = useState('')
  const [txType, setTxType] = useState<'earn' | 'spend'>('earn')
  const [description, setDescription] = useState('')
  const dialogRef = useRef<HTMLDivElement>(null)

  const parsedAmount = parseAmount(amount)
  const canApply = parsedAmount != null

  useEffect(() => {
    dialogRef.current?.focus()
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const detailQuery = useQuery({
    queryKey: ['admin-user', userId],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<UserDetail>>(`/api/admin/users/${userId}`)
      return unwrap(data)
    },
  })

  const adjust = useMutation({
    mutationFn: async () => {
      if (parsedAmount == null) throw new Error('Укажите сумму')
      await api.post(`/api/admin/users/${userId}/bonus/adjust`, {
        type: txType,
        amount: parsedAmount,
        description: description.trim() || undefined,
      })
    },
    onSuccess: () => {
      toast.success(txType === 'earn' ? `Начислено ${parsedAmount} бонусов` : `Списано ${parsedAmount} бонусов`)
      setAmount('')
      setDescription('')
      void queryClient.invalidateQueries({ queryKey: ['admin-user', userId] })
      void queryClient.invalidateQueries({ queryKey: ['admin-users'] })
    },
    onError: (err) => toast.error(apiErrorMessage(err)),
  })

  const user = detailQuery.data?.user
  const account = detailQuery.data?.bonusAccount
  const isBlocked = user?.blocked === true

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
        aria-labelledby="user-card-title"
        className="relative w-full max-w-2xl rounded-lg border bg-background shadow-xl outline-none"
        onClick={(e) => e.stopPropagation()}
      >
        <Card className="border-0 shadow-none">
          <CardHeader className="flex flex-row items-start justify-between gap-4 border-b bg-muted/40">
            <div>
              <CardTitle id="user-card-title" className="text-lg">
                {user ? `${user.firstName} ${user.lastName}` : 'Карточка пользователя'}
              </CardTitle>
              {user && <p className="text-sm text-muted-foreground mt-1">{user.email}</p>}
            </div>
            <Button type="button" variant="outline" size="icon" onClick={onClose} aria-label="Закрыть">
              <X className="h-4 w-4" />
            </Button>
          </CardHeader>
          <CardContent className="space-y-4 pt-4 max-h-[70vh] overflow-y-auto">
            {detailQuery.isLoading && <p className="text-muted-foreground">Загрузка...</p>}
            {detailQuery.isError && (
              <p className="text-destructive">Не удалось загрузить данные пользователя</p>
            )}
            {user && (
              <>
                <div className="grid gap-2 text-sm md:grid-cols-2">
                  <p>
                    <span className="text-muted-foreground">Телефон:</span> {user.phone}
                  </p>
                  <p>
                    <span className="text-muted-foreground">Роль:</span> {user.role}
                  </p>
                  <p>
                    <span className="text-muted-foreground">Статус:</span>{' '}
                    {user.blocked ? 'Заблокирован' : 'Активен'}
                  </p>
                  <p>
                    <span className="text-muted-foreground">Баланс бонусов:</span>{' '}
                    <strong className="text-lg text-primary">{account?.balance ?? 0}</strong>
                  </p>
                </div>

                <div className="rounded-lg border bg-muted/20 p-4 space-y-4">
                  <div>
                    <p className="font-medium">Корректировка бонусов</p>
                    <p className="text-sm text-muted-foreground mt-1">
                      Укажите <strong>сумму</strong> (обязательно), затем нажмите «Применить корректировку».
                    </p>
                  </div>

                  <div>
                    <Label htmlFor="bonus-type">Тип операции</Label>
                    <select
                      id="bonus-type"
                      className="mt-1 flex h-10 w-full rounded-md border border-input bg-background px-3 text-sm"
                      value={txType}
                      onChange={(e) => setTxType(e.target.value as 'earn' | 'spend')}
                      disabled={isBlocked}
                    >
                      <option value="earn">Начислить бонусы</option>
                      <option value="spend">Списать бонусы</option>
                    </select>
                  </div>

                  <div>
                    <Label htmlFor="bonus-amount">
                      Сумма <span className="text-destructive">*</span>
                    </Label>
                    <Input
                      id="bonus-amount"
                      type="text"
                      inputMode="decimal"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      placeholder="Например: 100"
                      disabled={isBlocked}
                      className="mt-1"
                    />
                  </div>

                  <div>
                    <Label htmlFor="bonus-comment">Комментарий (необязательно)</Label>
                    <Input
                      id="bonus-comment"
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      placeholder="Причина корректировки"
                      disabled={isBlocked}
                      className="mt-1"
                    />
                  </div>

                  {canApply && !isBlocked && (
                    <p className="text-sm text-muted-foreground">
                      {txType === 'earn'
                        ? `Будет начислено: +${parsedAmount} бонусов`
                        : `Будет списано: −${parsedAmount} бонусов`}
                    </p>
                  )}

                  <Button
                    type="button"
                    size="lg"
                    className="w-full"
                    onClick={() => adjust.mutate()}
                    disabled={!canApply || adjust.isPending || isBlocked}
                  >
                    {adjust.isPending ? 'Сохранение…' : 'Применить корректировку'}
                  </Button>

                  {isBlocked && (
                    <p className="text-sm text-destructive">
                      Пользователь заблокирован. Сначала нажмите «Разблокировать» в таблице.
                    </p>
                  )}
                </div>

                {(detailQuery.data?.recentTransactions?.length ?? 0) > 0 && (
                  <div>
                    <p className="mb-2 font-medium text-sm">Последние операции</p>
                    <ul className="space-y-1 text-sm">
                      {detailQuery.data?.recentTransactions?.map((tx) => (
                        <li key={tx.id} className="rounded border px-2 py-1">
                          {new Date(tx.createdAt).toLocaleString('ru-RU')} — {tx.type === 'earn' ? '+' : '−'}
                          {tx.amount} ({tx.description ?? '—'})
                        </li>
                      ))}
                    </ul>
                  </div>
                )}
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export function UsersPage() {
  const [search, setSearch] = useState('')
  const [sorting, setSorting] = useState<SortingState>([])
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null)
  const queryClient = useQueryClient()

  const openUser = useCallback((id: string) => {
    setSelectedUserId(id)
  }, [])

  const closeUser = useCallback(() => {
    setSelectedUserId(null)
  }, [])

  const query = useQuery({
    queryKey: ['admin-users', search],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Paginated<User>>>('/api/admin/users', {
        params: { q: search, page: 1, pageSize: 50 },
      })
      return unwrap(data)
    },
  })

  const blockMutation = useMutation({
    mutationFn: async ({ id, blocked }: { id: string; blocked: boolean }) => {
      await api.patch(`/api/admin/users/${id}/block`, { blocked })
    },
    onSuccess: () => {
      toast.success('Статус обновлён')
      void queryClient.invalidateQueries({ queryKey: ['admin-users'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-user'] })
    },
    onError: () => toast.error('Ошибка'),
  })

  const columns = useMemo(
    () => [
      columnHelper.accessor('email', { header: ru.email }),
      columnHelper.accessor('phone', { header: 'Телефон' }),
      columnHelper.accessor((r) => `${r.firstName} ${r.lastName}`, { id: 'name', header: 'Имя' }),
      columnHelper.accessor('role', { header: 'Роль' }),
      columnHelper.accessor('createdAt', {
        header: 'Регистрация',
        cell: (info) => new Date(info.getValue()).toLocaleDateString('ru-RU'),
      }),
      columnHelper.accessor('blocked', {
        header: ru.status,
        cell: (info) => (info.getValue() ? 'Заблокирован' : 'Активен'),
      }),
      columnHelper.display({
        id: 'actions',
        header: ru.actions,
        cell: ({ row }) => (
          <div className="flex flex-wrap gap-2">
            <Button
              type="button"
              size="sm"
              variant="default"
              className="shadow-sm"
              onClick={() => openUser(row.original.id)}
            >
              <Eye className="h-4 w-4" />
              Открыть карточку
            </Button>
            <Button
              type="button"
              size="sm"
              variant="outline"
              onClick={() =>
                blockMutation.mutate({ id: row.original.id, blocked: !row.original.blocked })
              }
            >
              {row.original.blocked ? ru.unblock : ru.block}
            </Button>
          </div>
        ),
      }),
    ],
    [blockMutation, openUser],
  )

  const table = useReactTable({
    data: query.data?.items ?? [],
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
  })

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">{ru.users}</h1>
      <Input placeholder={ru.search} value={search} onChange={(e) => setSearch(e.target.value)} className="max-w-sm" />
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Всего: {query.data?.total ?? 0}</CardTitle>
        </CardHeader>
        <CardContent className="overflow-x-auto">
          {query.isLoading && <p className="p-4 text-muted-foreground">Загрузка...</p>}
          {query.isError && (
            <p className="p-4 text-destructive">Не удалось загрузить пользователей</p>
          )}
          {!query.isLoading && !query.isError && (
            <table className="w-full text-sm">
              <thead>
                {table.getHeaderGroups().map((hg) => (
                  <tr key={hg.id} className="border-b text-left">
                    {hg.headers.map((h) => (
                      <th key={h.id} className="p-2 font-medium">
                        {flexRender(h.column.columnDef.header, h.getContext())}
                      </th>
                    ))}
                  </tr>
                ))}
              </thead>
              <tbody>
                {table.getRowModel().rows.map((row) => (
                  <tr
                    key={row.id}
                    className={`border-b ${selectedUserId === row.original.id ? 'bg-primary/5' : ''}`}
                  >
                    {row.getVisibleCells().map((cell) => (
                      <td key={cell.id} className="p-2">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          {!query.isLoading && !query.isError && !query.data?.items.length && (
            <p className="p-4 text-muted-foreground">{ru.noData}</p>
          )}
        </CardContent>
      </Card>

      {selectedUserId && <UserDetailModal userId={selectedUserId} onClose={closeUser} />}
    </div>
  )
}
