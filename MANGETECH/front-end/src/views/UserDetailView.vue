<!-- src/views/UserDetailView.vue - VERSÃO FINAL INTEGRADA -->
<template>
  <div class="space-y-6">
    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando usuário...</p>
    </div>

    <!-- Error State -->
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

    <!-- User Detail -->
    <div v-else-if="user">
      <!-- Header -->
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
                <span v-if="user.is_superuser" class="px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 border border-red-200">
                  <Crown :size="14" class="inline mr-1" />
                  Super Admin
                </span>
                <span v-else-if="user.is_staff" class="px-3 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800 border border-purple-200">
                  <Shield :size="14" class="inline mr-1" />
                  Administrador
                </span>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <button class="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium">
                <Mail :size="18" />
                Enviar Email
              </button>
              <button class="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium">
                <Edit :size="18" />
                Editar
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <!-- Left Column (8/12) -->
        <div class="lg:col-span-8 space-y-6">
          <!-- Estatísticas de Chamados -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-gray-900">Estatísticas de Chamados</h3>
                <ClipboardList :size="20" class="text-gray-400" />
              </div>
            </div>
            <div class="px-6 py-5">
              <!-- Loading Stats -->
              <div v-if="statsLoading" class="flex items-center justify-center py-12">
                <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
                <p class="text-gray-600 ml-4">Carregando estatísticas...</p>
              </div>

              <!-- Stats Content -->
              <div v-else-if="stats" class="space-y-6">
                <!-- KPIs -->
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div class="text-center p-4 bg-blue-50 rounded-lg border border-blue-200">
                    <div class="text-3xl font-bold text-blue-600">{{ stats.total_chamados }}</div>
                    <div class="text-xs text-gray-600 mt-1">Total</div>
                  </div>
                  <div class="text-center p-4 bg-green-50 rounded-lg border border-green-200">
                    <div class="text-3xl font-bold text-green-600">{{ stats.chamados_solicitados }}</div>
                    <div class="text-xs text-gray-600 mt-1">Solicitados</div>
                  </div>
                  <div class="text-center p-4 bg-purple-50 rounded-lg border border-purple-200">
                    <div class="text-3xl font-bold text-purple-600">{{ stats.chamados_responsavel }}</div>
                    <div class="text-xs text-gray-600 mt-1">Responsável</div>
                  </div>
                  <div class="text-center p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                    <div class="text-3xl font-bold text-yellow-600">{{ stats.chamados_ativos }}</div>
                    <div class="text-xs text-gray-600 mt-1">Ativos</div>
                  </div>
                </div>

                <!-- Por Status -->
                <div v-if="stats.por_status && stats.por_status.length > 0">
                  <h4 class="text-sm font-semibold text-gray-900 mb-3">Chamados por Status</h4>
                  <div class="space-y-2">
                    <div 
                      v-for="item in stats.por_status" 
                      :key="item.status" 
                      class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                    >
                      <div class="flex items-center gap-3">
                        <span :class="['px-3 py-1 text-xs rounded-full font-semibold', getStatusColor(item.status)]">
                          {{ item.status }}
                        </span>
                      </div>
                      <span class="text-lg font-bold text-gray-900">{{ item.total }}</span>
                    </div>
                  </div>
                </div>

                <!-- Por Urgência -->
                <div v-if="stats.por_urgencia && stats.por_urgencia.length > 0">
                  <h4 class="text-sm font-semibold text-gray-900 mb-3">Chamados por Urgência</h4>
                  <div class="space-y-2">
                    <div 
                      v-for="item in stats.por_urgencia" 
                      :key="item.urgencia" 
                      class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                    >
                      <div class="flex items-center gap-3">
                        <span :class="['px-3 py-1 text-xs rounded-full font-semibold', getPriorityColor(item.urgencia)]">
                          {{ item.urgencia }}
                        </span>
                      </div>
                      <span class="text-lg font-bold text-gray-900">{{ item.total }}</span>
                    </div>
                  </div>
                </div>

                <!-- Empty State -->
                <div v-if="stats.total_chamados === 0" class="text-center py-8">
                  <div class="mx-auto w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
                    <ClipboardList :size="32" class="text-gray-400" />
                  </div>
                  <p class="text-gray-500">Nenhum chamado registrado</p>
                </div>
              </div>

              <!-- Error State -->
              <div v-else class="text-center py-8">
                <p class="text-gray-500">Não foi possível carregar as estatísticas</p>
              </div>
            </div>
          </section>

          <!-- Atividades Recentes (Mock) -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-gray-900">Atividades Recentes</h3>
                <Clock :size="20" class="text-gray-400" />
              </div>
            </div>
            <div class="px-6 py-5">
              <div class="flow-root">
                <ul class="space-y-6">
                  <li v-for="(activity, index) in recentActivities" :key="index" class="relative">
                    <div v-if="index < recentActivities.length - 1" class="absolute left-4 top-8 -ml-px h-full w-0.5 bg-gray-200"></div>
                    <div class="relative flex items-start gap-3">
                      <div class="flex-shrink-0">
                        <div :class="['h-8 w-8 rounded-full flex items-center justify-center', activity.color]">
                          <component :is="activity.icon" :size="16" class="text-white" />
                        </div>
                      </div>
                      <div class="flex-1 min-w-0">
                        <p class="text-sm font-medium text-gray-900">{{ activity.text }}</p>
                        <p class="text-xs text-gray-500 mt-1">{{ activity.time }}</p>
                      </div>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </section>
        </div>

        <!-- Right Column (4/12) -->
        <div class="lg:col-span-4 space-y-6">
          <!-- Informações Pessoais -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Informações Pessoais</h3>
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
                <dt class="text-sm font-medium text-gray-500">Tipo de Conta</dt>
                <dd class="mt-1">
                  <span v-if="user.is_superuser" class="px-2 py-1 text-xs rounded-full font-medium bg-red-100 text-red-800 border border-red-200">
                    Super Administrador
                  </span>
                  <span v-else-if="user.is_staff" class="px-2 py-1 text-xs rounded-full font-medium bg-purple-100 text-purple-800 border border-purple-200">
                    Administrador
                  </span>
                  <span v-else class="px-2 py-1 text-xs rounded-full font-medium bg-gray-100 text-gray-800">
                    Usuário Padrão
                  </span>
                </dd>
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
            </div>
          </section>

          <!-- Informações do Sistema -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Sistema</h3>
            </div>
            <div class="px-6 py-5 space-y-4">
              <div>
                <dt class="text-sm font-medium text-gray-500">Membro desde</dt>
                <dd class="mt-1 text-sm text-gray-900">
                  {{ user.date_joined ? formatDate(user.date_joined) : 'Não disponível' }}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">ID do Usuário</dt>
                <dd class="mt-1 text-sm text-gray-900 font-mono bg-gray-50 px-2 py-1 rounded">#{{ user.id }}</dd>
              </div>
            </div>
          </section>

          <!-- Ações -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Ações Rápidas</h3>
            </div>
            <div class="px-6 py-5 space-y-3">
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-sm font-medium">
                <Mail :size="18" />
                Enviar Email
              </button>
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium text-gray-700">
                <Shield :size="18" />
                Alterar Permissões
              </button>
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium text-gray-700">
                <Key :size="18" />
                Resetar Senha
              </button>
              <button class="w-full flex items-center justify-center gap-2 px-4 py-2 border border-red-300 text-red-600 rounded-lg hover:bg-red-50 transition text-sm font-medium">
                <Ban :size="18" />
                Desativar Conta
              </button>
            </div>
          </section>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import { usersApi } from '@/api'
