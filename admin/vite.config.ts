import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'https://admin.salanga.ru',
        changeOrigin: true,
        secure: true,
      },
      '/health': {
        target: 'https://admin.salanga.ru',
        changeOrigin: true,
        secure: true,
      },
    },
  },
})
