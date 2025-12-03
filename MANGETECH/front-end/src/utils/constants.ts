// src/utils/constants.ts

// Status de chamados
export const TASK_STATUS = {
  ABERTO: 'ABERTO',
  AGUARDANDO_RESP: 'AGUARDANDO RESP',
  EM_ANDAMENTO: 'EM ANDAMENTO',
  REALIZADO: 'REALIZADO',
  CONCLUIDO: 'CONCLUÍDO',
  CANCELADO: 'CANCELADO',
} as const

export const TASK_STATUS_LABELS: Record<string, string> = {
  [TASK_STATUS.ABERTO]: 'Aberto',
  [TASK_STATUS.AGUARDANDO_RESP]: 'Aguardando Responsáveis',
  [TASK_STATUS.EM_ANDAMENTO]: 'Em Andamento',
  [TASK_STATUS.REALIZADO]: 'Realizado',
  [TASK_STATUS.CONCLUIDO]: 'Concluído',
  [TASK_STATUS.CANCELADO]: 'Cancelado',
}

// Prioridades/Urgências
export const PRIORITY = {
  CRITICO: 'Crítico',
  ALTA: 'Alta',
  MEDIA: 'Média',
  BAIXA: 'Baixa',
} as const

export const PRIORITY_LABELS: Record<string, string> = {
  [PRIORITY.CRITICO]: 'Crítico',
  [PRIORITY.ALTA]: 'Alta',
  [PRIORITY.MEDIA]: 'Média',
  [PRIORITY.BAIXA]: 'Baixa',
}

// Status de ativos
export const ASSET_STATUS = {
  ATIVO: 'Ativo',
  INATIVO: 'Inativo',
  MANUTENCAO: 'Manutenção',
} as const

export const ASSET_STATUS_LABELS: Record<string, string> = {
  [ASSET_STATUS.ATIVO]: 'Ativo',
  [ASSET_STATUS.INATIVO]: 'Inativo',
  [ASSET_STATUS.MANUTENCAO]: 'Em Manutenção',
}

// Roles de usuário
export const USER_ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  TECHNICIAN: 'technician',
  REQUESTER: 'requester',
} as const

export const USER_ROLE_LABELS: Record<string, string> = {
  [USER_ROLES.ADMIN]: 'Administrador',
  [USER_ROLES.MANAGER]: 'Gerente',
  [USER_ROLES.TECHNICIAN]: 'Técnico',
  [USER_ROLES.REQUESTER]: 'Solicitante',
}

// Tamanhos de arquivo
export const FILE_SIZE_LIMITS = {
  IMAGE: 10, // MB
  DOCUMENT: 10, // MB
  VIDEO: 50, // MB
} as const

// Tipos de arquivo aceitos
export const ACCEPTED_FILE_TYPES = {
  IMAGE: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
  DOCUMENT: ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  EXCEL: ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
} as const

// Paginação
export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 50,
  PAGE_SIZE_OPTIONS: [10, 25, 50, 100],
} as const

// Tempos de debounce/throttle
export const TIMING = {
  DEBOUNCE_SEARCH: 300, // ms
  DEBOUNCE_INPUT: 500, // ms
  THROTTLE_SCROLL: 200, // ms
  TOAST_DURATION: 5000, // ms
} as const

// Cores do tema
export const THEME_COLORS = {
  primary: '#2563eb',
  secondary: '#64748b',
  success: '#10b981',
  warning: '#f59e0b',
  error: '#ef4444',
  info: '#3b82f6',
} as const

// API Endpoints (relativos à baseURL)
export const API_ENDPOINTS = {
  AUTH: {
    LOGIN: '/auth/login/',
    REGISTER: '/auth/register/',
    LOGOUT: '/auth/logout/',
    ME: '/usuarios/me/',
    FORGOT_PASSWORD: '/auth/recuperar-senha/',
  },
  TASKS: {
    LIST: '/chamados/',
    DETAIL: (id: string | number) => `/chamados/${id}/`,
    CREATE: '/chamados/',
    UPDATE_STATUS: (id: string | number) => `/chamados/${id}/mudar_status/`,
    ADD_COMMENT: (id: string | number) => `/chamados/${id}/adicionar_comentario/`,
    STATISTICS: '/chamados/estatisticas/',
  },
  ASSETS: {
    LIST: '/ativos/',
    DETAIL: (id: number) => `/ativos/${id}/`,
    CREATE: '/ativos/',
    QR_CODE: (id: number) => `/ativos/${id}/qr-code/`,
  },
  DASHBOARD: {
    GERENCIAL: '/dashboard/gerencial/',
  },
  USERS: {
    LIST: '/usuarios/',
    DETAIL: (id: number) => `/usuarios/${id}/`,
  },
} as const

// Mensagens de erro
export const ERROR_MESSAGES = {
  GENERIC: 'Ocorreu um erro. Tente novamente.',
  NETWORK: 'Erro de conexão. Verifique sua internet.',
  UNAUTHORIZED: 'Você não tem permissão para esta ação.',
  NOT_FOUND: 'Recurso não encontrado.',
  VALIDATION: 'Verifique os dados e tente novamente.',
} as const

// Mensagens de sucesso
export const SUCCESS_MESSAGES = {
  SAVED: 'Salvo com sucesso!',
  DELETED: 'Excluído com sucesso!',
  UPDATED: 'Atualizado com sucesso!',
  CREATED: 'Criado com sucesso!',
} as const