import { useQuery } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Copy } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'
import { ru } from '@/i18n/ru'

type PosKey = Record<string, unknown>
type FarCardsDllInfo = {
  fileName?: string
  iniName?: string
  farcardsDll?: string
  architecture?: string
  farcardsVer?: string
  repoReadme?: string
  ciArtifact?: string
}
type FarCardsInfo = {
  baseUrl?: string
  publicSiteUrl?: string
  getCardInfoExPath?: string
  transactionsExPath?: string
  findByQrPath?: string
  auth?: string
  cardCodeHint?: string
  recommendedIntegration?: string
  dllInfo?: FarCardsDllInfo
  setupSteps?: string[]
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

function CopyPre({ label, text }: { label: string; text: string }) {
  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm font-medium">{label}</p>
        <Button type="button" variant="outline" size="sm" disabled={!text} onClick={() => void copyText(text)}>
          <Copy className="mr-1 h-3 w-3" />
          Копировать
        </Button>
      </div>
      <pre className="overflow-x-auto rounded-md border bg-muted p-3 text-xs whitespace-pre-wrap">{text}</pre>
    </div>
  )
}

function rkeeperKey(keys: PosKey[]) {
  const row = keys.find((k) => String(k.system) === 'RKeeper')
  return row ? String(row.apiKey ?? '') : ''
}

function buildSalangaExtDllIni(publicSiteUrl: string, apiKey: string) {
  const base = publicSiteUrl.trim() || 'https://admin.salanga.ru'
  const key = apiKey.trim() || 'YOUR_RKEEPER_POS_API_KEY'
  return `[API]
BaseUrl=${base}
ApiKey=${key}
TimeoutSec=30
Log=3
XMLCP=1251`
}

function buildFarcardsIni(dllName: string) {
  return `[FarServer]
Type=1
DLL=${dllName}
Log=3
XMLCP=1251

[LinkDLL]
1=pds_netk

[pds_netk]
ininame=pds_netk.ini
NetServerName=FARCARDS_NETNAME`
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
  const fcPublicRoot = fc?.publicSiteUrl ?? fcBase.replace(/\/api\/farcards\/?$/, '') || ''
  const getCardUrl = fcBase && fc?.getCardInfoExPath ? `${fcBase}${fc.getCardInfoExPath}` : ''
  const txUrl = fcBase && fc?.transactionsExPath ? `${fcBase}${fc.transactionsExPath}` : ''
  const findQrUrl = fcBase && fc?.findByQrPath ? `${fcBase}${fc.findByQrPath}` : ''
  const dll = fc?.dllInfo
  const dllName = dll?.farcardsDll ?? 'SalangaExtDll'
  const salangaIni = buildSalangaExtDllIni(fcPublicRoot, rkKey)
  const farcardsIni = buildFarcardsIni(dllName)

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
          <CardTitle className="text-base">r_keeper — FarCards</CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          {fc?.recommendedIntegration && (
            <p className="text-sm font-medium text-primary">{fc.recommendedIntegration}</p>
          )}

          <div className="space-y-4 rounded-lg border p-4">
            <h2 className="text-sm font-semibold">SalangaExtDll (Type=1) — рекомендуется</h2>
            {dll && (
              <ul className="list-inside list-disc space-y-1 text-sm text-muted-foreground">
                <li>
                  Файлы: {dll.fileName}, {dll.iniName} — каталог FarCards {dll.farcardsVer}, {dll.architecture}
                </li>
                {dll.repoReadme && <li>Документация в репозитории: {dll.repoReadme}</li>}
                {dll.ciArtifact && <li>Сборка DLL: {dll.ciArtifact}</li>}
              </ul>
            )}
            <CopyRow
              label="BaseUrl для SalangaExtDll.ini (корень сайта, без /api/farcards)"
              value={fcPublicRoot}
            />
            <CopyRow label="X-API-Key (RKeeper) → ApiKey в SalangaExtDll.ini" value={rkKey} />
            <CopyPre label="SalangaExtDll.ini" text={salangaIni} />
            <CopyPre label="Farcards.ini (фрагмент [FarServer])" text={farcardsIni} />
            {fc?.setupSteps && fc.setupSteps.length > 0 && (
              <div className="space-y-1">
                <p className="text-sm font-medium">Шаги на стороне кассового сервера</p>
                <ol className="list-inside list-decimal space-y-1 text-sm text-muted-foreground">
                  {fc.setupSteps.map((step) => (
                    <li key={step}>{step}</li>
                  ))}
                </ol>
              </div>
            )}
          </div>

          <div className="space-y-4 rounded-lg border p-4">
            <h2 className="text-sm font-semibold">HTTP API (вызывается из DLL)</h2>
            <CopyRow label="Префикс FarCards API" value={fcBase} />
            <CopyRow label="GetCardInfoEx" value={getCardUrl} />
            <CopyRow label="TransactionsEx" value={txUrl} />
            <CopyRow label="FindByQR (Kind=3, QR гостя)" value={findQrUrl} />
            <p className="text-sm text-muted-foreground">{fc?.auth}</p>
            <p className="text-sm text-muted-foreground">{fc?.cardCodeHint}</p>
            {fc?.endpoints?.map((ep) => (
              <CopyRow
                key={ep.path}
                label={`${ep.method} ${ep.path}${ep.note ? ` — ${ep.note}` : ''}`}
                value={ep.header ?? ''}
              />
            ))}
          </div>

          {fc?.extDllHttpIni && (
            <div className="space-y-4 rounded-lg border border-dashed p-4">
              <h2 className="text-sm font-semibold">Альтернатива: ExtDllHTTP (UCS / HTTP-прокси)</h2>
              <p className="text-xs text-muted-foreground">
                Если используется сторонняя HTTP-обёртка вместо SalangaExtDll.dll — те же пути и X-API-Key.
              </p>
              <CopyPre
                label="Пример ExtDllHTTP.ini (фрагмент)"
                text={`[Server]
Address=${fc.extDllHttpIni.Address ?? fcPublicRoot}
GetCardInfoEx=${fc.extDllHttpIni.GetCardInfoEx ?? '/api/farcards/getcardinfoex'}
TransactionsEx=${fc.extDllHttpIni.TransactionsEx ?? '/api/farcards/transactionsex'}`}
              />
            </div>
          )}
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
