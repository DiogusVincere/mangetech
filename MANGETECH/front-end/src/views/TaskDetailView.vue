<template>
  <div class="space-y-6">
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando chamado...</p>
    </div>

    <div v-else-if="error" class="bg-white rounded-xl border border-red-200 shadow-sm p-6">
      <div class="text-center py-8">
        <div class="mx-auto w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-4">
          <AlertCircle :size="32" class="text-red-600" />
        </div>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar chamado</h3>
        <p class="text-gray-600 mb-4">{{ error }}</p>
        <button
          @click="$router.push('/tasks')"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          Voltar para Lista
        </button>
      </div>
    </div>

    <div v-else-if="task">
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-3">
          <button
            @click="$router.push('/tasks')"
            class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition"
          >
            <ArrowLeft :size="20" />
          </button>
          <div>
            <div class="flex items-center gap-2 mb-1">
              <h1 class="text-2xl font-bold text-gray-900">Chamado #{{ task.id }}</h1>
              <span :class="['px-3 py-1 text-sm font-semibold rounded-full', statusClass(task.status)]">
                {{ task.status }}
              </span>
            </div>
            <p class="text-sm text-gray-500">Criado em {{ formatDate(task.data_criacao) }}</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <button
            @click="showCommentModal = true"
            class="flex items-center gap-2 px-4 py-2 text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition"
          >
            <MessageSquare :size="18" />
            <span>Adicionar Comentário</span>
          </button>
          <button
            @click="showStatusModal = true"
            class="flex items-center gap-2 px-4 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition"
          >
            <RefreshCw :size="18" />
            <span>Mudar Status</span>
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 class="text-xl font-semibold text-gray-900 mb-4">{{ task.titulo }}</h2>
            
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-gray-500">Descrição</label>
                <p class="mt-1 text-gray-900 whitespace-pre-wrap">{{ task.descricao }}</p>
              </div>

              <div class="grid grid-cols-2 gap-4 pt-4 border-t border-gray-100">
                <div>
                  <label class="text-sm font-medium text-gray-500">Prioridade</label>
                  <div class="mt-1">
                    <span :class="['inline-flex items-center px-3 py-1 text-sm font-bold rounded-full', priorityClass(task.urgencia)]">
                      {{ task.urgencia }}
                    </span>
                  </div>
                </div>

                </div>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-lg font-semibold text-gray-900">Histórico e Comentários</h3>
              <span class="text-sm text-gray-500">{{ comentarios.length }} {{ comentarios.length === 1 ? 'item' : 'itens' }}</span>
            </div>

            <div v-if="comentarios.length > 0" class="space-y-6">
              <div
                v-for="(comentario, index) in comentarios"
                :key="comentario.id"
                class="relative"
              >
                <div
                  v-if="index < comentarios.length - 1"
                  class="absolute left-5 top-12 bottom-0 w-0.5 bg-gray-200"
                ></div>

                <div class="flex gap-4">
                  <div class="flex-shrink-0">
                    <div class="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                      <User :size="20" class="text-blue-600" />
                    </div>
                  </div>

                  <div class="flex-1 bg-gray-50 rounded-lg p-4">
                    <div class="flex items-start justify-between mb-2">
                      <div>
                        <p class="font-semibold text-gray-900">{{ comentario.autor }}</p>
                        <p class="text-xs text-gray-500">{{ formatDate(comentario.data_criacao) }}</p>
                      </div>
                      <span
                        v-if="comentario.tipo === 'status_change'"
                        class="text-xs px-2 py-1 bg-purple-100 text-purple-700 rounded-full font-medium"
                      >
                        Mudança de Status
                      </span>
                    </div>
                    <p class="text-gray-700 whitespace-pre-wrap">{{ comentario.texto }}</p>

                    <div v-if="comentario.fotos && comentario.fotos.length > 0" class="mt-3 grid grid-cols-3 gap-2">
                      <img
                        v-for="(foto, fotoIndex) in comentario.fotos"
                        :key="foto.id || fotoIndex"
                        :src="foto.url" 
                        :alt="`Foto ${fotoIndex + 1}`"
                        class="w-full h-24 object-cover rounded-lg cursor-pointer hover:opacity-80 transition border border-gray-200"
                        @click="openImagePreview(foto.url)"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div v-else class="text-center py-12">
              <MessageSquare :size="40" class="mx-auto text-gray-300 mb-3" />
              <p class="text-gray-500 mb-4">Nenhum comentário ainda</p>
              <button
                @click="showCommentModal = true"
                class="text-blue-600 hover:text-blue-700 font-medium text-sm"
              >
                Adicionar o primeiro comentário
              </button>
            </div>
          </div>
        </div>

        <div class="space-y-6">
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Ativo Relacionado</h3>
            <div class="space-y-3">
              <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <Package :size="20" class="text-gray-600" />
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-500">Código/Nome</p>
                  <p class="text-sm font-semibold text-gray-900 truncate">{{ task.ativo }}</p>
                </div>
              </div>

              <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
                <MapPin :size="20" class="text-gray-600" />
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-500">Localização</p>
                  <p class="text-sm font-semibold text-gray-900 truncate">{{ task.ambiente }}</p>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Equipe</h3>
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-gray-500">Solicitante</label>
                <p class="mt-1 text-gray-900 font-medium">
                  {{ task.solicitante_nome || 'Não informado' }}
                </p>
              </div>
              <div class="pt-4 border-t border-gray-100">
                <label class="text-sm font-medium text-gray-500">Responsáveis</label>
                <p class="mt-1 text-gray-900 font-medium">
                  <span v-if="task.responsaveis_nomes && task.responsaveis_nomes.length > 0">
                    {{ task.responsaveis_nomes.join(', ') }}
                  </span>
                  <span v-else class="text-gray-400 italic">Não atribuído</span>
                </p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Datas</h3>
            <div class="space-y-3">
              <div>
                <label class="text-sm font-medium text-gray-500">Criação</label>
                <p class="mt-1 text-gray-900">{{ formatDate(task.data_criacao) }}</p>
              </div>
              <div v-if="task.data_sugerida">
                <label class="text-sm font-medium text-gray-500">Previsão</label>
                <p class="mt-1 text-gray-900">{{ formatDate(task.data_sugerida) }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <AddCommentModal
      v-if="task"
      :is-open="showCommentModal"
      :chamado-id="Number(task.id)"
      @close="showCommentModal = false"
      @comment-added="handleCommentAdded"
    />

    <AdvanceStatusModal
      v-if="task"
      :is-open="showStatusModal"
      :chamado-id="Number(task.id)"
      :current-status="task.status"
      @close="showStatusModal = false"
      @status-changed="handleStatusChanged"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { tasksApi } from '../api'
import { useUiStore } from '../stores/ui'
import { format } from 'date-fns'
import {
  ArrowLeft,
  AlertCircle,
  MessageSquare,
  RefreshCw,
  Package,
  MapPin,
  User
} from 'lucide-vue-next'
import AddCommentModal from '../components/modals/AddCommentModal.vue'
import AdvanceStatusModal from '../components/modals/AdvanceStatusModal.vue'

// Definição da interface das Fotos
interface Foto {
  id: number
  imagem: string
  url: string
  data_upload: string
}

// Interface atualizada conforme Backend Serializer
interface TaskDetail {
  id: number | string
  titulo: string
  descricao: string
  status: string
  urgencia: string
  ativo: string
  ambiente: string
  // Campos de nomes vindos do backend
  solicitante_nome?: string
  responsaveis_nomes?: string[]
  // Campos originais (IDs ou objetos)
  solicitante?: any
  responsavel?: any
  data_criacao: string
  data_sugerida?: string
}

interface Comentario {
  id: number
  texto: string
  autor: string
  data_criacao: string
  tipo?: string
  // Fotos é um array de objetos
  fotos?: Foto[]
}

const route = useRoute()
const router = useRouter()
const uiStore = useUiStore()

const task = ref<TaskDetail | null>(null)
const comentarios = ref<Comentario[]>([])
const loading = ref(true)
const error = ref('')

const showCommentModal = ref(false)
const showStatusModal = ref(false)

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
  if (!date) return 'N/A'
  try {
    return format(new Date(date), 'dd/MM/yyyy HH:mm')
  } catch {
    return date
  }
}

