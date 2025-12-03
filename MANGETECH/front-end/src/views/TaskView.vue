<template>
  <div class="space-y-6">
    <!-- Header com novo estilo -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Chamados</h1>
        <p class="text-sm text-gray-500 mt-1">Gerencie todos os chamados do sistema</p>
      </div>
      
      <router-link
        to="/tasks/create"
        class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition shadow-sm"
      >
        <Plus :size="20" class="mr-2" />
        <span>Novo Chamado</span>
      </router-link>
    </div>

    <!-- Filters com estilo moderno -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="relative">
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search :size="18" class="text-gray-400" />
          </div>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Buscar chamados..."
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
          />
        </div>
        
        <select
          v-model="filters.status"
          class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none transition"
        >
          <option value="">Todos os Status</option>
          <option value="ABERTO">Aberto</option>
          <option value="AGUARDANDO RESP">Aguardando Responsáveis</option>
          <option value="EM ANDAMENTO">Em Andamento</option>
          <option value="REALIZADO">Realizado</option>
          <option value="CONCLUÍDO">Concluído</option>
          <option value="CANCELADO">Cancelado</option>
        </select>
        
        <select
          v-model="filters.urgencia"
          class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none transition"
        >
          <option value="">Todas Prioridades</option>
          <option value="Crítico">Crítico</option>
          <option value="Alta">Alta</option>
          <option value="Média">Média</option>
          <option value="Baixa">Baixa</option>
        </select>
        
        <button
          @click="loadTasks"
          class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition flex items-center justify-center"
        >
          <Filter :size="18" class="mr-2" />
          Filtrar
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando chamados...</p>
    </div>

    <!-- Tasks List com cards modernos -->
    <div v-else-if="tasks.length > 0" class="grid grid-cols-1 gap-4">
      <div
        v-for="task in tasks"
        :key="task.id"
        class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md hover:border-blue-300 transition-all duration-200"
      >
        <div class="flex items-start justify-between mb-3">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-2">
              <span class="text-xs font-medium text-gray-500">#{{ task.id }}</span>
              <span :class="['px-2.5 py-1 text-xs font-semibold rounded-full', statusClass(task.status)]">
                {{ task.status }}
              </span>
            </div>
            <h3 
              @click="$router.push(`/tasks/${task.id}`)"
              class="text-lg font-semibold text-gray-900 mb-1 hover:text-blue-600 cursor-pointer transition"
            >
              {{ task.titulo }}
            </h3>
            <div class="flex items-center gap-3 text-sm text-gray-600 mt-2">
              <div class="flex items-center">
                <Package :size="16" class="mr-1" />
                {{ task.ativo }}
              </div>
              <div class="flex items-center">
                <MapPin :size="16" class="mr-1" />
                {{ task.ambiente }}
              </div>
            </div>
          </div>
          <span :class="['px-3 py-1.5 text-xs font-bold rounded-full whitespace-nowrap ml-4', priorityClass(task.urgencia)]">
            {{ task.urgencia }}
          </span>
        </div>
        
        <p class="text-sm text-gray-600 line-clamp-2 mb-4">{{ task.descricao }}</p>
        
        <div class="flex items-center justify-between pt-3 border-t border-gray-100">
          <div class="flex items-center text-xs text-gray-500">
            <Calendar :size="14" class="mr-1" />
            {{ formatDate(task.data_criacao) }}
          </div>
          
          <!-- 🆕 BOTÕES DE AÇÃO -->
          <div class="flex items-center gap-2">
            <button
              @click.stop="openCommentModal(task)"
              class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition"
              title="Adicionar Comentário"
            >
              <MessageSquare :size="14" />
              <span>Comentar</span>
            </button>
            
            <button
              @click.stop="openStatusModal(task)"
              class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-purple-600 bg-purple-50 rounded-lg hover:bg-purple-100 transition"
              title="Mudar Status"
            >
              <RefreshCw :size="14" />
              <span>Status</span>
            </button>
            
            <button
              @click.stop="$router.push(`/tasks/${task.id}`)"
              class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
              title="Ver Detalhes"
            >
              <ChevronRight :size="14" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State moderno -->
    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div class="text-center py-16 px-4">
        <div class="mx-auto w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mb-4">
          <ClipboardList :size="40" class="text-gray-400" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum chamado encontrado</h3>
        <p class="text-gray-500 mb-6">Crie um novo chamado para começar</p>
        
        <router-link
          to="/tasks/create"
          class="inline-flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-sm"
        >
          <Plus :size="20" class="mr-2" />
          Criar Primeiro Chamado
        </router-link>
      </div>
    </div>

    <!-- 🆕 MODALS INTEGRADOS -->
    <AddCommentModal
      v-if="selectedTask"
      :is-open="showCommentModal"
      :chamado-id="Number(selectedTask.id)"
      @close="closeCommentModal"
      @comment-added="handleCommentAdded"
    />

    <AdvanceStatusModal
      v-if="selectedTask"
      :is-open="showStatusModal"
      :chamado-id="Number(selectedTask.id)"
      :current-status="selectedTask.status"
      @close="closeStatusModal"
      @status-changed="handleStatusChanged"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { tasksApi } from '../api'
