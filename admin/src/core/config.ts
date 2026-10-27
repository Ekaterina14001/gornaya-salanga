/**
 * Пустой baseURL = запросы на тот же хост, что и админка (/api, /health через nginx).
 * Так работает с любого устройства. Переопределение — только через VITE_API_URL при сборке.
 */
const viteApi = import.meta.env.VITE_API_URL
export const API_URL =
  viteApi !== undefined && String(viteApi).trim() !== ''
    ? String(viteApi).trim().replace(/\/+$/, '')
    : ''

export const TOKEN_KEY = 'gs_admin_access'
export const REFRESH_KEY = 'gs_admin_refresh'
