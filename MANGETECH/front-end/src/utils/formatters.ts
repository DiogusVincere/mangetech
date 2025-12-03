// src/utils/formatters.ts
import type { User } from '@/types'

/**
 * Formata data no padrão brasileiro
 * @param dateString - String de data ISO
 * @returns Data formatada (ex: "28/11/2025 14:30")
 */
export const formatDate = (dateString: string): string => {
  if (!dateString) return '-'
  
  const date = new Date(dateString)
  
  if (isNaN(date.getTime())) return '-'
  
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const year = date.getFullYear()
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  
  return `${day}/${month}/${year} ${hours}:${minutes}`
}

/**
 * Formata data sem hora
 * @param dateString - String de data ISO
 * @returns Data formatada (ex: "28/11/2025")
 */
export const formatDateOnly = (dateString: string): string => {
  if (!dateString) return '-'
  
  const date = new Date(dateString)
  
  if (isNaN(date.getTime())) return '-'
  
  const day = date.getDate().toString().padStart(2, '0')
  const month = (date.getMonth() + 1).toString().padStart(2, '0')
  const year = date.getFullYear()
  
  return `${day}/${month}/${year}`
}

/**
 * Formata hora
 * @param dateString - String de data ISO
 * @returns Hora formatada (ex: "14:30")
 */
export const formatTime = (dateString: string): string => {
  if (!dateString) return '-'
  
  const date = new Date(dateString)
  
  if (isNaN(date.getTime())) return '-'
  
  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')
  
  return `${hours}:${minutes}`
}

/**
 * Formata data relativa (ex: "há 2 horas")
 * @param dateString - String de data ISO
 * @returns Data relativa
 */
export const formatRelativeDate = (dateString: string): string => {
  if (!dateString) return '-'
  
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMs / 3600000)
  const diffDays = Math.floor(diffMs / 86400000)
  
  if (diffMins < 1) return 'agora'
  if (diffMins === 1) return 'há 1 minuto'
  if (diffMins < 60) return `há ${diffMins} minutos`
  if (diffHours === 1) return 'há 1 hora'
  if (diffHours < 24) return `há ${diffHours} horas`
  if (diffDays === 1) return 'ontem'
  if (diffDays < 7) return `há ${diffDays} dias`
  if (diffDays < 30) return `há ${Math.floor(diffDays / 7)} semanas`
  if (diffDays < 365) return `há ${Math.floor(diffDays / 30)} meses`
  return `há ${Math.floor(diffDays / 365)} anos`
}

/**
 * Obtém iniciais de um nome ou usuário
 * @param userOrName - Objeto User ou string com nome
 * @returns Iniciais (ex: "JS" para "João Silva")
 */
export const getInitials = (userOrName: User | string): string => {
  let name: string
  
  // Se for um objeto User
  if (typeof userOrName === 'object' && userOrName !== null) {
    const user = userOrName as User
    const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim()
    name = fullName || user.username || user.email || 'U'
  } else {
    // Se for uma string
    name = (userOrName as string) || 'U'
  }
  
  // Extrair iniciais
  const parts = name.split(' ').filter(n => n.length > 0)
  
  if (parts.length === 0) return 'U'
  if (parts.length === 1) return parts[0]!.substring(0, 2).toUpperCase()
  
  const first = parts[0]!.charAt(0)
  const last = parts[parts.length - 1]!.charAt(0)
  
  return `${first}${last}`.toUpperCase()
}

/**
 * Formata nome completo
 * @param user - Objeto User
 * @returns Nome completo ou username
 */
export const getFullName = (user: User): string => {
  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim()
  return fullName || user.username || user.email || 'Usuário'
}

/**
 * Formata número como moeda brasileira
 * @param value - Valor numérico
 * @returns Valor formatado (ex: "R$ 1.234,56")
 */
export const formatCurrency = (value: number): string => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

/**
 * Formata número com separadores
 * @param value - Valor numérico
 * @returns Número formatado (ex: "1.234")
 */
export const formatNumber = (value: number): string => {
  return new Intl.NumberFormat('pt-BR').format(value)
}

/**
 * Trunca texto longo
 * @param text - Texto a truncar
 * @param maxLength - Comprimento máximo
 * @returns Texto truncado com "..."
 */
export const truncateText = (text: string, maxLength: number = 50): string => {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

/**
 * Mascara email (ex: j***@gmail.com)
 * @param email - Email a mascarar
 * @returns Email mascarado
 */
export const maskEmail = (email: string): string => {
  const parts = email.split('@')
  const user = parts[0] ?? ''
  const domain = parts[1] ?? ''
  
  if (!user || !domain) return email
  if (user.length <= 2) return `${user}@${domain}`
  
  return `${user[0]}${'*'.repeat(Math.max(0, user.length - 2))}${user[user.length - 1]}@${domain}`
}

/**
 * Formata telefone brasileiro
 * @param phone - Telefone a formatar
 * @returns Telefone formatado
 */
export const formatPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '')
  
  if (cleaned.length === 11) {
    return cleaned.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3')
  }
  
  if (cleaned.length === 10) {
    return cleaned.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3')
  }
  
  return phone
}

/**
 * Formata CPF
 * @param cpf - CPF a formatar
 * @returns CPF formatado
 */
export const formatCPF = (cpf: string): string => {
  const cleaned = cpf.replace(/\D/g, '')
  return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
}

/**
 * Formata tamanho de arquivo
 * @param bytes - Tamanho em bytes
 * @returns Tamanho formatado (ex: "1.5 MB")
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes'
  
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

/**
 * Pluraliza palavra baseado em quantidade
 * @param count - Quantidade
 * @param singular - Palavra no singular
 * @param plural - Palavra no plural (opcional)
 * @returns Palavra pluralizada
 */
export const pluralize = (count: number, singular: string, plural?: string): string => {
  if (count === 1) return singular
  return plural || `${singular}s`
}