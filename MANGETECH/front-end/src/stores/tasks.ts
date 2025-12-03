// src/stores/tasks.ts - CORRIGIDO
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { tasksApi } from '@/api'
import type { Task } from '@/types'
import router from '@/router'

export const useTasksStore = defineStore('tasks', () => {
  const tasks = ref<Task[]>([])
  const currentTask = ref<Task | null>(null)
  const loading = ref(false)
  const totalTasks = ref(0)
  const currentPage = ref(1)
  const perPage = ref(50)

  // Fetch all tasks with filters
  async function fetchTasks(filters?: any) {
    loading.value = true
    try {
      const data = await tasksApi.getAll(filters)
      tasks.value = data // Já vem com IDs como string
      totalTasks.value = tasks.value.length
      
      console.log('Tasks carregadas:', tasks.value.length)
      console.log('Primeira task:', tasks.value[0])
    } catch (error) {
      console.error('❌ Erro ao buscar tarefas:', error)
      tasks.value = []
    } finally {
      loading.value = false
    }
  }

  // Fetch single task
  async function fetchTask(id: number | string) {
    loading.value = true
    try {
      const data = await tasksApi.getById(id)
      currentTask.value = data
      return data
    } catch (error) {
      console.error('❌ Erro ao buscar tarefa:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // Create task
  async function createTask(taskData: any) {
    loading.value = true
    try {
      const newTask = await tasksApi.create(taskData)
      tasks.value.unshift(newTask)
      totalTasks.value++
      return newTask
    } catch (error) {
      console.error('❌ Erro ao criar tarefa:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // Update task status
  async function updateTaskStatus(id: number | string, status: string, descricao: string, fotos?: File[]) {
    loading.value = true
    try {
      const updatedTask = await tasksApi.updateStatus(id, status, descricao, fotos)
      
      // Update in list
      const index = tasks.value.findIndex(t => String(t.id) === String(id))
      if (index !== -1) {
        tasks.value[index] = updatedTask
      }
      
      // Update current task
      if (currentTask.value && String(currentTask.value.id) === String(id)) {
        currentTask.value = updatedTask
      }
      
      return updatedTask
    } catch (error) {
      console.error('❌ Erro ao atualizar status:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // Add comment
  async function addComment(id: number | string, texto: string, fotos?: File[]) {
    try {
      const formData = new FormData()
      formData.append('texto', texto)
      
      if (fotos && fotos.length > 0) {
        fotos.forEach(foto => formData.append('fotos', foto))
      }
      
      await tasksApi.addComment(id, formData)
      
      // Reload task to get updated comments
      if (currentTask.value && String(currentTask.value.id) === String(id)) {
        await fetchTask(id)
      }
    } catch (error) {
      console.error('❌ Erro ao adicionar comentário:', error)
      throw error
    }
  }

  // Change status (usado pelos modals)
  async function changeStatus(id: number | string, status: string, descricao: string, fotos?: File[]) {
    try {
      const formData = new FormData()
      formData.append('status', status)
      formData.append('descricao', descricao)
      
      if (fotos && fotos.length > 0) {
        fotos.forEach(foto => formData.append('fotos', foto))
      }
      
      const result = await tasksApi.changeStatus(id, formData)
      
      // Update in list
      const index = tasks.value.findIndex(t => String(t.id) === String(id))
      if (index !== -1 && result.chamado) {
        tasks.value[index] = { ...result.chamado, id: String(result.chamado.id) }
      }
      
      // Update current task
      if (currentTask.value && String(currentTask.value.id) === String(id) && result.chamado) {
        currentTask.value = { ...result.chamado, id: String(result.chamado.id) }
      }
      
      return result
    } catch (error) {
      console.error('❌ Erro ao mudar status:', error)
      throw error
    }
  }

  // Get statistics
  async function getStatistics() {
    try {
      return await tasksApi.getStatistics()
    } catch (error) {
      console.error('❌ Erro ao buscar estatísticas:', error)
      throw error
    }
  }

  // Export CSV
  async function exportCSV(filters?: any) {
    try {
      const blob = await tasksApi.exportCSV(filters)
      
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `chamados_${new Date().toISOString().split('T')[0]}.csv`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
    } catch (error) {
      console.error('❌ Erro ao exportar CSV:', error)
      throw error
    }
  }

  // Navigate to task
  const navigateToTask = (taskId: number | string) => {
    const stringId = String(taskId)
    console.log('🔗 Navegando para task:', stringId)
    router.push(`/tasks/${stringId}`)
  }

  // Clear current task
  function clearCurrentTask() {
    currentTask.value = null
  }

  return {
    tasks,
    currentTask,
    loading,
    totalTasks,
    currentPage,
    perPage,
    fetchTasks,
    fetchTask,
    createTask,
    updateTaskStatus,
    addComment,
    changeStatus,
    getStatistics,
    exportCSV,
    clearCurrentTask,
    navigateToTask
  }
})