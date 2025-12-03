// src/types/index.ts - CORRIGIDO COM CAMPOS FALTANTES

export interface User {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  is_staff: boolean
  is_superuser: boolean 
  is_active?: boolean
  date_joined?: string
}

export interface Task {
  id: number | string
  titulo: string
  descricao: string
  ativo: string
  ambiente: string
  urgencia: 'Crítico' | 'Alta' | 'Média' | 'Baixa'
  status: 'ABERTO' | 'AGUARDANDO RESP' | 'EM ANDAMENTO' | 'REALIZADO' | 'CONCLUÍDO' | 'CANCELADO'
  data_criacao: string
  data_sugerida?: string
  data_atualizacao?: string
  solicitante?: User
  solicitante_nome?: string
  solicitante_email?: string
  responsaveis?: User[]
  responsaveis_detalhes?: User[]
  responsaveis_nomes?: string[]
  historico?: TaskHistory[]
  comentarios?: Comentario[]
  anexos_detalhes?: Anexo[]
}

export interface TaskHistory {
  id: number
  status: string
  to_status?: string
  from_status?: string
  descricao: string
  usuario?: User
  usuario_nome?: string
  timestamp: string
  data_criacao: string
  fotos?: string[]
}

export interface Comentario {
  id: number
  chamado: number
  autor?: User
  usuario_nome?: string
  texto: string
  timestamp: string
  data_criacao: string
}

export interface Anexo {
  id: number
  arquivo: string
  url: string
  nome_original: string
  data_upload: string
}

// ASSET - CORRIGIDO COM CAMPOS FALTANTES
export interface Asset {
  id: number
  codigo: string
  nome: string
  modelo: string
  fabricante: string
  numero_serie: string
  fornecedor?: string
  ambiente: string
  status: 'Ativo' | 'Inativo' | 'Manutenção'
  
  // CAMPOS ADICIONADOS:
  data_aquisicao?: string // Para CreateAssetView
  valor?: number // Para CreateAssetView
  garantia_meses?: number // Para CreateAssetView e AssetDetailView
  observacoes?: string // Para CreateAssetView e AssetDetailView
  
  // Campos de controle
  data_cadastro?: string
  data_criacao?: string // Alias para data_cadastro (usado em AssetDetailView)
  data_atualizacao?: string
  
  // Estatísticas
  total_chamados?: number
  chamados_abertos?: number
  
  ultimo_chamado?: {
    id: string
    titulo: string
    status: string
    data: string
  }
  
  historico_movimentacoes?: Array<{
    id: number
    tipo: string
    descricao: string
    data_criacao: string
    usuario_nome?: string
  }>
}

export interface DashboardData {
  kpis: {
    total_chamados: number
    abertos: number
    em_andamento: number
    aguardando?: number
    realizado?: number
    concluido: number
    cancelado?: number
    criticos_abertos: number
    tempo_medio: string
  }
  por_status: Record<string, number>
  por_urgencia: Record<string, number>
  periodo?: {
    ultimos_7_dias: number
    ultimos_30_dias: number
    ultimos_90_dias: number
  }
  tempo_resolucao?: Record<string, number>
  criticos?: Task[]
}