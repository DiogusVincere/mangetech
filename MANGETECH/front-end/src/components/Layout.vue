<template>
  <div class="flex h-screen bg-gray-50">
    <!-- Sidebar -->
    <aside :class="['bg-white border-r border-gray-200 transition-all relative', sidebarOpen ? 'w-64' : 'w-20']">
      <!-- Logo -->
      <div class="h-16 flex items-center justify-center border-b border-gray-200">
        <div v-if="sidebarOpen" class="flex items-center gap-2">
          <div class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <span class="text-white font-bold">M</span>
          </div>
          <span class="font-semibold text-lg">MANGE_TECH</span>
        </div>
        <div v-else class="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
          <span class="text-white font-bold">M</span>
        </div>
      </div>

      <!-- Menu -->
      <nav class="p-4 pb-32">
        <router-link
          v-for="item in menuItems"
          :key="item.path"
          :to="item.path"
          class="flex items-center gap-3 px-3 py-2 rounded-lg mb-1 text-gray-700 hover:bg-gray-100"
          active-class="bg-blue-50 text-blue-700 font-medium"
        >
          <component :is="item.icon" :size="20" />
          <span v-if="sidebarOpen">{{ item.label }}</span>
        </router-link>
      </nav>

      <!-- User Info -->
      <div class="absolute bottom-0 left-0 right-0 border-t border-gray-200">
        <div v-if="sidebarOpen" class="p-4">
          <!-- User Card -->
          <div class="flex items-center gap-3 mb-2">
            <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold">
              {{ getUserInitials() }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium truncate">{{ authStore.user?.first_name || 'Usuário' }}</p>
              <p class="text-xs text-gray-500 truncate">{{ authStore.user?.email }}</p>
            </div>
          </div>
          
          <!-- Menu Items -->
          <div class="space-y-1">
            <router-link
              to="/profile"
              class="flex items-center gap-2 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition"
            >
              <User :size="16" />
              <span>Meu Perfil</span>
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
        
        <!-- Collapsed State -->
        <div v-else class="p-4">
          <div class="relative group">
            <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold cursor-pointer">
              {{ getUserInitials() }}
            </div>
            
            <!-- Tooltip on hover -->
            <div class="absolute bottom-full left-0 mb-2 hidden group-hover:block bg-gray-900 text-white text-xs rounded py-1 px-2 whitespace-nowrap z-50">
              {{ authStore.user?.email }}
            </div>
          </div>
        </div>
      </div>
    </aside>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col overflow-hidden">
      <!-- Header -->
      <header class="bg-white border-b border-gray-200 h-16 flex items-center justify-between px-6">
        <button @click="uiStore.toggleSidebar()" class="p-2 hover:bg-gray-100 rounded-lg">
          <Menu :size="20" />
        </button>

        <div class="flex items-center gap-4">
          <Bell :size="20" class="text-gray-600 cursor-pointer hover:text-gray-900" />
        </div>
      </header>

      <!-- Page Content -->
      <main class="flex-1 overflow-auto p-6">
        <router-view />
      </main>
    </div>

    <!-- Toast -->
    <Toast />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { LayoutDashboard, ClipboardList, Package, Users, Menu, Bell, User, LogOut } from 'lucide-vue-next'
import Toast from './Toast.vue'

const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const sidebarOpen = computed(() => uiStore.sidebarOpen)

const menuItems = computed(() => [
  { path: '/', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/tasks', label: 'Chamados', icon: ClipboardList },
  { path: '/assets', label: 'Ativos', icon: Package },
  { path: '/users', label: 'Usuários', icon: Users },
])

const getUserInitials = () => {
  const user = authStore.user
  if (!user) return 'U'
  
  if (user.first_name && user.last_name) {
    return `${user.first_name[0]}${user.last_name[0]}`.toUpperCase()
  }
  
  return user.email?.[0]?.toUpperCase() || 'U'
}

const handleLogout = async () => {
  await authStore.logout()
  router.push('/login')
}
</script>