<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import FileUploadArea from '../ui/FileUploadArea.vue'
import { tasksApi } from '@/api'

interface Props {
  isOpen: boolean
  chamadoId: number
  currentStatus: string
}

interface StatusChange {
  id?: number
  status: string
  descricao: string
  data_mudanca: string
  usuario: string
  fotos: string[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'close': []
  'status-changed': [statusChange: StatusChange]
}>()

const statusOptions = [
  { value: 'ABERTO', label: 'Aberto', color: 'blue' },
  { value: 'AGUARDANDO RESP', label: 'Aguardando Resposta', color: 'yellow' },
  { value: 'EM ANDAMENTO', label: 'Em Andamento', color: 'purple' },
  { value: 'REALIZADO', label: 'Realizado', color: 'green' },
  { value: 'CONCLUÍDO', label: 'Concluído', color: 'gray' },
  { value: 'CANCELADO', label: 'Cancelado', color: 'red' }
]

const selectedStatus = ref('')
const descricao = ref('')
const files = ref<File[]>([])
const isSubmitting = ref(false)
const error = ref('')

// Filtra status disponíveis (não mostra o status atual)
const availableStatusOptions = computed(() => {
  return statusOptions.filter(option => option.value !== props.currentStatus)
})

// Limpa o formulário quando o modal abre
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    selectedStatus.value = ''
    descricao.value = ''
    files.value = []
    error.value = ''
  }
})

const handleFilesSelected = (selectedFiles: File[]) => {
  files.value = selectedFiles
}

const handleFilesRemoved = (remainingFiles: File[]) => {
  files.value = remainingFiles
}

const handleClose = () => {
  if (!isSubmitting.value) {
    emit('close')
  }
}

const handleSubmit = async () => {
  // Validações
  if (!selectedStatus.value) {
    error.value = 'Selecione um status'
    return
  }

  if (!descricao.value.trim()) {
    error.value = 'A descrição é obrigatória'
    return
  }

  
  if (descricao.value.trim().length < 10) {
    error.value = 'A descrição deve ter no mínimo 10 caracteres'
    return
  }

  isSubmitting.value = true
  error.value = ''

  try {
    // Sempre usa FormData para manter compatibilidade com fotos
    const formData = new FormData()
    formData.append('status', selectedStatus.value)
    formData.append('descricao', descricao.value.trim())
    
    // Adiciona fotos se houver
    files.value.forEach(file => {
      formData.append('fotos', file)
    })

    const response = await tasksApi.changeStatus(props.chamadoId, formData)

    if (response.success) {
      emit('status-changed', {
        status: selectedStatus.value,
        descricao: descricao.value.trim(),
        data_mudanca: new Date().toISOString(),
        usuario: 'Você',
        fotos: []
      })
      emit('close')
    } else {
      error.value = response.message || 'Erro ao mudar status. Tente novamente.'
    }
  } catch (err: any) {
    console.error('❌ Erro ao mudar status:', err)
    
    // Mostra erro específico do backend
    if (err.response?.data?.errors) {
      const errors = err.response.data.errors
      const errorMessages = Object.entries(errors)
        .map(([field, messages]: [string, any]) => {
          if (Array.isArray(messages)) {
            return messages.join(', ')
          }
          return messages
        })
        .join(' | ')
      
      error.value = errorMessages
    } else if (err.response?.data?.message) {
      error.value = err.response.data.message
    } else if (err.response?.data?.detail) {
      error.value = err.response.data.detail
    } else {
      error.value = 'Erro ao mudar status. Tente novamente.'
    }
  } finally {
    isSubmitting.value = false
  }
}

const handleBackdropClick = (e: MouseEvent) => {
  if (e.target === e.currentTarget) {
    handleClose()
  }
}

const handleEscKey = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.isOpen && !isSubmitting.value) {
    handleClose()
  }
}

// Adiciona listener para ESC
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    window.addEventListener('keydown', handleEscKey)
  } else {
    window.removeEventListener('keydown', handleEscKey)
  }
})

// Cor do badge de status
const getStatusColor = (status: string) => {
  const option = statusOptions.find(opt => opt.value === status)
  return option?.color || 'gray'
}

