<template>
  <div class="flex h-screen bg-gray-50">
    <!-- Sidebar -->
    <aside :class="['bg-white border-r border-gray-200 transition-all relative flex-shrink-0', sidebarOpen ? 'w-64' : 'w-20']">
      <div class="h-16 flex items-center justify-center border-b border-gray-200">
        <router-link :to="homePath" class="flex items-center gap-2">
          <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <span class="text-white font-bold">M</span>
          </div>
          <span v-if="sidebarOpen" class="font-semibold text-lg">MangeTech</span>
        </router-link>
      </div>

      <nav class="p-4 pb-40">
        <router-link
          v-for="item in menuItems"
          :key="item.path"
          :to="item.path"
          :title="item.label"
          class="flex items-center gap-3 px-3 py-2 rounded-lg mb-1 text-gray-700 hover:bg-gray-100"
          :class="isActive(item.path) ? 'bg-blue-50 text-blue-700 font-medium' : ''"
        >
          <component :is="item.icon" :size="20" />
          <span v-if="sidebarOpen">{{ item.label }}</span>
        </router-link>
      </nav>

      <div class="absolute bottom-0 left-0 right-0 border-t border-gray-200">
        <div v-if="sidebarOpen" class="p-4">
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold">
              {{ userInitials }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium truncate">{{ userName }}</p>
              <p class="text-xs text-gray-500 truncate">
                {{ authStore.isAdmin ? 'Administrador' : 'Usuário' }} · {{ authStore.user?.email }}
              </p>
            </div>
          </div>
          <div class="space-y-1">
            <router-link
              to="/profile"
              class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition"
            >
              <User :size="16" />
              <span>Meu perfil</span>
            </router-link>
            <button
              @click="handleLogout"
              class="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition"
            >
              <LogOut :size="16" />
              <span>Sair</span>
            </button>
          </div>
        </div>

        <div v-else class="p-4 flex flex-col items-center gap-2">
          <router-link
            to="/profile"
            :title="authStore.user?.email"
            class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold"
          >
            {{ userInitials }}
          </router-link>
          <button @click="handleLogout" title="Sair" class="p-2 text-red-600 hover:bg-red-50 rounded-lg">
            <LogOut :size="18" />
          </button>
        </div>
      </div>
    </aside>

    <div class="flex-1 flex flex-col overflow-hidden min-w-0">
      <header class="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-6">
        <button @click="uiStore.toggleSidebar()" class="p-2 hover:bg-gray-100 rounded-lg" title="Recolher menu">
          <Menu :size="20" />
        </button>

        <router-link
          to="/tasks/create"
          class="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition"
        >
          <Plus :size="16" />
          <span class="hidden sm:inline">Novo chamado</span>
        </router-link>
      </header>

      <main class="flex-1 overflow-auto p-6">
        <router-view :key="$route.path" />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { LayoutDashboard, ClipboardList, Package, Users, Menu, User, LogOut, Plus } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const sidebarOpen = computed(() => uiStore.sidebarOpen)
const homePath = computed(() => (authStore.isAdmin ? '/' : '/tasks'))

// Dashboard e Usuários são só de staff: o menu não mostra o que a pessoa não pode abrir.
const menuItems = computed(() => [
  ...(authStore.isAdmin ? [{ path: '/', label: 'Dashboard', icon: LayoutDashboard }] : []),
  { path: '/tasks', label: 'Chamados', icon: ClipboardList },
  { path: '/assets', label: 'Ativos', icon: Package },
  ...(authStore.isAdmin ? [{ path: '/users', label: 'Usuários', icon: Users }] : []),
])

const isActive = (path: string) => (path === '/' ? route.path === '/' : route.path.startsWith(path))

const userName = computed(() => {
  const u = authStore.user
  if (!u) return 'Usuário'
  return `${u.first_name || ''} ${u.last_name || ''}`.trim() || u.username
})

const userInitials = computed(() => {
  const u = authStore.user
  if (!u) return 'U'
  if (u.first_name && u.last_name) return `${u.first_name[0]}${u.last_name[0]}`.toUpperCase()
  return (u.first_name || u.email || 'U').substring(0, 2).toUpperCase()
})

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>
