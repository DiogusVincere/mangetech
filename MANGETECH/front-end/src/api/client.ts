// src/api/client.ts
import axios from 'axios'

// ===== CONFIGURAÇÃO BASE DO AXIOS =====
const api = axios.create({
  baseURL: 'https://gothan-tech-dfcqa4daf2d4a3ax.westus3-01.azurewebsites.net/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// ===== INTERCEPTOR: Adicionar token em todas as requisições =====
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Token ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// ===== INTERCEPTOR: Tratar erros globalmente =====
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token inválido ou expirado
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(error)
  }
)

// ===== TASKS API (CHAMADOS) =====
export const tasksApi = {
  // Listar todos os chamados
  async getAll(filters?: any) {
    const params = new URLSearchParams()
    if (filters?.search) params.append('search', filters.search)
    if (filters?.status) params.append('status', filters.status)
    if (filters?.urgencia) params.append('urgencia', filters.urgencia)
    if (filters?.solicitante) params.append('solicitante', filters.solicitante)
    if (filters?.data_inicio) params.append('data_criacao_after', filters.data_inicio)
    if (filters?.data_fim) params.append('data_criacao_before', filters.data_fim)
    
    const response = await api.get(`/chamados/?${params.toString()}`)
    return response.data
  },

  // Buscar chamado por ID
  async getById(id: number | string) {
    const response = await api.get(`/chamados/${id}/`)
    return response.data
  },

  // Criar novo chamado
  async create(taskData: any) {
    const response = await api.post('/chamados/', taskData)
    return response.data
  },

  // Atualizar chamado
  async update(id: number | string, taskData: any) {
    const response = await api.patch(`/chamados/${id}/`, taskData)
    return response.data
  },

  // Deletar chamado
  async delete(id: number | string) {
    const response = await api.delete(`/chamados/${id}/`)
    return response.data
  },

  // Mudar status do chamado (com FormData para fotos)
  async changeStatus(id: number | string, formData: FormData) {
    const response = await api.post(`/chamados/${id}/mudar_status/`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },

  // Adicionar comentário (com FormData para fotos)
  async addComment(id: number | string, formData: FormData) {
    const response = await api.post(`/chamados/${id}/adicionar_comentario/`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },

  // Adicionar anexo
  async addAttachment(id: number | string, file: File) {
    const formData = new FormData()
    formData.append('arquivo', file)
    
    const response = await api.post(`/chamados/${id}/adicionar_anexo/`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    return response.data
  },

  // Buscar estatísticas
  async getStatistics() {
    const response = await api.get('/chamados/estatisticas/')
    return response.data
  },

  // Buscar estatísticas filtradas
  async getFilteredStatistics(filters?: any) {
    const params = new URLSearchParams()
    if (filters?.status) params.append('status', filters.status)
    if (filters?.urgencia) params.append('urgencia', filters.urgencia)
    
    const response = await api.get(`/chamados/estatisticas_filtradas/?${params.toString()}`)
    return response.data
  },

  // Exportar CSV
  async exportCSV(filters?: any) {
    const params = new URLSearchParams()
    if (filters?.search) params.append('search', filters.search)
    if (filters?.status) params.append('status', filters.status)
    if (filters?.urgencia) params.append('urgencia', filters.urgencia)
    
    const response = await api.get(`/chamados/export/?${params.toString()}`, {
      responseType: 'blob'
    })
    return response.data
  },

  // Deletar múltiplos chamados
  async bulkDelete(ids: number[]) {
    const response = await api.post('/chamados/bulk-delete/', { ids })
    return response.data
  }
}

// ===== ASSETS API (ATIVOS) =====
export const assetsApi = {
  // Listar todos os ativos
  async getAll(filters?: any) {
    const params = new URLSearchParams()
    if (filters?.search) params.append('search', filters.search)
    if (filters?.status) params.append('status', filters.status)
    
    const response = await api.get(`/ativos/?${params.toString()}`)
    return response.data
  },

  // Buscar ativo por ID
  async getById(id: number | string) {
    const response = await api.get(`/ativos/${id}/`)
    return response.data
  },

  // Criar novo ativo
  async create(assetData: any) {
    const response = await api.post('/ativos/', assetData)
    return response.data
  },

  // Atualizar ativo
  async update(id: number | string, assetData: any) {
    const response = await api.patch(`/ativos/${id}/`, assetData)
    return response.data
  },

  // Deletar ativo
  async delete(id: number | string) {
    const response = await api.delete(`/ativos/${id}/`)
    return response.data
  },

  // Buscar chamados relacionados ao ativo
  async getTasks(id: number | string) {
    const response = await api.get(`/ativos/${id}/chamados/`)
    return response.data.chamados || []
  },

  // Gerar QR Code do ativo
  async getQRCode(id: number | string) {
    const response = await api.get(`/ativos/${id}/qr-code/`)
    return response.data
  },

  // Adicionar histórico ao ativo
  async addHistory(id: number | string, tipo: string, descricao: string) {
    const response = await api.post(`/ativos/${id}/adicionar_historico/`, {
      tipo,
      descricao
    })
    return response.data
  },

  // Buscar ativo por QR Code
  async getByQRCode(codigo: string) {
    const response = await api.get(`/ativos/${codigo}/por_qrcode/`)
    return response.data
  }
}

// ===== AUTH API (AUTENTICAÇÃO) =====
export const authApi = {
  // Login
  async login(email: string, senha: string) {
    const response = await api.post('/auth/login/', { email, senha })
    return response.data
  },

  // Registro
  async register(nome: string, email: string, senha: string) {
    const response = await api.post('/auth/register/', { nome, email, senha })
    return response.data
  },

  // Logout
  async logout() {
    const response = await api.post('/auth/logout/')
    return response.data
  },

  // Solicitar recuperação de senha
  async requestPasswordReset(email: string) {
    const response = await api.post('/auth/solicitar-recuperacao-senha/', { email })
    return response.data
  },

  // Verificar token de recuperação
  async verifyResetToken(email: string, token: string) {
    const response = await api.post('/auth/verificar-token-recuperacao/', { email, token })
    return response.data
  },

  // Resetar senha
  async resetPassword(email: string, token: string, nova_senha: string, confirmar_senha: string) {
    const response = await api.post('/auth/resetar-senha/', {
      email,
      token,
      nova_senha,
      confirmar_senha
    })
    return response.data
  },

  // Verificar email
  async verifyEmail(email: string) {
    const response = await api.post('/auth/verificar-email/', { email })
    return response.data
  }
}

// ===== USER API (PERFIL DO USUÁRIO) =====
export const userApi = {
  // Buscar perfil
  async getProfile() {
    const response = await api.get('/perfil/')
    return response.data
  },

  // Atualizar perfil
  async updateProfile(data: any) {
    const response = await api.put('/perfil/atualizar/', data)
    return response.data
  },

  // Alterar senha
  async changePassword(senha_atual: string, nova_senha: string, confirmar_senha: string) {
    const response = await api.post('/perfil/alterar-senha/', {
      senha_atual,
      nova_senha,
      confirmar_senha
    })
    return response.data
  },

  // Buscar estatísticas do usuário
  async getStatistics() {
    const response = await api.get('/perfil/estatisticas/')
    return response.data
  },

  // Listar todos os usuários
  async getAll(search?: string) {
    const params = search ? `?search=${search}` : ''
    const response = await api.get(`/usuarios/${params}`)
    return response.data
  },

  // Buscar usuário atual (me)
  async getMe() {
    const response = await api.get('/usuarios/me/')
    return response.data
  },
 
  // ADICIONE ISTO TAMBÉM (Atalho para estatísticas)
  
}

// ===== DASHBOARD API =====
export const dashboardApi = {
  async getManagerialData() {
    const response = await api.get('/dashboard/gerencial/')
    return response.data
  }
}

// ===== COMMENTS API (COMENTÁRIOS) =====
export const commentsApi = {
  async getAll(chamadoId?: number) {
    const params = chamadoId ? `?chamado=${chamadoId}` : ''
    const response = await api.get(`/comentarios/${params}`)
    return response.data
  },

  async getById(id: number) {
    const response = await api.get(`/comentarios/${id}/`)
    return response.data
  }
}

// Exportar instância do axios como default
export default api
