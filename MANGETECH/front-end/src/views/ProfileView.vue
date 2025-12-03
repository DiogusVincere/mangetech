<!-- src/views/ProfileView.vue -->
<template>
  <div class="space-y-6">
    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando perfil...</p>
    </div>

    <!-- Profile Content -->
    <template v-else>
      <!-- Header -->
      <div class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
        <div class="px-6 py-4">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div class="flex items-center gap-4">
              <div class="w-20 h-20 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold text-3xl">
                {{ getInitials() }}
              </div>
              <div>
                <h1 class="text-2xl font-bold text-gray-900">{{ getFullName() }}</h1>
                <p class="text-sm text-gray-500">{{ profileData.email }}</p>
                <div class="mt-2">
                  <span v-if="authStore.user?.is_superuser" class="px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800 border border-red-200">
                    <Crown :size="14" class="inline mr-1" />
                    Super Admin
                  </span>
                  <span v-else-if="authStore.user?.is_staff" class="px-3 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800 border border-purple-200">
                    <Shield :size="14" class="inline mr-1" />
                    Administrador
                  </span>
                  <span v-else class="px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800 border border-blue-200">
                    <User :size="14" class="inline mr-1" />
                    Usuário
                  </span>
                </div>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <button
                @click="showPasswordModal = true"
                class="flex items-center gap-2 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition text-sm font-medium"
              >
                <Key :size="18" />
                Alterar Senha
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <!-- Left Column (8/12) -->
        <div class="lg:col-span-8 space-y-6">
          <!-- Informações Pessoais -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-gray-900">Informações Pessoais</h3>
                <UserCircle :size="20" class="text-gray-400" />
              </div>
            </div>
            <div class="px-6 py-5">
              <form @submit.prevent="handleUpdateProfile" class="space-y-5">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Nome
                      <span class="text-red-500">*</span>
                    </label>
                    <input
                      v-model="profileData.first_name"
                      type="text"
                      required
                      class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                      placeholder="Seu primeiro nome"
                    />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                      Sobrenome
                      <span class="text-red-500">*</span>
                    </label>
                    <input
                      v-model="profileData.last_name"
                      type="text"
                      required
                      class="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                      placeholder="Seu sobrenome"
                    />
                  </div>
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-2">
                    Email
                    <span class="text-red-500">*</span>
                  </label>
                  <div class="relative">
                    <Mail :size="18" class="absolute left-3 top-3 text-gray-400" />
                    <input
                      v-model="profileData.email"
                      type="email"
                      required
                      class="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                      placeholder="seu.email@exemplo.com"
                    />
                  </div>
                </div>

                <div class="flex items-center justify-between pt-4 border-t border-gray-200">
                  <p class="text-sm text-gray-500">
                    <span class="text-red-500">*</span> Campos obrigatórios
                  </p>
                  <div class="flex gap-3">
                    <button
                      type="button"
                      @click="loadProfile"
                      :disabled="loadingProfile"
                      class="px-5 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition text-sm font-medium"
                    >
                      Cancelar
                    </button>
                    <button
                      type="submit"
                      :disabled="loadingProfile"
                      class="flex items-center gap-2 px-6 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition text-sm font-medium"
                    >
                      <Save :size="18" v-if="!loadingProfile" />
                      <div v-else class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      {{ loadingProfile ? 'Salvando...' : 'Salvar Alterações' }}
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </section>

          <!-- Atividades Recentes -->
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
          <!-- Informações da Conta -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Informações da Conta</h3>
            </div>
            <div class="px-6 py-5 space-y-4">
              <div>
                <dt class="text-sm font-medium text-gray-500">Nome Completo</dt>
                <dd class="mt-1 text-sm font-semibold text-gray-900">{{ getFullName() }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Username</dt>
                <dd class="mt-1 text-sm text-gray-900 font-mono bg-gray-50 px-2 py-1 rounded">
                  {{ authStore.user?.username || 'N/A' }}
                </dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Email</dt>
                <dd class="mt-1 text-sm text-gray-900">{{ profileData.email }}</dd>
              </div>
              <div>
                <dt class="text-sm font-medium text-gray-500">Tipo de Conta</dt>
                <dd class="mt-1">
                  <span v-if="authStore.user?.is_superuser" class="px-2 py-1 text-xs rounded-full font-medium bg-red-100 text-red-800 border border-red-200">
                    Super Administrador
                  </span>
                  <span v-else-if="authStore.user?.is_staff" class="px-2 py-1 text-xs rounded-full font-medium bg-purple-100 text-purple-800 border border-purple-200">
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
                    authStore.user?.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  ]">
                    {{ authStore.user?.is_active ? 'Ativa' : 'Inativa' }}
                  </span>
                </dd>
              </div>
            </div>
          </section>

          <!-- Segurança -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <div class="flex items-center justify-between">
                <h3 class="text-lg font-semibold text-gray-900">Segurança</h3>
                <Shield :size="20" class="text-gray-400" />
              </div>
            </div>
            <div class="px-6 py-5 space-y-3">
              <button
                @click="showPasswordModal = true"
                class="w-full flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm group"
              >
                <div class="flex items-center gap-3">
                  <Key :size="18" class="text-gray-400 group-hover:text-blue-600 transition" />
                  <span class="font-medium text-gray-700 group-hover:text-gray-900">Alterar Senha</span>
                </div>
                <ChevronRight :size="18" class="text-gray-400" />
              </button>
              <button class="w-full flex items-center justify-between px-4 py-3 border border-gray-200 rounded-lg hover:bg-gray-50 transition text-sm group">
                <div class="flex items-center gap-3">
                  <Bell :size="18" class="text-gray-400 group-hover:text-blue-600 transition" />
                  <span class="font-medium text-gray-700 group-hover:text-gray-900">Notificações</span>
                </div>
                <ChevronRight :size="18" class="text-gray-400" />
              </button>
            </div>
          </section>

          <!-- Estatísticas Rápidas -->
          <section class="bg-white shadow-sm rounded-xl border border-gray-200 overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h3 class="text-lg font-semibold text-gray-900">Minhas Estatísticas</h3>
            </div>
            <div class="px-6 py-5">
              <div class="grid grid-cols-2 gap-4">
                <div class="text-center p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <div class="text-2xl font-bold text-blue-600">24</div>
                  <div class="text-xs text-gray-600 mt-1">Chamados</div>
                </div>
                <div class="text-center p-4 bg-green-50 rounded-lg border border-green-200">
                  <div class="text-2xl font-bold text-green-600">18</div>
                  <div class="text-xs text-gray-600 mt-1">Concluídos</div>
                </div>
                <div class="text-center p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                  <div class="text-2xl font-bold text-yellow-600">6</div>
                  <div class="text-xs text-gray-600 mt-1">Em Andamento</div>
                </div>
                <div class="text-center p-4 bg-purple-50 rounded-lg border border-purple-200">
                  <div class="text-2xl font-bold text-purple-600">75%</div>
                  <div class="text-xs text-gray-600 mt-1">Taxa Sucesso</div>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </template>

    <!-- Modal de Alteração de Senha -->
    <div
      v-if="showPasswordModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4"
      @click.self="showPasswordModal = false"
    >
      <div class="bg-white rounded-xl shadow-2xl max-w-md w-full overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <h3 class="text-lg font-semibold text-gray-900">Alterar Senha</h3>
          <button
            @click="showPasswordModal = false"
            class="p-1 hover:bg-gray-100 rounded-lg transition"
          >
            <X :size="20" class="text-gray-500" />
          </button>
        </div>

        <form @submit.prevent="handleChangePassword" class="px-6 py-5 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Senha Atual
              <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <Lock :size="18" class="absolute left-3 top-3 text-gray-400" />
              <input
                v-model="passwordData.current"
                :type="showCurrentPassword ? 'text' : 'password'"
                required
                class="w-full pl-10 pr-10 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                placeholder="Digite sua senha atual"
              />
              <button
                type="button"
                @click="showCurrentPassword = !showCurrentPassword"
                class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
              >
                <Eye v-if="!showCurrentPassword" :size="18" />
                <EyeOff v-else :size="18" />
              </button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Nova Senha
              <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <Lock :size="18" class="absolute left-3 top-3 text-gray-400" />
              <input
                v-model="passwordData.new"
                :type="showNewPassword ? 'text' : 'password'"
                required
                minlength="6"
                class="w-full pl-10 pr-10 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                placeholder="Mínimo 6 caracteres"
              />
              <button
                type="button"
                @click="showNewPassword = !showNewPassword"
                class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
              >
                <Eye v-if="!showNewPassword" :size="18" />
                <EyeOff v-else :size="18" />
              </button>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Confirmar Nova Senha
              <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <Lock :size="18" class="absolute left-3 top-3 text-gray-400" />
              <input
                v-model="passwordData.confirm"
                :type="showConfirmPassword ? 'text' : 'password'"
                required
                class="w-full pl-10 pr-10 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                placeholder="Digite a senha novamente"
              />
              <button
                type="button"
                @click="showConfirmPassword = !showConfirmPassword"
                class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
              >
                <Eye v-if="!showConfirmPassword" :size="18" />
                <EyeOff v-else :size="18" />
              </button>
            </div>
            <p v-if="passwordData.new && passwordData.confirm && passwordData.new !== passwordData.confirm" class="text-xs text-red-600 mt-1">
              As senhas não coincidem
            </p>
          </div>

          <div class="flex gap-3 pt-4">
            <button
              type="button"
              @click="showPasswordModal = false"
              :disabled="loadingPassword"
              class="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50 transition text-sm font-medium"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="loadingPassword || passwordData.new !== passwordData.confirm"
              class="flex-1 flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition text-sm font-medium"
            >
              <div v-if="loadingPassword" class="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
              {{ loadingPassword ? 'Alterando...' : 'Alterar Senha' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import api from '@/api/client'
import {
  UserCircle, Mail, Key, Shield, User, Crown, Clock, Save,
  Lock, Eye, EyeOff, X, Bell, ChevronRight,
  ClipboardList, CheckCircle, AlertCircle
} from 'lucide-vue-next'

const authStore = useAuthStore()
const uiStore = useUiStore()

const profileData = ref({
  first_name: '',
  last_name: '',
  email: ''
})

const passwordData = ref({
  current: '',
  new: '',
  confirm: ''
})

const loading = ref(false)
const loadingProfile = ref(false)
const loadingPassword = ref(false)
const showPasswordModal = ref(false)
const showCurrentPassword = ref(false)
const showNewPassword = ref(false)
const showConfirmPassword = ref(false)

const recentActivities = ref([
  {
    icon: ClipboardList,
    text: 'Atualizou suas informações pessoais',
    time: 'Há 2 horas',
    color: 'bg-blue-500'
  },
  {
    icon: CheckCircle,
    text: 'Alterou a senha da conta',
    time: 'Há 1 dia',
    color: 'bg-green-500'
  },
  {
    icon: AlertCircle,
    text: 'Login realizado com sucesso',
    time: 'Há 2 dias',
    color: 'bg-yellow-500'
  },
])

const getFullName = () => {
  const fullName = `${profileData.value.first_name || ''} ${profileData.value.last_name || ''}`.trim()
  return fullName || authStore.user?.username || 'Usuário'
}

const getInitials = () => {
  if (profileData.value.first_name && profileData.value.last_name) {
    return `${profileData.value.first_name[0]}${profileData.value.last_name[0]}`.toUpperCase()
  }
  if (profileData.value.first_name) {
    return profileData.value.first_name.substring(0, 2).toUpperCase()
  }
  if (authStore.user?.username) {
    return authStore.user.username.substring(0, 2).toUpperCase()
  }
  return 'US'
}

const loadProfile = async () => {
  loading.value = true
  try {
    const response = await api.get('/perfil/')
    const data = response.data.data
    profileData.value = {
      first_name: data.first_name || '',
      last_name: data.last_name || '',
      email: data.email || ''
    }
  } catch (error) {
    console.error('Erro ao carregar perfil:', error)
    uiStore.showToast('error', 'Erro ao carregar perfil')
  } finally {
    loading.value = false
  }
}

const handleUpdateProfile = async () => {
  loadingProfile.value = true
  try {
    await api.put('/perfil/atualizar/', profileData.value)
    uiStore.showToast('success', 'Perfil atualizado com sucesso!')
    
    // Atualizar dados do usuário no store
    if (authStore.user) {
      authStore.user.first_name = profileData.value.first_name
      authStore.user.last_name = profileData.value.last_name
      authStore.user.email = profileData.value.email
    }
  } catch (error: any) {
    uiStore.showToast('error', error.response?.data?.message || 'Erro ao atualizar perfil')
  } finally {
    loadingProfile.value = false
  }
}

const handleChangePassword = async () => {
  if (passwordData.value.new !== passwordData.value.confirm) {
    uiStore.showToast('error', 'As senhas não coincidem')
    return
  }

  loadingPassword.value = true
  try {
    await api.post('/perfil/alterar-senha/', {
      senha_atual: passwordData.value.current,
      nova_senha: passwordData.value.new,
      confirmar_senha: passwordData.value.confirm
    })
    uiStore.showToast('success', 'Senha alterada com sucesso!')
    passwordData.value = { current: '', new: '', confirm: '' }
    showPasswordModal.value = false
    showCurrentPassword.value = false
    showNewPassword.value = false
    showConfirmPassword.value = false
  } catch (error: any) {
    uiStore.showToast('error', error.response?.data?.errors?.senha_atual?.[0] || 'Erro ao alterar senha')
  } finally {
    loadingPassword.value = false
  }
}

onMounted(() => {
  loadProfile()
})
</script>