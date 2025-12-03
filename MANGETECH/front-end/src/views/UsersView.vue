<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Usuários</h1>
        <p class="text-sm text-gray-500 mt-1">Gerencie todos os usuários do sistema</p>
      </div>
      <div class="relative">
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search :size="18" class="text-gray-400" />
        </div>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Buscar usuário..."
          class="w-full md:w-80 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
        />
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Total de Usuários</p>
            <h3 class="text-2xl font-bold text-gray-900 mt-1">{{ users.length }}</h3>
          </div>
          <div class="p-3 bg-blue-100 rounded-full">
            <Users :size="24" class="text-blue-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Administradores</p>
            <h3 class="text-2xl font-bold text-gray-900 mt-1">{{ adminCount }}</h3>
          </div>
          <div class="p-3 bg-purple-100 rounded-full">
            <Shield :size="24" class="text-purple-600" />
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Usuários Comuns</p>
            <h3 class="text-2xl font-bold text-gray-900 mt-1">{{ users.length - adminCount }}</h3>
          </div>
          <div class="p-3 bg-green-100 rounded-full">
            <UserCheck :size="24" class="text-green-600" />
          </div>
        </div>
      </div>
    </div>

    <!-- Loading -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando usuários...</p>
    </div>

    <!-- Users Table -->
    <div v-else-if="filteredUsers.length > 0" class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                Usuário
              </th>
              <th scope="col" class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                Email
              </th>
              <th scope="col" class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                Username
              </th>
              <th scope="col" class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                Tipo
              </th>
              <th scope="col" class="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
                Ações
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr 
              v-for="user in filteredUsers" 
              :key="user.id" 
              @click="viewUserDetail(user.id)"
              class="hover:bg-gray-50 cursor-pointer transition-colors"
            >
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="flex-shrink-0 h-10 w-10">
                    <div class="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold text-sm">
                      {{ getInitials(user) }}
                    </div>
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-gray-900">
                      {{ getFullName(user) }}
                    </div>
                    <div class="text-xs text-gray-500">
                      ID: #{{ user.id }}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center text-sm text-gray-600">
                  <Mail :size="16" class="mr-2 text-gray-400" />
                  {{ user.email }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center text-sm text-gray-600">
                  <User :size="16" class="mr-2 text-gray-400" />
                  {{ user.username }}
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span v-if="user.is_superuser" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-red-100 text-red-800 border border-red-200">
                  <Crown :size="14" class="mr-1" />
                  Super Admin
                </span>
                <span v-else-if="user.is_staff" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-purple-100 text-purple-800 border border-purple-200">
                  <Shield :size="14" class="mr-1" />
                  Administrador
                </span>
                <span v-else class="inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 border border-blue-200">
                  <User :size="14" class="mr-1" />
                  Usuário
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <button
                  @click.stop="viewUserDetail(user.id)"
                  class="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-blue-600 hover:text-blue-800 hover:bg-blue-50 rounded-lg transition-colors"
                >
                  <Eye :size="16" />
                  Ver Detalhes
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Info -->
      <div class="bg-gray-50 px-6 py-4 border-t border-gray-200">
        <div class="flex items-center justify-between">
          <p class="text-sm text-gray-600">
            Mostrando <span class="font-medium text-gray-900">{{ filteredUsers.length }}</span> de 
            <span class="font-medium text-gray-900">{{ users.length }}</span> usuário(s)
          </p>
          <div v-if="searchQuery" class="flex items-center text-sm text-gray-600">
            <Filter :size="16" class="mr-2" />
            Resultados filtrados
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div class="text-center py-16 px-4">
        <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <Users :size="40" class="text-gray-400" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum usuário encontrado</h3>
        <p class="text-gray-500 mb-6" v-if="searchQuery">
          Nenhum resultado para "{{ searchQuery }}"
        </p>
        <p class="text-gray-500" v-else>
          Não há usuários cadastrados no sistema
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { usersApi } from '@/api'
import { useUiStore } from '@/stores/ui'
import { 
  Users, Search, Shield, UserCheck, User, Mail, Filter, Eye, Crown
} from 'lucide-vue-next'
import type { User as UserType } from '@/types'

const router = useRouter()
const uiStore = useUiStore()

const users = ref<UserType[]>([])
const loading = ref(false)
const searchQuery = ref('')

const adminCount = computed(() => {
  return users.value.filter(user => user.is_staff).length
})

const filteredUsers = computed(() => {
  if (!searchQuery.value) {
    return users.value
  }
  
  const query = searchQuery.value.toLowerCase()
  return users.value.filter(user => {
    const fullName = getFullName(user).toLowerCase()
    const email = user.email.toLowerCase()
    const username = user.username.toLowerCase()
    
    return fullName.includes(query) || 
           email.includes(query) || 
           username.includes(query)
  })
})

const getFullName = (user: UserType) => {
  const fullName = `${user.first_name || ''} ${user.last_name || ''}`.trim()
  return fullName || user.username
}

const getInitials = (user: UserType) => {
  if (user.first_name && user.last_name) {
    return `${user.first_name[0]}${user.last_name[0]}`.toUpperCase()
  }
  if (user.first_name) {
    return user.first_name.substring(0, 2).toUpperCase()
  }
  return user.username.substring(0, 2).toUpperCase()
}

const viewUserDetail = (userId: number) => {
  router.push(`/users/${userId}`)
}

const loadUsers = async () => {
  loading.value = true
  try {
    const data = await usersApi.getAll()
    users.value = Array.isArray(data) ? data : []
  } catch (err: any) {
    console.error('Erro ao carregar usuários:', err)
    uiStore.showToast('error', 'Erro ao carregar usuários')
    users.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>