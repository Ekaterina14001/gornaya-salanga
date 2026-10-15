import { useQuery } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Copy } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type PosKey = Record<string, unknown>
type FarCardsInfo = {
  baseUrl?: string
  getCardInfoExPath?: string
  transactionsExPath?: string
  findByQrPath?: string
  auth?: string
  cardCodeHint?: string
  extDllHttpIni?: Record<string, string>
  endpoints?: Array<{ method: string; path: string; header?: string; note?: string }>
}
type PosIntegration = {
  apiUrl?: string
  companyId?: string | number
  timeoutSeconds?: number
  uds?: { apiUrl?: string; companyId?: string | number; timeoutSeconds?: number; auth?: string }
  farcards?: FarCardsInfo
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

function rkeeperKey(keys: PosKey[]) {
  const row = keys.find((k) => String(k.system) === 'RKeeper')
  return row ? String(row.apiKey ?? '') : ''
}

export function PosIntegrationPage() {
  const keysQuery = useQuery({
    queryKey: ['pos-keys'],
    queryFn: async () => {
      const { data } = await api.get<ApiEnvelope<PosIntegration>>('/api/admin/pos/keys')
      return unwrap(data)
    },
  })

  const uds = keysQuery.data?.uds
  const fc = keysQuery.data?.farcards
  const apiUrl = uds?.apiUrl ?? keysQuery.data?.apiUrl ?? ''
  const companyId = uds?.companyId != null ? String(uds.companyId) : keysQuery.data?.companyId != null ? String(keysQuery.data.companyId) : ''
  const timeoutSeconds = uds?.timeoutSeconds ?? keysQuery.data?.timeoutSeconds ?? 15
  const serverKeys = keysQuery.data?.serverKeys ?? []
  const rkKey = rkeeperKey(serverKeys)

  const fcBase = fc?.baseUrl ?? ''
  const getCardUrl = fcBase && fc?.getCardInfoExPath ? `${fcBase}${fc.getCardInfoExPath}` : ''
  const txUrl = fcBase && fc?.transactionsExPath ? `${fcBase}${fc.transactionsExPath}` : ''
  const findQrUrl = fcBase && fc?.findByQrPath ? `${fcBase}${fc.findByQrPath}` : ''

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">{ru.posIntegration}</h1>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">БАРС — UDS Partner API v2</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {keysQuery.isLoading && <p className="text-sm text-muted-foreground">{ru.loading}</p>}
          <CopyRow label="Адрес API" value={apiUrl} />
          <CopyRow label="ИД компании (Basic login)" value={companyId} />
          <CopyRow label="Таймаут, сек" value={String(timeoutSeconds)} />
          <p className="text-sm text-muted-foreground">{uds?.auth ?? 'HTTP Basic: «ИД компании : API-ключ»'}</p>
          {serverKeys
            .filter((k) => String(k.system) === 'Bars')
            .map((key) => (
              <CopyRow
                key={String(key.id)}
                label={`API-ключ — ${String(key.system)}`}
                value={String(key.apiKey ?? '')}
              />
            ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">r_keeper — FarCards (ExtDllHTTP)</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <CopyRow label="Базовый URL" value={fcBase} />
          <CopyRow label="GetCardInfoEx" value={getCardUrl} />
          <CopyRow label="TransactionsEx" value={txUrl} />
          <CopyRow label="FindByQR (Kind=3, QR гостя)" value={findQrUrl} />
          <CopyRow label="X-API-Key (RKeeper)" value={rkKey} />
          <p className="text-sm text-muted-foreground">{fc?.auth}</p>
          <p className="text-sm text-muted-foreground">{fc?.cardCodeHint}</p>
          {fc?.extDllHttpIni && (
            <div className="space-y-1">
              <p className="text-sm font-medium">Пример ExtDllHTTP.ini (фрагмент)</p>
              <pre className="overflow-x-auto rounded-md border bg-muted p-3 text-xs">
                {`[Server]
Address=${fc.extDllHttpIni.Address ?? fcBase}
GetCardInfoEx=${fc.extDllHttpIni.GetCardInfoEx ?? '/api/farcards/getcardinfoex'}
TransactionsEx=${fc.extDllHttpIni.TransactionsEx ?? '/api/farcards/transactionsex'}`}
              </pre>
              <p className="text-xs text-muted-foreground">
                Заголовок X-API-Key настраивается в ExtDLL у интegratorа (если поддерживается) или на прокси.
              </p>
            </div>
          )}
          {fc?.endpoints?.map((ep) => (
            <CopyRow
              key={ep.path}
              label={`${ep.method} ${ep.path}${ep.note ? ` — ${ep.note}` : ''}`}
              value={ep.header ?? ''}
            />
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Ключи POS (Shelter / Bars / RKeeper)</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
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
