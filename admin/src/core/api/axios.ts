import axios, { type AxiosError, type InternalAxiosRequestConfig } from 'axios'
import { API_URL, REFRESH_KEY, TOKEN_KEY } from '../config'

export interface ApiEnvelope<T> {
  data?: T
  error?: { code: string; message: string }
}

export const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

let refreshing = false

api.interceptors.response.use(
  (res) => res,
  async (error: AxiosError) => {
    if (error.response?.status !== 401 || refreshing) {
      return Promise.reject(error)
    }
    refreshing = true
    try {
      const refreshToken = localStorage.getItem(REFRESH_KEY)
      if (!refreshToken) throw error
      const { data } = await axios.post<ApiEnvelope<{ accessToken: string; refreshToken: string }>>(
        `${API_URL}/api/auth/refresh`,
        { refreshToken },
      )
      const payload = data.data
      if (!payload?.accessToken) throw error
      localStorage.setItem(TOKEN_KEY, payload.accessToken)
      if (payload.refreshToken) {
        localStorage.setItem(REFRESH_KEY, payload.refreshToken)
      }
      const original = error.config
      if (original) {
        original.headers.Authorization = `Bearer ${payload.accessToken}`
        return api(original)
      }
    } finally {
      refreshing = false
    }
    return Promise.reject(error)
  },
)

export function unwrap<T>(body: ApiEnvelope<T> | T): T {
  if (body && typeof body === 'object' && 'data' in body && body.data !== undefined) {
    return body.data as T
  }
  return body as T
}

export function apiErrorMessage(error: unknown): string {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data as ApiEnvelope<unknown> | undefined
    return data?.error?.message ?? error.message
  }
  return 'Неизвестная ошибка'
}
