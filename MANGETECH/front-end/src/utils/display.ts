// src/utils/display.ts — rótulos, cores e datas usados em várias telas
import type { User } from '@/types'

export const STATUS_OPTIONS = [
  { value: 'ABERTO', label: 'Aberto' },
  { value: 'AGUARDANDO RESP', label: 'Aguardando responsáveis' },
  { value: 'EM ANDAMENTO', label: 'Em andamento' },
  { value: 'REALIZADO', label: 'Realizado' },
  { value: 'CONCLUÍDO', label: 'Concluído' },
  { value: 'CANCELADO', label: 'Cancelado' },
] as const

export const URGENCIA_OPTIONS = ['Crítico', 'Alta', 'Média', 'Baixa'] as const
export const ASSET_STATUS_OPTIONS = ['Ativo', 'Manutenção', 'Inativo'] as const

export function statusLabel(status: string) {
  return STATUS_OPTIONS.find((s) => s.value === status)?.label || status
}

export function statusClass(status: string) {
  const classes: Record<string, string> = {
    'ABERTO': 'bg-blue-100 text-blue-800',
    'AGUARDANDO RESP': 'bg-yellow-100 text-yellow-800',
    'EM ANDAMENTO': 'bg-purple-100 text-purple-800',
    'REALIZADO': 'bg-cyan-100 text-cyan-800',
    'CONCLUÍDO': 'bg-green-100 text-green-800',
    'CANCELADO': 'bg-gray-200 text-gray-700',
  }
  return classes[status] || 'bg-gray-100 text-gray-700'
}

export function priorityClass(priority: string) {
  const classes: Record<string, string> = {
    'Crítico': 'bg-red-100 text-red-800 border border-red-200',
    'Alta': 'bg-orange-100 text-orange-800 border border-orange-200',
    'Média': 'bg-yellow-100 text-yellow-800 border border-yellow-200',
    'Baixa': 'bg-green-100 text-green-800 border border-green-200',
  }
  return classes[priority] || 'bg-gray-100 text-gray-700'
}

export function assetStatusClass(status: string) {
  const classes: Record<string, string> = {
    'Ativo': 'bg-green-100 text-green-800',
    'Inativo': 'bg-gray-200 text-gray-700',
    'Manutenção': 'bg-yellow-100 text-yellow-800',
  }
  return classes[status] || 'bg-gray-100 text-gray-700'
}

function toDate(value?: string | null) {
  if (!value) return null
  // Datas sem hora (AAAA-MM-DD) são locais, não UTC.
  const d = /^\d{4}-\d{2}-\d{2}$/.test(value) ? new Date(`${value}T00:00:00`) : new Date(value)
  return isNaN(d.getTime()) ? null : d
}

export function formatDate(value?: string | null, fallback = '—') {
  const d = toDate(value)
  return d ? d.toLocaleDateString('pt-BR') : fallback
}

export function formatDateTime(value?: string | null, fallback = '—') {
  const d = toDate(value)
  return d
    ? `${d.toLocaleDateString('pt-BR')} ${d.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}`
    : fallback
}

export function timeAgo(value?: string | null) {
  const d = toDate(value)
  if (!d) return ''
  const segundos = Math.round((Date.now() - d.getTime()) / 1000)
  if (segundos < 60) return 'agora há pouco'
  const minutos = Math.round(segundos / 60)
  if (minutos < 60) return `há ${minutos} min`
  const horas = Math.round(minutos / 60)
  if (horas < 24) return `há ${horas} h`
  const dias = Math.round(horas / 24)
  if (dias < 30) return `há ${dias} dia${dias > 1 ? 's' : ''}`
  return formatDate(value)
}

/** Converte data da API para o valor de um <input type="datetime-local">. */
export function toDateTimeLocal(value?: string | null) {
  const d = toDate(value)
  if (!d) return ''
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

export function formatMoney(value?: string | number | null) {
  if (value === null || value === undefined || value === '') return '—'
  return Number(value).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

export function fullName(user?: Partial<User> | null) {
  if (!user) return ''
  return `${user.first_name || ''} ${user.last_name || ''}`.trim() || user.nome || user.username || user.email || ''
}

export function initials(user?: Partial<User> | null) {
  if (!user) return '?'
  if (user.first_name && user.last_name) return `${user.first_name[0]}${user.last_name[0]}`.toUpperCase()
  return (fullName(user) || '?').substring(0, 2).toUpperCase()
}

export function roleLabel(user?: Partial<User> | null) {
  if (!user) return ''
  if (user.is_superuser) return 'Superusuário'
  if (user.is_staff) return 'Administrador'
  return 'Usuário'
}