const getStatusColorClasses = (color: string) => {
  const colors: Record<string, string> = {
    blue: 'bg-blue-100 text-blue-800 border-blue-200',
    yellow: 'bg-yellow-100 text-yellow-800 border-yellow-200',
    purple: 'bg-purple-100 text-purple-800 border-purple-200',
    green: 'bg-green-100 text-green-800 border-green-200',
    gray: 'bg-gray-100 text-gray-800 border-gray-200',
    red: 'bg-red-100 text-red-800 border-red-200'
  }
  return colors[color] || colors.gray
}
</script>

<template>
  <Transition
    enter-active-class="transition-opacity duration-300"
    leave-active-class="transition-opacity duration-200"
    enter-from-class="opacity-0"
    leave-to-class="opacity-0"
  >
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
      @click="handleBackdropClick"
    >
      <Transition
        enter-active-class="transition-all duration-300"
        leave-active-class="transition-all duration-200"
        enter-from-class="opacity-0 scale-95"
        leave-to-class="opacity-0 scale-95"
      >
        <div
          v-if="isOpen"
          class="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
        >
          <!-- Header -->
          <div class="flex items-center justify-between p-6 border-b border-gray-200">
            <div>
              <h2 class="text-xl font-semibold text-gray-900">
                Mudar Status do Chamado
              </h2>
              <p class="text-sm text-gray-500 mt-1">
                Status atual: 
                <span 
                  :class="[
                    'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ml-1',
                    getStatusColorClasses(getStatusColor(currentStatus))
                  ]"
                >
                  {{ statusOptions.find(opt => opt.value === currentStatus)?.label || currentStatus }}
                </span>
              </p>
            </div>
            <button
              @click="handleClose"
              :disabled="isSubmitting"
              class="text-gray-400 hover:text-gray-600 transition-colors disabled:opacity-50"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Body -->
          <div class="p-6 space-y-4">
            <!-- Mensagem de Erro -->
            <div
              v-if="error"
              class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-start"
            >
              <svg class="w-5 h-5 mr-2 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
              </svg>
              <span>{{ error }}</span>
            </div>

            <!-- Select de Status -->
            <div>
              <label for="status" class="block text-sm font-medium text-gray-700 mb-2">
                Novo Status <span class="text-red-500">*</span>
              </label>
              <select
                id="status"
                v-model="selectedStatus"
                :disabled="isSubmitting"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:cursor-not-allowed"
              >
                <option value="" disabled>Selecione um status</option>
                <option 
                  v-for="option in availableStatusOptions" 
                  :key="option.value" 
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>

            <!-- Textarea para Descrição -->
            <div>
              <label for="descricao" class="block text-sm font-medium text-gray-700 mb-2">
                Descrição da Mudança <span class="text-red-500">*</span>
              </label>
              <textarea
                id="descricao"
                v-model="descricao"
                rows="5"
                :disabled="isSubmitting"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none disabled:bg-gray-50 disabled:cursor-not-allowed"
                placeholder="Descreva o que foi feito ou o motivo da mudança de status... (mínimo 10 caracteres)"
              ></textarea>
              <div class="flex items-center justify-between mt-1">
                <p class="text-sm text-gray-500">
                  Informe detalhes sobre o trabalho realizado ou a razão da mudança
                </p>
                <p class="text-xs text-gray-400">
                  {{ descricao.length }}/10 caracteres
                </p>
              </div>
            </div>

            <!-- FileUploadArea para Fotos -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Fotos do Trabalho Realizado (opcional)
              </label>
              <FileUploadArea
                accept="image/*"
                :max-size="5"
                :multiple="true"
                :max-files="10"
                :disabled="isSubmitting"
                @files-selected="handleFilesSelected"
                @files-removed="handleFilesRemoved"
              />
              <p class="mt-1 text-sm text-gray-500">
                Você pode anexar até 10 fotos do trabalho realizado (máx. 5MB cada)
              </p>
            </div>
          </div>

          <!-- Footer -->
          <div class="flex items-center justify-end gap-3 p-6 border-t border-gray-200 bg-gray-50">
            <button
              @click="handleClose"
              :disabled="isSubmitting"
              class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Cancelar
            </button>
            <button
              @click="handleSubmit"
              :disabled="isSubmitting || !selectedStatus || descricao.trim().length < 10"
              class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              <svg
                v-if="isSubmitting"
                class="animate-spin h-5 w-5"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              <span>{{ isSubmitting ? 'Salvando...' : 'Confirmar Mudança' }}</span>
            </button>
          </div>
        </div>
      </Transition>
    </div>
  </Transition>
</template>