// src/stores/ui.ts
import { defineStore } from 'pinia'
import { ref } from 'vue'

interface Toast {
  id: number
  type: 'success' | 'error' | 'info' | 'warning'
  message: string
}

export const useUiStore = defineStore('ui', () => {
  const toasts = ref<Toast[]>([])
  const sidebarOpen = ref(true)
  let toastId = 0

  function showToast(type: Toast['type'], message: string) {
    const toast: Toast = {
      id: ++toastId,
      type,
      message,
    }
    
    toasts.value.push(toast)
    
    setTimeout(() => {
      removeToast(toast.id)
    }, 5000)
  }

  function removeToast(id: number) {
    const index = toasts.value.findIndex(t => t.id === id)
    if (index !== -1) {
      toasts.value.splice(index, 1)
    }
  }

  function toggleSidebar() {
    sidebarOpen.value = !sidebarOpen.value
  }

  return {
    toasts,
    sidebarOpen,
    showToast,
    removeToast,
    toggleSidebar,
  }
})
