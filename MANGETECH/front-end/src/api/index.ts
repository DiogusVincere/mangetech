// src/api/index.ts — chamadas à API do MangeTech
import api from './client'
import type {
  Asset,
  AssetHistory,
  AssetTask,
  DashboardData,
  Page,
  Task,
  User,
  UserStats,
} from '@/types'

export { default as api, API_URL, extractError, extractFieldErrors, downloadBlob } from './client'

/** Remove filtros vazios para não mandar `?status=&search=` à API. */
function clean(params?: Record<string, any>) {
  const out: Record<string, any> = {}
  for (const [k, v] of Object.entries(params || {})) {
    if (v === '' || v === null || v === undefined || v === false) continue
    out[k] = v
  }
  return out
}

/** Lê todas as páginas de uma listagem (para listas pequenas: ativos, usuários). */
async function getAllPages<T>(url: string, params?: Record<string, any>): Promise<T[]> {
  const { data } = await api.get(url, { params: { page_size: 1000, ...clean(params) } })
  if (Array.isArray(data)) return data
  const items: T[] = [...(data.results || [])]
  let next: string | null = data.next
  while (next) {
    const { data: page } = await api.get(next)
    items.push(...(page.results || []))
    next = page.next
  }
  return items
}

// ============================================
// AUTH
// ============================================
export const authApi = {
  async login(email: string, password: string) {
    const { data } = await api.post('/auth/login/', { email, senha: password })
    return data as { token: string; user: User }
  },

  async register(name: string, email: string, password: string) {
    const { data } = await api.post('/auth/register/', { nome: name, email, senha: password })
    return data as { token: string; user: User }
  },

  async logout() {
    await api.post('/auth/logout/')
  },

  async getMe() {
    const { data } = await api.get('/usuarios/me/')
    return data.user as User
  },

  async requestPasswordReset(email: string) {
    const { data } = await api.post('/auth/solicitar-recuperacao-senha/', { email })
    return data
  },

  async verifyResetToken(email: string, token: string) {
    const { data } = await api.post('/auth/verificar-token-recuperacao/', { email, token })
    return data
  },

  async resetPassword(email: string, token: string, password: string, confirm: string) {
    const { data } = await api.post('/auth/resetar-senha/', {
      email,
      token,
      nova_senha: password,
      confirmar_senha: confirm,
    })
    return data
  },
}

// ============================================
// CHAMADOS
// ============================================
export const tasksApi = {
  async list(filters?: Record<string, any>, page = 1, pageSize = 20) {
    const { data } = await api.get('/chamados/', {
      params: { ...clean(filters), page, page_size: pageSize },
    })
    return data as Page<Task>
  },

  async getById(id: number | string) {
    const { data } = await api.get(`/chamados/${id}/`)
    return data as Task
  },

  async create(task: Record<string, any>) {
    const { data } = await api.post('/chamados/', task)
    return data as Task
  },

  async update(id: number | string, task: Record<string, any>) {
    const { data } = await api.patch(`/chamados/${id}/`, task)
    return data as Task
  },

  async remove(id: number | string) {
    await api.delete(`/chamados/${id}/`)
  },

  async changeStatus(id: number | string, payload: FormData) {
    const { data } = await api.post(`/chamados/${id}/mudar_status/`, payload)
    return data as { success: boolean; message: string; chamado: Task }
  },

  async addComment(id: number | string, payload: FormData) {
    const { data } = await api.post(`/chamados/${id}/adicionar_comentario/`, payload)
    return data
  },

  async addAttachment(id: number | string, arquivo: File) {
    const formData = new FormData()
    formData.append('arquivo', arquivo)
    const { data } = await api.post(`/chamados/${id}/adicionar_anexo/`, formData)
    return data
  },

  async removeAttachment(id: number | string, anexoId: number) {
    await api.delete(`/chamados/${id}/anexos/${anexoId}/`)
  },

  async bulkDelete(ids: (number | string)[]) {
    const { data } = await api.post('/chamados/bulk-delete/', { ids: ids.map(Number) })
    return data as {
      quantidade_excluida: number
      ids_excluidos: number[]
      ids_em_andamento: number[]
      nao_localizados_ou_sem_permissao: number
    }
  },

  async exportCSV(filters?: Record<string, any>) {
    const { data } = await api.get('/chamados/export/', {
      params: clean(filters),
      responseType: 'blob',
    })
    return data as Blob
  },
}

// ============================================
// ATIVOS
// ============================================
export const assetsApi = {
  async getAll(filters?: Record<string, any>) {
    return getAllPages<Asset>('/ativos/', filters)
  },

  async getById(id: number | string) {
    const { data } = await api.get(`/ativos/${id}/`)
    return data as Asset
  },

  async create(asset: Record<string, any>) {
    const { data } = await api.post('/ativos/', asset)
    return data as Asset
  },

  async update(id: number | string, asset: Record<string, any>) {
    const { data } = await api.patch(`/ativos/${id}/`, asset)
    return data as Asset
  },

  async remove(id: number | string) {
    await api.delete(`/ativos/${id}/`)
  },

  async getTasks(id: number | string) {
    const { data } = await api.get(`/ativos/${id}/chamados/`)
    return (data.chamados || []) as AssetTask[]
  },

  async getQRCode(id: number | string) {
    const { data } = await api.get(`/ativos/${id}/qr-code/`)
    return data as {
      qr_code: string
      ativo_codigo: string
      ativo_nome: string
      ativo_modelo?: string
      ativo_ambiente?: string
    }
  },

  async addHistory(id: number | string, tipo: string, descricao: string) {
    const { data } = await api.post(`/ativos/${id}/adicionar_historico/`, { tipo, descricao })
    return data.historico as AssetHistory
  },
}

// ============================================
// USUÁRIOS
// ============================================
export const usersApi = {
  async getAll(filters?: Record<string, any>) {
    return getAllPages<User>('/usuarios/', filters)
  },

  async getById(id: number | string) {
    const { data } = await api.get(`/usuarios/${id}/`)
    return data as User
  },

  async update(id: number | string, changes: Partial<User>) {
    const { data } = await api.patch(`/usuarios/${id}/`, changes)
    return data as User
  },

  async remove(id: number | string) {
    await api.delete(`/usuarios/${id}/`)
  },

  async getStatistics(id: number | string) {
    const { data } = await api.get(`/usuarios/${id}/estatisticas/`)
    return data.data as UserStats
  },
}

// ============================================
// PERFIL
// ============================================
export const profileApi = {
  async get() {
    const { data } = await api.get('/perfil/')
    return data.data as User
  },

  async update(changes: Partial<User>) {
    const { data } = await api.patch('/perfil/atualizar/', changes)
    return data.data as User
  },

  async changePassword(current: string, password: string, confirm: string) {
    const { data } = await api.post('/perfil/alterar-senha/', {
      senha_atual: current,
      nova_senha: password,
      confirmar_senha: confirm,
    })
    return data as { token: string }
  },

  async getStatistics() {
    const { data } = await api.get('/perfil/estatisticas/')
    return data.data as UserStats
  },
}

// ============================================
// DASHBOARD
// ============================================
export const dashboardApi = {
  async getIndicators(dias?: number | string) {
    const { data } = await api.get('/dashboard/gerencial/', { params: clean({ dias }) })
    return data.data as DashboardData
  },
}

export default api
