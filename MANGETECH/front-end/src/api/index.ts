// src/api/index.ts - VERSÃO CORRIGIDA COMPLETA
import api from './client'
import type { User, Task, Asset, DashboardData } from '@/types'

// ============================================
// AUTH API
// ============================================
export const authApi = {
  async login(email: string, password: string) {
    const { data } = await api.post('/auth/login/', { 
      email, 
      senha: password 
    })
    return data
  },

  async register(name: string, email: string, password: string) {
    const { data } = await api.post('/auth/register/', { 
      nome: name, 
      email, 
      senha: password 
    })
    return data
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

  async verifyResetToken(token: string) {
    const { data } = await api.post('/auth/verificar-token-recuperacao/', { token })
    return data
  },

  async resetPassword(token: string, password: string) {
    const { data } = await api.post('/auth/resetar-senha/', { token, senha: password })
    return data
  },
}

// ============================================
// TASKS API
// ============================================
export const tasksApi = {
  async getAll(filters?: any) {
    console.log(' tasksApi.getAll - Iniciando requisição...')
    console.log('Filtros:', filters)
    
    const { data } = await api.get('/chamados/', { params: filters })
    
    console.log('Resposta recebida:', data)
    console.log('Tipo da resposta:', Array.isArray(data) ? 'Array' : typeof data)
    
    // Normalizar resposta: pode vir como array direto ou paginado
    let tasks = Array.isArray(data) ? data : (data.results || [])
    
    console.log('Total de tasks antes da conversão:', tasks.length)
    
    // Converter IDs para string para consistência
    tasks = tasks.map((task: any) => {
      const converted = {
        ...task,
        id: String(task.id) // Garante que ID é sempre string no frontend
      }
      console.log(`🔄 Task ${task.id} convertida:`, converted)
      return converted
    })
    
    console.log('Tasks após conversão:', tasks.length)
    console.log('Primeira task processada:', tasks[0])
    
    return tasks
  },

  async getById(id: number | string) {
    console.log('tasksApi.getById - ID recebido:', id, 'tipo:', typeof id)
    
    // CORRIGIDO: Adicionar barra final
    const { data } = await api.get(`/chamados/${id}/`)
    
    console.log('Task recebida do backend:', data)
    
    // Converter ID para string
    const converted = {
      ...data,
      id: String(data.id)
    } as Task
    
    console.log('Task após conversão:', converted)
    
    return converted
  },

  async create(task: any) {
    console.log('tasksApi.create - Criando task:', task)
    
    const { data } = await api.post('/chamados/', task)
    
    console.log('Task criada:', data)
    
    // Converter ID para string
    const converted = {
      ...data,
      id: String(data.id)
    } as Task
    
    console.log('Task após conversão:', converted)
    
    return converted
  },

  // addComment - FormData
  async addComment(id: number | string, payload: { texto: string } | FormData) {
    console.log('tasksApi.addComment - ID:', id, 'Payload:', payload)
    
    const isFormData = payload instanceof FormData
    
    // CORRIGIDO: Adicionar barra final
    const { data } = await api.post(`/chamados/${id}/adicionar_comentario/`, payload, {
      headers: isFormData ? { 'Content-Type': 'multipart/form-data' } : {}
    })
    
    console.log('Comentário adicionado:', data)
    
    return data
  },

  // changeStatus - FormData
  async changeStatus(id: number | string, payload: { status: string; descricao: string } | FormData) {
    console.log('tasksApi.changeStatus - ID:', id, 'Payload:', payload)
    
    const isFormData = payload instanceof FormData
    
    // CORRIGIDO: Adicionar barra final
    const { data } = await api.post(`/chamados/${id}/mudar_status/`, payload, {
      headers: isFormData ? { 'Content-Type': 'multipart/form-data' } : {}
    })
    
    console.log('Status alterado:', data)
    
    return data
  },

  // Versão alternativa com parâmetros separados
  async updateStatus(id: number | string, status: string, descricao: string, fotos?: File[]) {
    console.log('tasksApi.updateStatus - ID:', id, 'Status:', status)
    
    const formData = new FormData()
    formData.append('status', status)
    formData.append('descricao', descricao)
    
    if (fotos && fotos.length > 0) {
      fotos.forEach(foto => formData.append('fotos', foto))
    }
    
    // CORRIGIDO: Adicionar barra final
    const { data } = await api.post(`/chamados/${id}/mudar_status/`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    
    console.log('Status atualizado:', data)
    
    return {
      ...data,
      id: String(data.id)
    } as Task
  },

  // addAttachment
  async addAttachment(id: number | string, arquivo: File) {
    console.log('tasksApi.addAttachment - ID:', id)
    
    const formData = new FormData()
    formData.append('arquivo', arquivo)
    
    // CORRIGIDO: Adicionar barra final
    const { data } = await api.post(`/chamados/${id}/adicionar_anexo/`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    
    console.log('Anexo adicionado:', data)
    
    return data
  },

  // Estatísticas
  async getStatistics() {
    const { data } = await api.get('/chamados/estatisticas/')
    return data
  },

  // Bulk delete
  async bulkDelete(ids: (number | string)[]) {
    console.log('tasksApi.bulkDelete - IDs originais:', ids)
    
    // Converter para números antes de enviar
    const numericIds = ids.map(id => {
      const num = typeof id === 'string' ? parseInt(id, 10) : id
      console.log(`Convertendo ${id} (${typeof id}) para ${num} (${typeof num})`)
      return num
    })
    
    console.log('IDs numéricos:', numericIds)
    
    const { data } = await api.post('/chamados/bulk-delete/', { ids: numericIds })
    
    console.log('Resultado:', data)
    
    return data
  },

  // Export CSV
  async exportCSV(filters?: any) {
    const { data } = await api.get('/chamados/export/', { 
      params: filters,
      responseType: 'blob'
    })
    return data
  },
}


// ===== ATIVOS API ===== 
// VERSÃO CORRIGIDA
export const assetsApi = {
  async getAll(filters?: any) {
    console.log('assetsApi.getAll - Buscando ativos...')
    console.log('Filtros:', filters)
    
    const { data } = await api.get('/ativos/', { params: filters })
    
    console.log('Resposta recebida:', data)
    console.log('Tipo:', Array.isArray(data) ? 'Array' : typeof data)
    
    // Normalizar resposta
    const assets = Array.isArray(data) ? data : (data.results || [])
    
    console.log('Total de ativos:', assets.length)
    console.log(' Primeiro ativo:', assets[0])
    
    return assets
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
  }
}
// ============================================
// USERS API
// ============================================
// src/api/client.ts (ou index.ts)

// ...

// ============================================
// USERS API
// ============================================
export const usersApi = {
  async getAll(filters?: any) {
    console.log('usersApi.getAll - Buscando usuários...')
    const { data } = await api.get('/usuarios/', { params: filters })
    const users = Array.isArray(data) ? data : (data.results || [])
    console.log('Usuários carregados:', users.length)
    return users
  },

  async getById(id: number | string) {
    console.log('usersApi.getById - ID:', id)
    const { data } = await api.get(`/usuarios/${id}/`)
    console.log('Usuário carregado:', data)
    return data as User
  },

  // --- ADICIONE ESTA FUNÇÃO QUE ESTAVA FALTANDO ---
  async update(id: number | string, data: any) {
    console.log('usersApi.update - ID:', id, 'Data:', data)
    const response = await api.patch(`/usuarios/${id}/`, data)
    return response.data
  },
  // ------------------------------------------------

  async getStatistics(id: number | string) {
    console.log('usersApi.getStatistics - ID:', id)
    try {
      const { data } = await api.get(`/usuarios/${id}/estatisticas/`)
      console.log('Estatísticas carregadas:', data)
      return data
    } catch (error: any) {
      console.error('Erro ao buscar estatísticas:', error)
      
      // Se o endpoint não existir ainda (404), retorna dados vazios
      if (error.response?.status === 404) {
        return {
          success: true,
          data: {
            total_chamados: 0,
            chamados_solicitados: 0,
            chamados_responsavel: 0,
            chamados_ativos: 0,
            por_status: [],
            por_urgencia: []
          }
        }
      }
      throw error
    }
  },
}

// ============================================
// PROFILE API
// ============================================
export const profileApi = {
  async get() {
    const { data } = await api.get('/perfil/')
    return data.data
  },

  async update(profileData: any) {
    const { data } = await api.put('/perfil/atualizar/', profileData)
    return data
  },

  async changePassword(oldPassword: string, newPassword: string, confirmPassword: string) {
    const { data } = await api.post('/perfil/alterar-senha/', {
      senha_atual: oldPassword,
      nova_senha: newPassword,
      confirmar_senha: confirmPassword
    })
    return data
  },

  async getStatistics() {
    const { data } = await api.get('/perfil/estatisticas/')
    return data.data
  },
}

// ============================================
// DASHBOARD API
// ============================================
export const dashboardApi = {
  async getIndicators(filters?: any) {
    const { data } = await api.get('/dashboard/gerencial/', { params: filters })
    return data.data as DashboardData
  },
}

export default api