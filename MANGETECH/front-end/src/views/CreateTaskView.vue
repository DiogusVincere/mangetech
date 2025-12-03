<!-- src/views/CreateTaskView.vue - CORRIGIDO COM DEBUGGING -->
<template>
  <div class="max-w-4xl mx-auto px-4 py-6">
    <!-- Header -->
    <div class="flex items-center mb-8">
      <router-link to="/tasks" class="p-2 hover:bg-gray-100 rounded-lg transition mr-4">
        <ArrowLeft :size="20" class="text-gray-600" />
      </router-link>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Criar Novo Chamado</h1>
        <p class="text-sm text-gray-500 mt-1">Preencha as informações do chamado</p>
      </div>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Título -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <label for="titulo" class="block text-sm font-semibold text-gray-700 mb-2">
          Título <span class="text-red-500">*</span>
        </label>
        <input 
          v-model="formData.titulo" 
          type="text" 
          id="titulo" 
          required 
          minlength="5" 
          :class="[
            'w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition',
            errors.titulo ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
          ]" 
          placeholder="Descreva brevemente o problema" 
          @blur="validateField('titulo')" 
        />
        <p v-if="errors.titulo" class="text-sm text-red-600 mt-1 flex items-center">
          <AlertCircle :size="14" class="mr-1" />
          {{ errors.titulo }}
        </p>
        <p v-else class="text-xs text-gray-500 mt-1">
          Mínimo 5 caracteres
        </p>
      </div>

      <!-- Ativo e Ambiente -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Ativo -->
          <div>
            <label for="ativo" class="block text-sm font-semibold text-gray-700 mb-2">
              Ativo/Equipamento <span class="text-red-500">*</span>
            </label>
            
            <!-- Loading State -->
            <div v-if="loadingAtivos" class="w-full px-4 py-3 border border-gray-300 rounded-lg bg-gray-50 flex items-center gap-2">
              <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
              <span class="text-sm text-gray-500">Carregando ativos...</span>
            </div>
            
            <!-- Select com Ativos -->
            <div v-else-if="ativos.length > 0" class="relative">
              <select 
                v-model="formData.ativo" 
                id="ativo" 
                required
                class="w-full px-4 py-3 pr-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition appearance-none bg-white"
              >
                <option value="">Selecione um ativo</option>
                <option 
                  v-for="asset in ativos" 
                  :key="asset.id" 
                  :value="asset.codigo"
                >
                  {{ asset.codigo }} - {{ asset.nome }} ({{ asset.ambiente }})
                </option>
              </select>
              <Package :size="18" class="absolute right-3 top-3.5 text-gray-400 pointer-events-none" />
            </div>
            
            <!-- Fallback: Input Manual -->
            <div v-else>
              <input 
                v-model="formData.ativo" 
                type="text" 
                id="ativo" 
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                placeholder="Digite o código ou nome do equipamento" 
              />
              <p class="text-xs text-amber-600 mt-1 flex items-center gap-1">
                <AlertCircle :size="14" />
                Nenhum ativo cadastrado. Digite manualmente ou 
                <router-link to="/assets/create" class="underline hover:text-amber-700">
                  cadastre aqui
                </router-link>
              </p>
            </div>
            
            <!-- Debug Info (remover em produção) -->
            <p class="text-xs text-gray-400 mt-1">
              {{ ativos.length }} ativo(s) disponível(is)
            </p>
          </div>

          <!-- Ambiente -->
          <div>
            <label for="ambiente" class="block text-sm font-semibold text-gray-700 mb-2">
              Ambiente/Localização <span class="text-red-500">*</span>
            </label>
            <input 
              v-model="formData.ambiente" 
              type="text" 
              id="ambiente" 
              required
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="Ex: Sala 102 - Administrativo" 
            />
            <p class="text-xs text-gray-500 mt-1">
              Onde o equipamento está localizado
            </p>
          </div>
        </div>
      </div>

      <!-- Descrição -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <label for="descricao" class="block text-sm font-semibold text-gray-700 mb-2">
          Descrição <span class="text-red-500">*</span>
        </label>
        <textarea 
          v-model="formData.descricao" 
          id="descricao" 
          required 
          minlength="15" 
          rows="5" 
          :class="[
            'w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition resize-none',
            errors.descricao ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
          ]" 
          placeholder="Descreva detalhadamente o problema (mínimo 15 caracteres)"
          @blur="validateField('descricao')"
        ></textarea>
        <div class="flex items-center justify-between mt-2">
          <p v-if="errors.descricao" class="text-sm text-red-600 flex items-center">
            <AlertCircle :size="14" class="mr-1" />
            {{ errors.descricao }}
          </p>
          <p v-else class="text-xs text-gray-500">
            {{ formData.descricao.length }} / 15 caracteres mínimos
          </p>
        </div>
      </div>

      <!-- Data Sugerida e Urgência -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Data Sugerida -->
          <div>
            <label for="data-sugerida" class="block text-sm font-semibold text-gray-700 mb-2">
              Data Sugerida de Resolução
            </label>
            <input 
              v-model="formData.data_sugerida" 
              type="datetime-local" 
              id="data-sugerida"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition" 
            />
            <p class="text-xs text-gray-500 mt-1">
              Quando você gostaria que fosse resolvido
            </p>
          </div>

          <!-- Urgência -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 mb-2">
              Nível de Urgência <span class="text-red-500">*</span>
            </label>
            <div class="grid grid-cols-4 gap-2">
              <button 
                v-for="nivel in ['Baixa', 'Média', 'Alta', 'Crítico']" 
                :key="nivel" 
                type="button"
                @click="formData.urgencia = nivel" 
                :class="[
                  'px-3 py-3 text-sm font-medium rounded-lg border-2 transition-all',
                  formData.urgencia === nivel
                    ? 'border-blue-500 bg-blue-50 text-blue-700 shadow-sm'
                    : 'border-gray-300 hover:border-gray-400 text-gray-700'
                ]"
              >
                {{ nivel }}
              </button>
            </div>
            <p v-if="errors.urgencia" class="text-sm text-red-600 mt-2 flex items-center">
              <AlertCircle :size="14" class="mr-1" />
              {{ errors.urgencia }}
            </p>
          </div>
        </div>
      </div>

      <!-- Responsáveis -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <label class="block text-sm font-semibold text-gray-700 mb-3">
          Responsáveis (opcional)
        </label>
        <div class="relative" ref="dropdownContainer">
          <input 
            v-model="searchResponsavel" 
            type="text" 
            placeholder="Buscar usuários..."
            class="w-full px-4 py-3 pr-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            @input="handleResponsavelSearch" 
            @focus="showResponsavelDropdown = true" 
          />
          <Search :size="18" class="absolute right-3 top-3.5 text-gray-400 pointer-events-none" />

          <!-- Dropdown de Responsáveis -->
          <div 
            v-if="showResponsavelDropdown && filteredResponsaveis.length > 0"
            class="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-auto"
          >
            <button 
              v-for="user in filteredResponsaveis" 
              :key="user.id" 
              type="button" 
              @click="toggleResponsavel(user)"
              :class="[
                'w-full text-left px-4 py-3 transition border-b border-gray-100 last:border-b-0 flex items-center justify-between',
                isResponsavelSelected(user.id) ? 'bg-blue-50' : 'hover:bg-gray-50'
              ]"
            >
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                  {{ getInitials(user) }}
                </div>
                <div>
                  <div class="font-medium text-gray-900">{{ getFullName(user) }}</div>
                  <div class="text-xs text-gray-500">{{ user.email }}</div>
                </div>
              </div>
              <CheckCircle v-if="isResponsavelSelected(user.id)" :size="20" class="text-blue-600" />
            </button>
          </div>
        </div>

        <!-- Responsáveis Selecionados -->
        <div v-if="selectedResponsaveis.length > 0" class="mt-4 flex flex-wrap gap-2">
          <div 
            v-for="user in selectedResponsaveis" 
            :key="user.id"
            class="flex items-center gap-2 px-3 py-2 bg-blue-50 border border-blue-200 rounded-lg"
          >
            <div class="w-6 h-6 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-semibold text-xs">
              {{ getInitials(user) }}
            </div>
            <span class="text-sm font-medium text-blue-900">{{ getFullName(user) }}</span>
            <button 
              type="button" 
              @click="removeResponsavel(user.id)"
              class="p-0.5 hover:bg-blue-100 rounded transition"
            >
              <X :size="14" class="text-blue-600" />
            </button>
          </div>
        </div>

        <p class="text-xs text-gray-500 mt-2">
          Você pode adicionar múltiplos responsáveis
        </p>
      </div>

      <!-- Botões -->
      <div class="flex justify-end gap-4 pt-6">
        <router-link 
          to="/tasks"
          class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
        >
          Cancelar
        </router-link>
        <button 
          type="submit" 
          :disabled="loading || !isFormValid"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition shadow-sm flex items-center gap-2"
        >
          <span v-if="!loading">Criar Chamado</span>
          <span v-else class="flex items-center gap-2">
            <div class="loader"></div>
            Criando...
          </span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useTasksStore } from '@/stores/tasks'
