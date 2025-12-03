<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from 'vue'
import { Upload, X, FileText, Image as ImageIcon } from 'lucide-vue-next'

interface Props {
  accept?: string
  maxSize?: number // em MB
  multiple?: boolean
  maxFiles?: number
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  accept: 'image/*,.pdf',
  maxSize: 10,
  multiple: true,
  maxFiles: 10,
  disabled: false
})

const emit = defineEmits<{
  'files-selected': [files: File[]]
  'files-removed': [files: File[]]
}>()

const selectedFiles = ref<File[]>([])
const isDragging = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)
const previewUrls = ref<Map<string, string>>(new Map())

// Computed para formatar tipos aceitos
const acceptedTypesText = computed(() => {
  if (props.accept.includes('image/*') && props.accept.includes('.pdf')) {
    return 'Imagens (JPG, PNG, GIF, WEBP) ou PDFs'
  } else if (props.accept.includes('image/*')) {
    return 'Imagens (JPG, PNG, GIF, WEBP)'
  } else if (props.accept.includes('.pdf')) {
    return 'PDFs'
  }
  return 'Arquivos'
})

// Validar arquivo
const validateFile = (file: File): { valid: boolean; error?: string } => {
  // Validar tamanho
  const fileSizeMB = file.size / (1024 * 1024)
  if (fileSizeMB > props.maxSize) {
    return {
      valid: false,
      error: `${file.name} excede o tamanho máximo de ${props.maxSize}MB`
    }
  }

  // Validar tipo
  const acceptedTypes = props.accept.split(',').map(t => t.trim())
  const fileExtension = '.' + file.name.split('.').pop()?.toLowerCase()
  const isImage = file.type.startsWith('image/')
  
  const isValidType = acceptedTypes.some(type => {
    if (type === 'image/*' && isImage) return true
    if (type === fileExtension) return true
    if (type === file.type) return true
    return false
  })

  if (!isValidType) {
    return {
      valid: false,
      error: `${file.name} não é um tipo de arquivo aceito`
    }
  }

  return { valid: true }
}

// Criar preview para imagens
const createPreview = (file: File) => {
  if (file.type.startsWith('image/')) {
    const url = URL.createObjectURL(file)
    previewUrls.value.set(file.name, url)
  }
}

// Processar arquivos
const processFiles = (files: FileList | File[]) => {
  const filesArray = Array.from(files)
  const validFiles: File[] = []
  
  for (const file of filesArray) {
    if (!file) continue

    // Verificar limite de arquivos
    if (selectedFiles.value.length + validFiles.length >= props.maxFiles) {
      alert(`Limite máximo de ${props.maxFiles} arquivos atingido`)
      break
    }

    // Verificar se já existe
    if (selectedFiles.value.some(f => f.name === file.name && f.size === file.size)) {
      continue
    }

    // Validar arquivo
    const validation = validateFile(file)
    if (!validation.valid) {
      alert(validation.error)
      continue
    }

    validFiles.push(file)
    createPreview(file)
  }

  if (validFiles.length > 0) {
    selectedFiles.value.push(...validFiles)
    emit('files-selected', [...selectedFiles.value])
  }
}

// Handlers
const handleFileSelect = (event: Event) => {
  if (props.disabled) return
  
  const target = event.target as HTMLInputElement
  if (target.files && target.files.length > 0) {
    processFiles(target.files)
    target.value = '' // Reset input
  }
}

const handleDragEnter = (event: DragEvent) => {
  if (props.disabled) return
  event.preventDefault()
  isDragging.value = true
}

const handleDragLeave = (event: DragEvent) => {
  if (props.disabled) return
  event.preventDefault()
  isDragging.value = false
}

const handleDragOver = (event: DragEvent) => {
  if (props.disabled) return
  event.preventDefault()
}

const handleDrop = (event: DragEvent) => {
  if (props.disabled) return
  event.preventDefault()
  isDragging.value = false

  if (event.dataTransfer?.files) {
    processFiles(event.dataTransfer.files)
  }
}

