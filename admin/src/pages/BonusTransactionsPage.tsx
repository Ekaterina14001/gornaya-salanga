import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  getSortedRowModel,
  useReactTable,
  type SortingState,
} from '@tanstack/react-table'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { API_URL, TOKEN_KEY } from '@/core/config'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type Tx = {
  id: string
  userId: string
  type: string
  amount: number
  source?: string
  createdAt: string
}

type Paginated<T> = { items: T[]; total: number }

const columnHelper = createColumnHelper<Tx>()

export function BonusTransactionsPage() {
  const [userId, setUserId] = useState('')
  const [type, setType] = useState('')
  const [sorting, setSorting] = useState<SortingState>([])

  const query = useQuery({
    queryKey: ['admin-transactions', userId, type],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<Paginated<Tx>>>('/api/admin/bonus/transactions', {
        params: { userId: userId || undefined, type: type || undefined, page: 1, pageSize: 100 },
      })
      return unwrap(data)
    },
  })

  const columns = useMemo(
    () => [
      columnHelper.accessor('createdAt', { header: ru.createdAt }),
      columnHelper.accessor('userId', { header: 'User ID' }),
      columnHelper.accessor('type', { header: ru.type }),
      columnHelper.accessor('amount', { header: ru.amount }),
      columnHelper.accessor('source', { header: 'Источник' }),
    ],
    [],
  )

  const table = useReactTable({
    data: query.data?.items ?? [],
    columns,
    state: { sorting },
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  })

  const exportCsv = async () => {
    const token = localStorage.getItem(TOKEN_KEY)
    const res = await fetch(`${API_URL}/api/admin/bonus/transactions/export`, {
      headers: { Authorization: `Bearer ${token}` },
    })
    const blob = await res.blob()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'transactions.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <h1 className="text-2xl font-bold">{ru.bonusTransactions}</h1>
        <Button variant="outline" onClick={() => void exportCsv()}>
          {ru.export}
        </Button>
      </div>
      <div className="flex gap-2">
        <Input placeholder="User ID" value={userId} onChange={(e) => setUserId(e.target.value)} className="max-w-xs" />
        <Input placeholder={ru.type} value={type} onChange={(e) => setType(e.target.value)} className="max-w-xs" />
      </div>
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Всего: {query.data?.total ?? 0}</CardTitle>
        </CardHeader>
        <CardContent className="overflow-x-auto">
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
                <tr key={row.id} className="border-b">
                  {row.getVisibleCells().map((cell) => (
                    <td key={cell.id} className="p-2">
                      {flexRender(cell.column.columnDef.cell, cell.getContext())}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>
    </div>
  )
}