import { useUiStore } from '@/stores/ui'
import { useAuthStore } from '@/stores/auth'
import { usersApi, assetsApi } from '@/api'
import {
  ArrowLeft,
  AlertCircle,
  Search,
  CheckCircle,
  X,
  Package
} from 'lucide-vue-next'
import type { Asset, User } from '@/types'

const router = useRouter()
const tasksStore = useTasksStore()
const uiStore = useUiStore()
const authStore = useAuthStore()

const formData = ref({
  titulo: '',
  ativo: '',
  ambiente: '',
  descricao: '',
  urgencia: 'Média',
  data_sugerida: '',
  responsaveis: [] as number[]
})

const errors = ref<Record<string, string>>({})
const loading = ref(false)
const loadingAtivos = ref(false)

// Responsáveis
const usuarios = ref<User[]>([])
const ativos = ref<Asset[]>([])
const searchResponsavel = ref('')
const selectedResponsaveis = ref<User[]>([])
const showResponsavelDropdown = ref(false)
const dropdownContainer = ref<HTMLElement | null>(null)

const filteredResponsaveis = computed(() => {
  if (!searchResponsavel.value) return usuarios.value.slice(0, 10)

  const query = searchResponsavel.value.toLowerCase()
  return usuarios.value.filter(user => {
    const fullName = getFullName(user).toLowerCase()
    return fullName.includes(query) || user.email.toLowerCase().includes(query)
  }).slice(0, 10)
})