const removeFile = (index: number) => {
  if (props.disabled) return
  
  const file = selectedFiles.value[index]
  if (!file) return
  
  // Revogar URL do preview
  const previewUrl = previewUrls.value.get(file.name)
  if (previewUrl) {
    URL.revokeObjectURL(previewUrl)
    previewUrls.value.delete(file.name)
  }

  selectedFiles.value.splice(index, 1)
  emit('files-removed', [...selectedFiles.value])
}

const openFileDialog = () => {
  if (props.disabled) return
  fileInput.value?.click()
}

// Formatar tamanho do arquivo
const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
}

// Limpar ao desmontar
onBeforeUnmount(() => {
  previewUrls.value.forEach(url => URL.revokeObjectURL(url))
})
</script>

<template>
  <div class="w-full">
    <!-- Área de Upload -->
    <div
      @dragenter="handleDragEnter"
      @dragleave="handleDragLeave"
      @dragover="handleDragOver"
      @drop="handleDrop"
      @click="openFileDialog"
      :class="[
        'border-2 border-dashed rounded-lg p-8 text-center transition-all',
        disabled 
          ? 'border-gray-200 bg-gray-50 cursor-not-allowed opacity-60'
          : isDragging
            ? 'border-blue-500 bg-blue-50 cursor-pointer'
            : 'border-gray-300 hover:border-blue-400 hover:bg-gray-50 cursor-pointer'
      ]"
    >
      <input
        ref="fileInput"
        type="file"
        :accept="accept"
        :multiple="multiple"
        :disabled="disabled"
        @change="handleFileSelect"
        class="hidden"
      />

      <Upload :class="[
        'w-12 h-12 mx-auto mb-4',
        disabled ? 'text-gray-300' : isDragging ? 'text-blue-500' : 'text-gray-400'
      ]" />

      <p class="text-lg font-medium text-gray-700 mb-2">
        {{ isDragging ? 'Solte os arquivos aqui' : 'Arraste arquivos ou clique para selecionar' }}
      </p>
      
      <p class="text-sm text-gray-500">
        {{ acceptedTypesText }} • Máx {{ maxSize }}MB por arquivo
      </p>
      
      <p v-if="multiple" class="text-xs text-gray-400 mt-2">
        Limite: {{ maxFiles }} arquivos
      </p>
    </div>

    <!-- Lista de Arquivos Selecionados -->
    <div v-if="selectedFiles.length > 0" class="mt-4 space-y-2">
      <h4 class="text-sm font-medium text-gray-700 mb-2">
        Arquivos Selecionados ({{ selectedFiles.length }})
      </h4>

      <div
        v-for="(file, index) in selectedFiles"
        :key="`${file.name}-${index}`"
        class="flex items-center gap-3 p-3 bg-white border border-gray-200 rounded-lg hover:border-gray-300 transition-colors"
      >
        <!-- Preview ou Ícone -->
        <div class="flex-shrink-0">
          <img
            v-if="previewUrls.has(file.name)"
            :src="previewUrls.get(file.name)"
            :alt="file.name"
            class="w-12 h-12 object-cover rounded"
          />
          <div v-else class="w-12 h-12 bg-gray-100 rounded flex items-center justify-center">
            <FileText v-if="file.type.includes('pdf')" class="w-6 h-6 text-red-500" />
            <ImageIcon v-else class="w-6 h-6 text-gray-400" />
          </div>
        </div>

        <!-- Informações do Arquivo -->
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium text-gray-900 truncate">
            {{ file.name }}
          </p>
          <p class="text-xs text-gray-500">
            {{ formatFileSize(file.size) }}
          </p>
        </div>

        <!-- Botão Remover -->
        <button
          @click.stop="removeFile(index)"
          type="button"
          :disabled="disabled"
          class="flex-shrink-0 p-1 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          title="Remover arquivo"
        >
          <X class="w-5 h-5" />
        </button>
      </div>
    </div>
  </div>
</template>