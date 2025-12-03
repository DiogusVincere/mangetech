<template>
  <div class="fixed top-4 right-4 z-50 space-y-3">
    <div
      v-for="toast in uiStore.toasts"
      :key="toast.id"
      :class="[
        'min-w-[300px] rounded-lg shadow-lg p-4 flex items-start gap-3',
        toastClass(toast.type)
      ]"
    >
      <component :is="toastIcon(toast.type)" :size="20" class="flex-shrink-0 mt-0.5" />
      <p class="text-sm font-medium flex-1">{{ toast.message }}</p>
      <button @click="uiStore.removeToast(toast.id)" class="flex-shrink-0 hover:opacity-70">
        <X :size="16" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useUiStore } from '@/stores/ui'
import { CheckCircle, XCircle, AlertCircle, Info, X } from 'lucide-vue-next'

const uiStore = useUiStore()

const toastClass = (type: string) => {
  const classes = {
    success: 'bg-green-50 text-green-800 border border-green-200',
    error: 'bg-red-50 text-red-800 border border-red-200',
    warning: 'bg-yellow-50 text-yellow-800 border border-yellow-200',
    info: 'bg-blue-50 text-blue-800 border border-blue-200',
  }
  return classes[type as keyof typeof classes] || classes.info
}

const toastIcon = (type: string) => {
  const icons = {
    success: CheckCircle,
    error: XCircle,
    warning: AlertCircle,
    info: Info,
  }
  return icons[type as keyof typeof icons] || Info
}
</script>