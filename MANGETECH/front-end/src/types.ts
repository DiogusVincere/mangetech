// src/types.ts — formatos que a API devolve

export interface User {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  nome?: string
  is_staff: boolean
  is_superuser: boolean
  is_active?: boolean
  date_joined?: string
  last_login?: string | null
}

export type TaskStatus = 'ABERTO' | 'AGUARDANDO RESP' | 'EM ANDAMENTO' | 'REALIZADO' | 'CONCLUÍDO' | 'CANCELADO'
export type Urgencia = 'Crítico' | 'Alta' | 'Média' | 'Baixa'

export interface Foto {
  id: number
  imagem: string
  url: string | null
  data_upload: string
}

export interface TaskHistory {
  id: number
  status: string
  descricao: string
  usuario?: number | null
  usuario_nome?: string
  timestamp: string
  data_criacao: string
  fotos?: Foto[]
}

export interface Comentario {
  id: number
  chamado: number
  autor?: number | null
  usuario_nome?: string
  texto: string
  timestamp: string
  data_criacao: string
  fotos?: Foto[]
}

export interface Anexo {
  id: number
  arquivo: string
  url: string | null
  nome_original: string
  data_upload: string
}

export interface AssetSummary {
  id: number
  codigo: string
  nome: string
  ambiente: string
  status: Asset['status']
}

export interface Task {
  id: string
  titulo: string
  descricao: string
  ativo: string
  ativo_ref?: number | null
  ativo_detalhes?: AssetSummary | null
  ambiente: string
  urgencia: Urgencia
  status: TaskStatus
  data_criacao: string
  data_sugerida?: string | null
  data_atualizacao?: string
  atrasado?: boolean
  solicitante?: number | null
  solicitante_nome?: string | null
  solicitante_email?: string | null
  responsaveis?: number[]
  responsaveis_detalhes?: User[]
  responsaveis_nomes?: string[]
  historico?: TaskHistory[]
  comentarios?: Comentario[]
  anexos_detalhes?: Anexo[]
}

export interface Page<T> {
  count: number
  next: string | null
  previous: string | null
  results: T[]
}

export interface AssetHistory {
  id: number
  tipo: string
  descricao: string
  data_criacao: string
  usuario_nome?: string
}

export interface Asset {
  id: number
  codigo: string
  nome: string
  modelo: string
  fabricante: string
  numero_serie: string
  fornecedor: string
  ambiente: string
  status: 'Ativo' | 'Inativo' | 'Manutenção'
  data_aquisicao?: string | null
  valor?: string | null
  garantia_meses?: number | null
  garantia_ate?: string | null
  em_garantia?: boolean | null
  observacoes?: string
  data_cadastro?: string
  data_atualizacao?: string
  total_chamados?: number
  chamados_abertos?: number
  ultimo_chamado?: { id: string; titulo: string; status: string; data: string } | null
  historico_movimentacoes?: AssetHistory[]
}

export interface AssetTask {
  id: string
  titulo: string
  status: TaskStatus
  urgencia: Urgencia
  data_criacao: string
  solicitante_nome?: string | null
  responsaveis_nomes?: string[]
}

export interface Activity {
  tipo: 'status' | 'comentario'
  status: string | null
  texto: string
  chamado_id: number
  chamado_titulo: string
  data: string
}

export interface UserStats {
  total_chamados: number
  chamados_solicitados: number
  chamados_responsavel: number
  chamados_ativos: number
  chamados_concluidos: number
  por_status: { status: string; total: number }[]
  por_urgencia: { urgencia: string; total: number }[]
  atividades_recentes: Activity[]
}

export interface DashboardData {
  kpis: {
    total_chamados: number
    abertos: number
    em_andamento: number
    aguardando: number
    realizado: number
    concluido: number
    cancelado: number
    criticos_abertos: number
    atrasados: number
    tempo_medio: string
    tempo_medio_horas: number | null
    taxa_resolucao: number
    no_prazo_percentual: number | null
  }
  por_status: Record<string, number>
  por_urgencia: Record<string, number>
  periodo: {
    ultimos_7_dias: number
    ultimos_30_dias: number
    ultimos_90_dias: number
  }
  tempo_resolucao: Record<string, number>
  criticos: Task[]
  ativos: {
    total: number
    ativos: number
    manutencao: number
    inativos: number
    mais_chamados: { id: number; codigo: string; nome: string; status: string; total_chamados: number }[]
  }
}