import { formatDate } from '@/utils/formatters'
import { getStatusColor, getPriorityColor } from '@/utils/helpers'
import {
  ArrowLeft, Mail, Edit, Shield, Key, Ban, Crown,
  ClipboardList, CheckCircle, Clock, AlertCircle
} from 'lucide-vue-next'
import type { User } from '@/types'

const route = useRoute()
const router = useRouter()
const uiStore = useUiStore()

const user = ref<User | null>(null)
const stats = ref<any>(null)
const loading = ref(false)
const statsLoading = ref(false)
const error = ref('')

const recentActivities = ref([
  {
    icon: ClipboardList,
    text: 'Criou um novo chamado',
    time: 'Há 2 horas',
    color: 'bg-blue-500'
  },
  {
    icon: CheckCircle,
    text: 'Concluiu um chamado',
    time: 'Há 5 horas',
    color: 'bg-green-500'
  },
  {
    icon: Clock,
    text: 'Atualizou status de chamado',
    time: 'Há 1 dia',
    color: 'bg-yellow-500'
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
  if (user.first_name) {
    return user.first_name.substring(0, 2).toUpperCase()
  }
  return user.username.substring(0, 2).toUpperCase()
}

const loadUser = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const userId = Number(route.params.id)
    
    console.log('Carregando usuário ID:', userId)
    
    if (isNaN(userId)) {
      throw new Error('ID de usuário inválido')
    }
    
    user.value = await usersApi.getById(userId)
    
    console.log('Usuário carregado:', user.value)
    
    // Carregar estatísticas em paralelo
    await loadUserStats(userId)
  } catch (err: any) {
    console.error('❌ Erro ao carregar usuário:', err)
    
    if (err.response?.status === 404) {
      error.value = 'Usuário não encontrado'
      uiStore.showToast('error', 'Usuário não encontrado')
      setTimeout(() => router.push('/users'), 2000)
    } else if (err.response?.status === 403) {
      error.value = 'Você não tem permissão para visualizar este usuário'
      uiStore.showToast('error', 'Acesso negado')
    } else {
      error.value = err.message || 'Erro ao carregar dados do usuário'
      uiStore.showToast('error', 'Erro ao carregar usuário')
    }
  } finally {
    loading.value = false
  }
}

const loadUserStats = async (userId: number) => {
  statsLoading.value = true
  
  try {
    console.log('Carregando estatísticas do usuário:', userId)
    
    const response = await usersApi.getStatistics(userId)
    
    console.log('Estatísticas recebidas:', response)
    
    if (response.success) {
      stats.value = response.data
    } else {
      throw new Error(response.message || 'Erro ao carregar estatísticas')
    }
  } catch (err: any) {
    console.error('❌ Erro ao carregar estatísticas:', err)
    
    // Fallback com dados zerados (não mostra erro ao usuário)
    stats.value = {
      total_chamados: 0,
      chamados_solicitados: 0,
      chamados_responsavel: 0,
      chamados_ativos: 0,
      por_status: [],
      por_urgencia: []
    }
    
    // Só mostra toast se não for erro de permissão
    if (err.response?.status !== 403 && err.response?.status !== 404) {
      console.warn('⚠️ Usando dados vazios para estatísticas')
    }
  } finally {
    statsLoading.value = false
  }
}

onMounted(() => {
  loadUser()
})
</script>