import { useUiStore } from '../stores/ui'
import { 
  Plus, 
  ClipboardList, 
  Search, 
  Filter, 
  Package, 
  MapPin, 
  Calendar, 
  ChevronRight,
  MessageSquare,
  RefreshCw
} from 'lucide-vue-next'
import { format } from 'date-fns'
import type { Task } from '../types'
import AddCommentModal from '../components/modals/AddCommentModal.vue'
import AdvanceStatusModal from '../components/modals/AdvanceStatusModal.vue'

const uiStore = useUiStore()
const tasks = ref<Task[]>([])
const loading = ref(false)

// 🆕 Estados dos Modals
const showCommentModal = ref(false)
const showStatusModal = ref(false)
const selectedTask = ref<Task | null>(null)

const filters = ref({
  search: '',
  status: '',
  urgencia: '',
})

const priorityClass = (priority: string) => {
  const classes = {
    'Crítico': 'bg-red-100 text-red-800 border border-red-200',
    'Alta': 'bg-orange-100 text-orange-800 border border-orange-200',
    'Média': 'bg-yellow-100 text-yellow-800 border border-yellow-200',
    'Baixa': 'bg-green-100 text-green-800 border border-green-200',
  }
  return classes[priority as keyof typeof classes] || 'bg-gray-100 text-gray-700'
}

const statusClass = (status: string) => {
  const classes = {
    'ABERTO': 'bg-blue-100 text-blue-800',
    'AGUARDANDO RESP': 'bg-yellow-100 text-yellow-800',
    'EM ANDAMENTO': 'bg-purple-100 text-purple-800',
    'REALIZADO': 'bg-cyan-100 text-cyan-800',
    'CONCLUÍDO': 'bg-green-100 text-green-800',
    'CANCELADO': 'bg-red-100 text-red-800',
  }
  return classes[status as keyof typeof classes] || 'bg-gray-100 text-gray-700'
}

const formatDate = (date: string) => {
  try {
    return format(new Date(date), 'dd/MM/yyyy HH:mm')
  } catch {
    return date
  }
}

const loadTasks = async () => {
  loading.value = true
  try {
    const params: any = {}
    
    if (filters.value.search) params.search = filters.value.search
    if (filters.value.status) params.status = filters.value.status
    if (filters.value.urgencia) params.urgencia = filters.value.urgencia

    const data = await tasksApi.getAll(params)
    tasks.value = Array.isArray(data) ? data : []
  } catch (err: any) {
    console.error('Erro ao carregar chamados:', err)
    uiStore.showToast('error', 'Erro ao carregar chamados')
    tasks.value = []
  } finally {
    loading.value = false
  }
}

// 🆕 Funções para abrir/fechar modals
const openCommentModal = (task: Task) => {
  selectedTask.value = task
  showCommentModal.value = true
}

const closeCommentModal = () => {
  showCommentModal.value = false
  // Aguarda animação antes de limpar
  setTimeout(() => {
    selectedTask.value = null
  }, 300)
}

const openStatusModal = (task: Task) => {
  selectedTask.value = task
  showStatusModal.value = true
}

const closeStatusModal = () => {
  showStatusModal.value = false
  // Aguarda animação antes de limpar
  setTimeout(() => {
    selectedTask.value = null
  }, 300)
}

// 🆕 Handlers dos eventos dos modals
const handleCommentAdded = (comentario: any) => {
  uiStore.showToast('success', 'Comentário adicionado com sucesso!')
  // Opcional: recarregar lista para atualizar contadores
  loadTasks()
}

const handleStatusChanged = (statusChange: any) => {
  uiStore.showToast('success', 'Status alterado com sucesso!')
  
  // Atualiza o status localmente sem recarregar tudo
  if (selectedTask.value) {
    const selectedTaskId = selectedTask.value.id
    const taskIndex = tasks.value.findIndex(t => t.id === selectedTaskId)
    if (taskIndex !== -1 && tasks.value[taskIndex]) {
      tasks.value[taskIndex]!.status = statusChange.status
    }
  }
  
  // Opcional: recarregar lista completa
  // loadTasks()
}

onMounted(() => {
  loadTasks()
})
</script>