const loadTask = async () => {
  loading.value = true
  error.value = ''

  try {
    const taskId = route.params.id
    const data = await tasksApi.getById(Number(taskId))
    task.value = data as TaskDetail
    
    // Processar comentários
    let comentariosProcessados: Comentario[] = []

    if (data.comentarios && Array.isArray(data.comentarios)) {
      const comms = data.comentarios.map((c: any) => ({
        id: c.id,
        texto: c.texto,
        // Backend envia usuario_nome no serializer
        autor: c.usuario_nome || c.autor?.username || 'Anônimo',
        data_criacao: c.data_criacao || c.timestamp,
        tipo: 'comentario',
        // Backend envia lista de objetos foto {id, url, ...}
        fotos: c.fotos || []
      }))
      comentariosProcessados = [...comentariosProcessados, ...comms]
    }
    
    // Processar Histórico
    if (data.historico && Array.isArray(data.historico)) {
      const historicoFormatado = data.historico.map((h: any) => ({
        id: h.id + 10000, // Offset ID para evitar colisão com comentários na key
        texto: h.descricao,
        autor: h.usuario_nome || 'Sistema',
        data_criacao: h.data_criacao || h.timestamp,
        tipo: 'status_change',
        // No histórico, as fotos também vêm como objetos no serializer ChamadoStatusHistorySerializer -> fotos
        fotos: h.fotos || [] 
      }))
      comentariosProcessados = [...comentariosProcessados, ...historicoFormatado]
    }

    // Ordenar timeline por data (mais recente primeiro)
    comentarios.value = comentariosProcessados.sort((a, b) => {
      return new Date(b.data_criacao).getTime() - new Date(a.data_criacao).getTime()
    })

  } catch (err: any) {
    console.error('Erro ao carregar chamado:', err)
    error.value = err.response?.data?.detail || err.response?.data?.message || 'Chamado não encontrado'
  } finally {
    loading.value = false
  }
}

const handleCommentAdded = (comentario: any) => {
  // Recarrega tudo para garantir sincronia com backend (e URLs de imagens corretas)
  loadTask()
  uiStore.showToast('success', 'Comentário adicionado com sucesso!')
}

const handleStatusChanged = (statusChange: any) => {
  // Recarrega para atualizar status e histórico
  loadTask()
  uiStore.showToast('success', 'Status alterado com sucesso!')
}

const openImagePreview = (imageUrl: string) => {
  if (imageUrl) {
    window.open(imageUrl, '_blank')
  }
}

onMounted(() => {
  loadTask()
})
</script>