const isFormValid = computed(() => {
  return formData.value.titulo.length >= 5 &&
    formData.value.ativo &&
    formData.value.ambiente &&
    formData.value.descricao.length >= 15 &&
    formData.value.urgencia
})

const validateField = (field: string) => {
  errors.value[field] = ''

  if (field === 'titulo' && formData.value.titulo.length < 5) {
    errors.value.titulo = 'O título deve ter pelo menos 5 caracteres'
  }

  if (field === 'descricao' && formData.value.descricao.length < 15) {
    errors.value.descricao = 'A descrição deve ter pelo menos 15 caracteres'
  }

  if (field === 'urgencia' && !formData.value.urgencia) {
    errors.value.urgencia = 'Selecione um nível de urgência'
  }
}

const handleResponsavelSearch = () => {
  showResponsavelDropdown.value = true
}

const toggleResponsavel = (user: User) => {
  const index = selectedResponsaveis.value.findIndex(u => u.id === user.id)
  if (index > -1) {
    selectedResponsaveis.value.splice(index, 1)
  } else {
    selectedResponsaveis.value.push(user)
  }
  searchResponsavel.value = ''
  showResponsavelDropdown.value = false
}

const removeResponsavel = (userId: number) => {
  selectedResponsaveis.value = selectedResponsaveis.value.filter(u => u.id !== userId)
}

const isResponsavelSelected = (userId: number) => {
  return selectedResponsaveis.value.some(u => u.id === userId)
}

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

const handleSubmit = async () => {
  validateField('titulo')
  validateField('descricao')
  validateField('urgencia')

  if (!isFormValid.value) {
    uiStore.showToast('error', 'Por favor, preencha todos os campos obrigatórios')
    return
  }

  loading.value = true

  try {
    const taskData = {
      titulo: formData.value.titulo,
      ativo: formData.value.ativo,
      ambiente: formData.value.ambiente,
      descricao: formData.value.descricao,
      urgencia: formData.value.urgencia,
      data_sugerida: formData.value.data_sugerida || undefined,
      responsaveis: selectedResponsaveis.value.map(u => u.id)
    }

    const createdTask = await tasksStore.createTask(taskData)
    uiStore.showToast('success', 'Chamado criado com sucesso!')
    router.push(`/tasks/${createdTask.id}`)
  } catch (error: any) {
    console.error('Erro ao criar chamado:', error)
    uiStore.showToast('error', error.response?.data?.message || 'Erro ao criar chamado')
  } finally {
    loading.value = false
  }
}

const loadUsuarios = async () => {
  try {
    const data = await usersApi.getAll()
    usuarios.value = Array.isArray(data) ? data.filter(user => user && user.id) : []
    console.log('Usuários carregados:', usuarios.value.length)
  } catch (error) {
    console.error('❌ Erro ao carregar usuários:', error)
    usuarios.value = []
  }
}

const loadAtivos = async () => {
  loadingAtivos.value = true
  try {
    console.log(' Iniciando carregamento de ativos...')
    
    const response = await assetsApi.getAll()
    console.log('Resposta recebida:', response)
    console.log('Tipo:', Array.isArray(response) ? 'Array' : typeof response)
    
    // Normalizar resposta
    let ativosList: Asset[] = []
    
    if (Array.isArray(response)) {
      ativosList = response
    } else if (response && typeof response === 'object') {
      if (response.results && Array.isArray(response.results)) {
        ativosList = response.results
      } else if (response.data && Array.isArray(response.data)) {
        ativosList = response.data
      }
    }
    
    // Filtrar objetos válidos
    ativos.value = ativosList.filter(asset => 
      asset && 
      typeof asset === 'object' && 
      asset.id && 
      asset.codigo && 
      asset.nome
    )
    
    console.log('Ativos processados:', ativos.value.length)
    if (ativos.value.length > 0) {
      console.log(' Primeiro ativo:', ativos.value[0])
    } else {
      console.warn('Nenhum ativo válido encontrado')
      uiStore.showToast('warning', 'Nenhum ativo cadastrado. Você pode digitar manualmente.')
    }
    
  } catch (error: any) {
    console.error('❌ Erro ao carregar ativos:', error)
    console.error('Detalhes:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status
    })
    ativos.value = []
    uiStore.showToast('warning', 'Erro ao carregar ativos. Digite manualmente.')
  } finally {
    loadingAtivos.value = false
  }
}

const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (dropdownContainer.value && !dropdownContainer.value.contains(target)) {
    showResponsavelDropdown.value = false
  }
}

onMounted(() => {
  console.log('🚀 CreateTaskView montado')
  loadUsuarios()
  loadAtivos()
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.loader {
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top: 3px solid #ffffff;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>