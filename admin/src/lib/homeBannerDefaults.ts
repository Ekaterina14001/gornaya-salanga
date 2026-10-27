const SALANGA = 'https://www.salanga.ru'

export const defaultHomeBannerImage = (sortOrder: number): string => {
  const urls = [
    `${SALANGA}/up/17/51a5c408d8-glavnayazima-02.jpg`,
    `${SALANGA}/up/room/nomer-04.jpg`,
    `${SALANGA}/yiiassets/easyimage/6/6917b199b8c40571210a89edf50a2b25.jpg`,
  ]
  if (sortOrder < 0) return urls[0]
  if (sortOrder >= urls.length) return urls[0]
  return urls[sortOrder]
}

export const effectiveBannerImage = (stored: string | undefined, sortOrder: number): string => {
  const trimmed = (stored ?? '').trim()
  if (trimmed) return trimmed
  return defaultHomeBannerImage(sortOrder)
}

export function slotLabel(sortOrder: number): string {
  if (sortOrder === 0) return 'Верхний баннер (кнопка «Забронировать»)'
  return `Нижняя карусель · слайд ${sortOrder}`
}

export function nextSortOrderForNew(items: { sortOrder?: number; active?: boolean }[] | undefined): number {
  const active = (items ?? []).filter((h) => h.active !== false)
  const hasTop = active.some((h) => (h.sortOrder ?? 0) === 0)
  if (!hasTop) return 0
  const lower = active
    .map((h) => h.sortOrder ?? 0)
    .filter((n) => n > 0)
  if (lower.length === 0) return 1
  return Math.max(...lower) + 1
}
