<script setup lang="ts">
import { ref, watch } from 'vue'
import FileUploadArea from '../ui/FileUploadArea.vue'
import { tasksApi } from '@/api'

interface Props {
  isOpen: boolean
  chamadoId: number
}

interface Comentario {
  id: number
  texto: string
  autor: string
  data_criacao: string
  fotos: string[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'close': []
  'comment-added': [comentario: Comentario]
}>()

const comentario = ref('')
const files = ref<File[]>([])
const isSubmitting = ref(false)
const error = ref('')

// Limpa o formulário quando o modal abre
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    comentario.value = ''
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
  // Validação
  if (!comentario.value.trim()) {
    error.value = 'O comentário não pode estar vazio'
    return
  }

  isSubmitting.value = true
  error.value = ''

  try {
    // Sempre usa FormData para manter compatibilidade com fotos
    const formData = new FormData()
    formData.append('texto', comentario.value.trim())
    
    // Adiciona fotos se houver
    console.log('📸 Total de fotos:', files.value.length)
    files.value.forEach((file, index) => {
      console.log(`📸 Foto ${index + 1}:`, {
        name: file.name,
        type: file.type,
        size: file.size
      })
      formData.append('fotos', file)
    })
    
    console.log('📤 Enviando comentário...')
    const response = await tasksApi.addComment(props.chamadoId, formData)
    console.log('Resposta:', response)

    if (response.success) {
      emit('comment-added', response.comentario)
      emit('close')
    } else {
      error.value = 'Erro ao adicionar comentário. Tente novamente.'
    }
  } catch (err: any) {
    console.error('❌ Erro ao adicionar comentário:', err)
    console.error('Detalhes:', {
      status: err.response?.status,
      data: err.response?.data
    })
    
    // Mostra erros específicos do backend
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
    } else {
      error.value = err.response?.data?.message || err.response?.data?.detail || 'Erro ao adicionar comentário. Tente novamente.'
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
            <h2 class="text-xl font-semibold text-gray-900">
              Adicionar Comentário
            </h2>
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

            <!-- Textarea para Comentário -->
            <div>
              <label for="comentario" class="block text-sm font-medium text-gray-700 mb-2">
                Comentário <span class="text-red-500">*</span>
              </label>
              <textarea
                id="comentario"
                v-model="comentario"
                rows="5"
                :disabled="isSubmitting"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none disabled:bg-gray-50 disabled:cursor-not-allowed"
                placeholder="Descreva sua observação ou atualização sobre este chamado..."
              ></textarea>
              <p class="mt-1 text-sm text-gray-500">
                Adicione informações relevantes sobre o andamento do chamado
              </p>
            </div>

            <!-- FileUploadArea para Fotos -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">
                Anexar Fotos (opcional)
              </label>
              <FileUploadArea
                accept="image/*"
                :max-size="5"
                :multiple="true"
                :max-files="5"
                :disabled="isSubmitting"
                @files-selected="handleFilesSelected"
                @files-removed="handleFilesRemoved"
              />
              <p class="mt-1 text-sm text-gray-500">
                Você pode anexar até 5 fotos (máx. 5MB cada)
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
              :disabled="isSubmitting || !comentario.trim()"
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
              <span>{{ isSubmitting ? 'Adicionando...' : 'Adicionar Comentário' }}</span>
            </button>
          </div>
        </div>
      </Transition>
    </div>
  </Transition>
</template>