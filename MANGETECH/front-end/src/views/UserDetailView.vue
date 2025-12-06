<template>
  <div class="space-y-6">
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando usuário...</p>
    </div>

    <div v-else-if="error" class="bg-white rounded-xl border border-red-200 shadow-sm p-6">
      <div class="text-center py-8">
        <div class="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
          <AlertCircle :size="32" class="text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar usuário</h3>
        <p class="text-gray-600 mb-4">{{ error }}</p>
        <button
          @click="$router.push('/users')"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          Voltar para Usuários
        </button>
      </div>
    </div>

    <div v-else-if="user">
      <div class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
        <div class="px-6 py-4">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div class="flex-1">
              <div class="flex items-center gap-4 mb-2">
                <button @click="$router.push('/users')" class="p-2 hover:bg-gray-100 rounded-lg transition">
                  <ArrowLeft :size="20" class="text-gray-600" />
                </button>
                <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold text-2xl">
                  {{ getInitials(user) }}
                </div>
                <div>
                  <h1 class="text-2xl font-bold text-gray-900">{{ getFullName(user) }}</h1>
                  <p class="text-sm text-gray-500">{{ user.email }}</p>
                </div>
                
                <span v-if="user.is_superuser" class="px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 border border-red-200 flex items-center">
                  <Crown :size="14" class="mr-1" />
                  Super Admin
                </span>
                <span v-else-if="user.is_staff" class="px-3 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800 border border-purple-200 flex items-center">
                  <Wrench :size="14" class="mr-1" />
                  Técnico
                </span>
                <span v-else class="px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800 border border-blue-200 flex items-center">
                  <UserIcon :size="14" class="mr-1" />
                  Solicitante
                </span>
              </div>
            </div>
            
            <div class="flex items-center gap-3">
              <a :href="`mailto:${user.email}`" class="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium text-gray-700">
                <Mail :size="18" />
                Enviar Email
              </a>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div class="lg:col-span-8 space-y-6">
          
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-semibold text-gray-900">Estatísticas de Chamados</h3>
              <ClipboardList :size="20" class="text-gray-400" />
            </div>
            
            <div class="px-6 py-6 space-y-8">
              <div v-if="statsLoading" class="flex items-center justify-center py-8">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>

              <div v-else-if="stats">
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
                  <div class="text-center p-4 bg-blue-50 rounded-lg border border-blue-200">
                    <div class="text-3xl font-bold text-blue-600">{{ stats.total_chamados || 0 }}</div>
                    <div class="text-xs text-gray-600 mt-1 font-medium">Total</div>
                  </div>
                  <div class="text-center p-4 bg-green-50 rounded-lg border border-green-200">
                    <div class="text-3xl font-bold text-green-600">{{ stats.chamados_solicitados || 0 }}</div>
                    <div class="text-xs text-gray-600 mt-1 font-medium">Solicitados</div>
                  </div>
                  <div class="text-center p-4 bg-purple-50 rounded-lg border border-purple-200">
                    <div class="text-3xl font-bold text-purple-600">{{ stats.chamados_responsavel || 0 }}</div>
                    <div class="text-xs text-gray-600 mt-1 font-medium">Responsável</div>
                  </div>
                  <div class="text-center p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                    <div class="text-3xl font-bold text-yellow-600">{{ stats.chamados_ativos || 0 }}</div>
                    <div class="text-xs text-gray-600 mt-1 font-medium">Ativos</div>
                  </div>
                </div>

                <div class="mb-6">
                  <h4 class="text-sm font-semibold text-gray-900 mb-3">Chamados por Status</h4>
                  <div v-if="stats.por_status && stats.por_status.length > 0" class="space-y-3">
                    <div v-for="item in stats.por_status" :key="item.status" class="flex items-center justify-between bg-gray-50 px-4 py-3 rounded-lg border border-gray-100">
                      <span :class="['px-3 py-1 text-xs rounded-full font-bold uppercase tracking-wide', getStatusColor(item.status)]">
                        {{ item.status }}
                      </span>
                      <span class="text-lg font-bold text-gray-900">{{ item.total }}</span>
                    </div>
                  </div>
                  <p v-else class="text-sm text-gray-500 italic bg-gray-50 p-3 rounded-lg text-center">Nenhum dado disponível.</p>
                </div>

                <div>
                  <h4 class="text-sm font-semibold text-gray-900 mb-3">Chamados por Urgência</h4>
                  <div v-if="stats.por_urgencia && stats.por_urgencia.length > 0" class="space-y-3">
                    <div v-for="item in stats.por_urgencia" :key="item.urgencia" class="flex items-center justify-between bg-gray-50 px-4 py-3 rounded-lg border border-gray-100">
                      <span :class="['px-3 py-1 text-xs rounded-full font-bold', getPriorityColor(item.urgencia)]">
                        {{ item.urgencia }}
                      </span>
                      <span class="text-lg font-bold text-gray-900">{{ item.total }}</span>
                    </div>
                  </div>
                  <p v-else class="text-sm text-gray-500 italic bg-gray-50 p-3 rounded-lg text-center">Nenhum dado disponível.</p>
                </div>
              </div>
            </div>
          </section>

          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
              <h3 class="text-lg font-semibold text-gray-900">Atividades Recentes</h3>
              <Clock :size="20" class="text-gray-400" />
            </div>
            
            <div class="px-6 py-8">
              <div class="flow-root">
                <ul class="-my-5">
                  <li v-for="(activity, index) in recentActivities" :key="index" class="relative pb-10 last:pb-0">
                    <div 
                      v-if="index !== recentActivities.length - 1" 
                      class="absolute top-8 left-5 -ml-px h-full w-0.5 bg-gray-200" 
                      aria-hidden="true"
                    ></div>
                    
                    <div class="relative flex items-start space-x-4">
                      <div class="relative">
                        <div :class="['h-10 w-10 rounded-full flex items-center justify-center ring-4 ring-white shadow-sm', activity.bgClass]">
                          <component :is="activity.icon" :size="18" class="text-white" />
                        </div>
                      </div>
                      
                      <div class="min-w-0 flex-1 pt-1.5">
                        <div>
                          <p class="text-sm font-semibold text-gray-900">{{ activity.text }}</p>
                          <p class="text-xs text-gray-500 mt-1">{{ activity.time }}</p>
                        </div>
                      </div>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </section>
        </div>

        <div class="lg:col-span-4 space-y-6">
          
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Informações da Conta</h3>
            </div>
            <div class="px-6 py-5 space-y-4">
              <div>
                <dt class="text-sm font-medium text-gray-500">Nome Completo</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">{{ getFullName(user) }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Username</dt>
                <dd class="mt-1 text-sm text-gray-900 font-mono bg-gray-50 px-2 py-1 rounded">{{ user.username }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Email</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ user.email }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Status da Conta</dt>
                <dd class="mt-1">
                  <span :class="[
                    'px-2 py-1 text-xs rounded-full font-medium',
                    user.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  ]">
                    {{ user.is_active ? 'Ativa' : 'Inativa' }}
                  </span>
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Membro desde</dt>
                <dd class="mt-1 text-sm text-gray-900">
                  {{ user.date_joined ? formatDate(user.date_joined) : 'N/A' }}
                </dd>
              </div>
            </div>
          </section>

          <section v-if="authStore.isAdmin" class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200 bg-gray-50">
              <h3 class="text-lg font-semibold text-gray-900">Ações Administrativas</h3>
            </div>
            <div class="px-6 py-5 space-y-3">
              
              <button 
                @click="showPermissionModal = true"
                class="w-full flex items-center justify-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium text-gray-700"
              >
                <Shield :size="18" />
                Alterar Permissões
              </button>

              <button 
                @click="sendResetEmail"
                class="w-full flex items-center justify-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium text-gray-700"
              >
                <Key :size="18" />
                Enviar Email de Reset
              </button>

              <button 
                @click="toggleUserStatus"
                :class="[
                  'w-full flex items-center justify-center gap-2 px-4 py-2 border rounded-lg transition text-sm font-medium',
                  user.is_active 
                    ? 'border-red-300 text-red-600 hover:bg-red-50' 
                    : 'border-green-300 text-green-600 hover:bg-green-50'
                ]"
              >
                <component :is="user.is_active ? Ban : CheckCircle" :size="18" />
                {{ user.is_active ? 'Desativar Conta' : 'Ativar Conta' }}
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>

    <ChangePermissionModal 
      v-if="user"
      :is-open="showPermissionModal"
      :user-name="user.username"
      :is-staff="user.is_staff"
      :is-superuser="user.is_superuser"
      :is-submitting="permissionLoading"
      @close="showPermissionModal = false"
      @save="handlePermissionChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { useAuthStore } from '@/stores/auth'
