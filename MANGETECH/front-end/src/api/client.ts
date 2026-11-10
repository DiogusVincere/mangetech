// src/api/client.ts — instância do axios, token e tratamento de erros
import axios from 'axios'

// URL da API: defina VITE_API_URL no .env do front (ver .env.example).
// Sem a variável, usa a API publicada no Render.
export const API_URL: string = (
  import.meta.env.VITE_API_URL || 'https://mangetech-api.onrender.com/api'
).replace(/\/+$/, '')

const api = axios.create({
  baseURL: API_URL,
  timeout: 60000, // o Render gratuito leva ~30 s para acordar
})

export const TOKEN_KEY = 'token'
export const USER_KEY = 'user'

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY)
  if (token) {
    config.headers.Authorization = `Token ${token}`
  }
  return config
})

// 401 com token salvo = sessão expirada: limpa e volta para o login.
// (401 no próprio login é "senha errada" e precisa chegar até a tela.)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const url: string = error.config?.url || ''
    const tinhaToken = !!error.config?.headers?.Authorization
    if (error.response?.status === 401 && tinhaToken && !url.includes('/auth/')) {
      localStorage.removeItem(TOKEN_KEY)
      localStorage.removeItem(USER_KEY)
      if (!window.location.pathname.startsWith('/login')) {
        const destino = encodeURIComponent(window.location.pathname + window.location.search)
        window.location.href = `/login?redirect=${destino}&expirou=1`
      }
    }
    return Promise.reject(error)
  }
)

/** Mensagem legível de um erro do axios (a API devolve `message`). */
export function extractError(error: any, fallback = 'Algo deu errado. Tente novamente.'): string {
  if (!error) return fallback
  if (error.code === 'ECONNABORTED') return 'O servidor demorou para responder. Tente de novo.'
  if (error.message === 'Network Error' || !error.response) {
    return 'Não foi possível falar com o servidor. Verifique a conexão.'
  }
  const data = error.response.data
  if (data && typeof data === 'object') {
    if (typeof data.message === 'string' && data.message) return data.message
    if (typeof data.detail === 'string' && data.detail) return data.detail
    const errors = data.errors || data
    for (const valor of Object.values(errors)) {
      if (typeof valor === 'string' && valor) return valor
      if (Array.isArray(valor) && valor.length) return String(valor[0])
    }
  }
  if (error.response.status === 403) return 'Você não tem permissão para fazer isso.'
  if (error.response.status === 404) return 'Registro não encontrado.'
  if (error.response.status >= 500) return 'Erro no servidor. Tente novamente em instantes.'
  return fallback
}

/** Baixa um Blob como arquivo. */
export function downloadBlob(blob: Blob, filename: string) {
  const url = window.URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  window.URL.revokeObjectURL(url)
}

export default api
