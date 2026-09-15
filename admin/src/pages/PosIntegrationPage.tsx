import { useQuery } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Copy } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type PosKey = Record<string, unknown>
type PosIntegration = {
  apiUrl?: string
  companyId?: string | number
  timeoutSeconds?: number
  serverKeys?: PosKey[]
}

async function copyText(value: string) {
  try {
    await navigator.clipboard.writeText(value)
    toast.success('Скопировано')
  } catch {
    toast.error('Не удалось скопировать')
  }
}

function CopyRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="space-y-1">
      <p className="text-sm font-medium">{label}</p>
      <div className="flex items-center gap-2">
        <code className="flex-1 break-all rounded-md border bg-muted px-3 py-2 text-sm">{value || '—'}</code>
        <Button
          type="button"
          variant="outline"
          size="icon"
          disabled={!value}
          onClick={() => void copyText(value)}
        >
          <Copy className="h-4 w-4" />
        </Button>
      </div>
    </div>
  )
}

export function PosIntegrationPage() {
  const keysQuery = useQuery({
    queryKey: ['pos-keys'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<PosIntegration>>('/api/admin/pos/keys')
      return unwrap(data)
    },
  })

  const apiUrl = keysQuery.data?.apiUrl ?? ''
  const companyId = keysQuery.data?.companyId != null ? String(keysQuery.data.companyId) : ''
  const timeoutSeconds = keysQuery.data?.timeoutSeconds ?? 15
  const serverKeys = keysQuery.data?.serverKeys ?? []

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.posIntegration}</h1>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Касса — вкладка «Бонусная система UDS»</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {keysQuery.isLoading && <p className="text-sm text-muted-foreground">{ru.loading}</p>}
          <CopyRow label="Адрес API" value={apiUrl} />
          <CopyRow label="ИД компании" value={companyId} />
          <CopyRow label="Таймаут" value={String(timeoutSeconds)} />
          {serverKeys.map((key) => (
            <CopyRow
              key={String(key.id)}
              label={`API ключ — ${String(key.system)}`}
              value={String(key.apiKey ?? '')}
            />
          ))}
          {!keysQuery.isLoading && serverKeys.length === 0 && (
            <p className="text-sm text-muted-foreground">{ru.noData}</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