import { usersApi, authApi } from '@/api'
import { formatDate } from '@/utils/formatters'
import { getStatusColor, getPriorityColor } from '@/utils/helpers'
import ChangePermissionModal from '@/components/modals/ChangePermissionModal.vue'
import {
  ArrowLeft, Mail, Shield, Key, Ban, Crown,
  ClipboardList, CheckCircle, AlertCircle, Clock,
  User as UserIcon, Wrench
} from 'lucide-vue-next'
import type { User } from '@/types'

const route = useRoute()
const router = useRouter()
const uiStore = useUiStore()
const authStore = useAuthStore()

const user = ref<User | null>(null)
const stats = ref<any>(null)
const loading = ref(false)
const statsLoading = ref(false)
const permissionLoading = ref(false)
const error = ref('')
const showPermissionModal = ref(false)

// MOCK: Atividades Recentes (exatamente como nas imagens)
const recentActivities = ref([
  {
    icon: ClipboardList,
    text: 'Criou um novo chamado',
    time: 'Há 2 horas',
    bgClass: 'bg-blue-500' // Azul para criação
  },
  {
    icon: CheckCircle,
    text: 'Concluiu um chamado',
    time: 'Há 5 horas',
    bgClass: 'bg-green-500' // Verde para conclusão
  },
  {
    icon: Clock,
    text: 'Atualizou status de chamado',
    time: 'Há 1 dia',
    bgClass: 'bg-yellow-500' // Amarelo para atualização
  },
])

