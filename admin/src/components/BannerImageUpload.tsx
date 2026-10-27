import { useRef, useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { api, unwrap, type ApiEnvelope } from '@/core/api/axios'

type Props = {
  value: string
  onChange: (url: string) => void
  disabled?: boolean
  /** Показывать превью с salanga.ru, если своё изображение не задано */
  previewFallbackUrl?: string
}

export function BannerImageUpload({ value, onChange, disabled, previewFallbackUrl }: Props) {
  const previewSrc = value.trim() || previewFallbackUrl || ''
  const inputRef = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)

  async function onFile(file: File) {
    setUploading(true)
    try {
      const form = new FormData()
      form.append('file', file)
      const { data } = await api.post<ApiEnvelope<{ url: string; path: string }>>(
        '/api/admin/content/upload',
        form,
        { headers: { 'Content-Type': 'multipart/form-data' } },
      )
      const payload = unwrap(data)
      onChange(payload.url || payload.path)
      toast.success('Изображение загружено')
    } catch {
      toast.error('Не удалось загрузить файл')
    } finally {
      setUploading(false)
    }
  }

  return (
    <div className="space-y-2 md:col-span-2">
      <div className="flex flex-wrap items-center gap-2">
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          className="hidden"
          disabled={disabled || uploading}
          onChange={(e) => {
            const file = e.target.files?.[0]
            if (file) void onFile(file)
            e.target.value = ''
          }}
        />
        <Button
          type="button"
          size="sm"
          variant="secondary"
          disabled={disabled || uploading}
          onClick={() => inputRef.current?.click()}
        >
          {uploading ? 'Загрузка…' : 'Загрузить картинку'}
        </Button>
        {value.trim() ? (
          <Button
            type="button"
            size="sm"
            variant="outline"
            disabled={disabled || uploading}
            onClick={() => {
              onChange('')
              toast.success('Снова будет использоваться баннер с salanga.ru — нажмите «Сохранить»')
            }}
          >
            Вернуть баннер с сайта
          </Button>
        ) : null}
        {value.trim() ? (
          <span className="max-w-full truncate text-xs text-muted-foreground">{value}</span>
        ) : (
          <span className="text-xs text-muted-foreground">
            Сейчас с salanga.ru · можно загрузить своё (JPEG, PNG, WebP до 8 МБ)
          </span>
        )}
      </div>
      {previewSrc ? (
        <img src={previewSrc} alt="" className="max-h-32 rounded-md border object-contain" />
      ) : null}
      <Input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Своё изображение (URL) — необязательно"
        disabled={disabled}
      />
    </div>
  )
}