const getFullName = (user: User) => {
  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim()
  return fullName || user.username
}

const getInitials = (user: User) => {
  if (user.first_name && user.last_name) {
    return `${user.first_name[0]}${user.last_name[0]}`.toUpperCase()
  }
  return user.username.substring(0, 2).toUpperCase()
}

const loadUser = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const userId = Number(route.params.id)
    if (isNaN(userId)) throw new Error('ID inválido')
    
    user.value = await usersApi.getById(userId)
    
    await loadUserStats(userId)
  } catch (err: any) {
    console.error('Erro:', err)
    error.value = err.message || 'Erro ao carregar usuário'
    uiStore.showToast('error', error.value)
  } finally {
    loading.value = false
  }
}

const loadUserStats = async (userId: number) => {
  statsLoading.value = true
  try {
    const response = await usersApi.getStatistics(userId)
    if (response.success) {
      stats.value = response.data
    }
  } catch (err) {
    console.warn('Estatísticas indisponíveis')
  } finally {
    statsLoading.value = false
  }
}

const handlePermissionChange = async (role: string) => {
  if (!user.value) return
  
  permissionLoading.value = true
  
  try {
    const updates: any = {}
    
    if (role === 'admin') {
      updates.is_superuser = true
      updates.is_staff = true
    } else if (role === 'technician') {
      updates.is_superuser = false
      updates.is_staff = true
    } else { // requester
      updates.is_superuser = false
      updates.is_staff = false
    }
    
    await usersApi.update(user.value.id, updates)
    
    // Atualiza localmente
    user.value.is_superuser = updates.is_superuser
    user.value.is_staff = updates.is_staff
    
    uiStore.showToast('success', 'Permissões atualizadas com sucesso!')
    showPermissionModal.value = false
  } catch (err) {
    console.error(err)
    uiStore.showToast('error', 'Erro ao alterar permissões.')
  } finally {
    permissionLoading.value = false
  }
}

const toggleUserStatus = async () => {
  if (!user.value) return
  
  const action = user.value.is_active ? 'desativar' : 'ativar'
  if (!confirm(`Tem certeza que deseja ${action} este usuário?`)) return
  
  try {
    await usersApi.update(user.value.id, {
      is_active: !user.value.is_active
    })
    
    user.value.is_active = !user.value.is_active
    uiStore.showToast('success', `Usuário ${user.value.is_active ? 'ativado' : 'desativado'} com sucesso!`)
  } catch (err) {
    uiStore.showToast('error', 'Erro ao alterar status do usuário')
  }
}

const sendResetEmail = async () => {
  if (!user.value?.email) {
    uiStore.showToast('error', 'Usuário não tem email cadastrado')
    return
  }
  
  try {
    await authApi.requestPasswordReset(user.value.email)
    uiStore.showToast('success', `Email de recuperação enviado para ${user.value.email}`)
  } catch (err) {
    uiStore.showToast('error', 'Erro ao enviar email de recuperação')
  }
}

onMounted(() => {
  loadUser()
})
</script>