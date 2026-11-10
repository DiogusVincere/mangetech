<template>
  <div class="space-y-6">
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4">Carregando chamado…</p>
    </div>

    <div v-else-if="error" class="bg-white rounded-xl border border-red-200 shadow-sm p-8 text-center">
      <AlertCircle :size="32" class="mx-auto text-red-500 mb-3" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Não foi possível abrir o chamado</h3>
      <p class="text-gray-600 mb-4">{{ error }}</p>
      <router-link to="/tasks" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Voltar para a lista</router-link>
    </div>

    <template v-else-if="task">
      <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div class="flex items-center gap-3 min-w-0">
          <button @click="goBack" class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg" title="Voltar">
            <ArrowLeft :size="20" />
          </button>
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2 mb-1">
              <h1 class="text-2xl font-bold text-gray-900">Chamado #{{ task.id }}</h1>
              <span :class="['px-3 py-1 text-sm font-semibold rounded-full', statusClass(task.status)]">
                {{ statusLabel(task.status) }}
              </span>
              <span v-if="task.atrasado" class="px-3 py-1 text-sm font-semibold rounded-full bg-red-600 text-white">Atrasado</span>
            </div>
            <p class="text-sm text-gray-500">
              Aberto em {{ formatDateTime(task.data_criacao) }} por {{ task.solicitante_nome || '—' }}
              · atualizado {{ timeAgo(task.data_atualizacao) }}
            </p>
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <button @click="showCommentModal = true" class="flex items-center gap-2 px-4 py-2 text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100">
            <MessageSquare :size="18" /> Comentar
          </button>
          <button @click="showStatusModal = true" class="flex items-center gap-2 px-4 py-2 text-white bg-blue-600 rounded-lg hover:bg-blue-700">
            <RefreshCw :size="18" /> Mudar status
          </button>
          <router-link :to="`/tasks/${task.id}/edit`" class="flex items-center gap-2 px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50">
            <Pencil :size="18" /> Editar
          </router-link>
          <button
            v-if="canDelete"
            @click="deleteTask"
            :disabled="deleting || task.status === 'EM ANDAMENTO'"
            :title="task.status === 'EM ANDAMENTO' ? 'Chamado em andamento não pode ser excluído' : 'Excluir chamado'"
            class="flex items-center gap-2 px-4 py-2 text-red-600 border border-red-200 rounded-lg hover:bg-red-50 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Trash2 :size="18" />
          </button>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-start justify-between gap-3 mb-4">
              <h2 class="text-xl font-semibold text-gray-900">{{ task.titulo }}</h2>
              <span :class="['inline-flex px-3 py-1 text-sm font-bold rounded-full whitespace-nowrap', priorityClass(task.urgencia)]">
                {{ task.urgencia }}
              </span>
            </div>
            <p class="text-gray-800 whitespace-pre-wrap">{{ task.descricao }}</p>
          </div>

          <!-- Anexos -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-semibold text-gray-900">Anexos</h3>
              <label class="flex items-center gap-2 px-3 py-1.5 text-sm text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 cursor-pointer">
                <Paperclip :size="16" />
                {{ uploading ? 'Enviando…' : 'Anexar arquivo' }}
                <input type="file" class="hidden" :disabled="uploading" @change="uploadAttachment" />
              </label>
            </div>
            <ul v-if="task.anexos_detalhes?.length" class="divide-y divide-gray-100">
              <li v-for="anexo in task.anexos_detalhes" :key="anexo.id" class="flex items-center justify-between py-2 gap-3">
                <a :href="anexo.url || '#'" target="_blank" rel="noopener" class="flex items-center gap-2 text-sm text-blue-700 hover:underline min-w-0">
                  <FileText :size="16" class="flex-shrink-0" />
                  <span class="truncate">{{ anexo.nome_original }}</span>
                </a>
                <div class="flex items-center gap-3 text-xs text-gray-500 flex-shrink-0">
                  {{ formatDateTime(anexo.data_upload) }}
                  <button @click="removeAttachment(anexo.id)" class="p-1 text-gray-400 hover:text-red-600" title="Remover anexo">
                    <X :size="16" />
                  </button>
                </div>
              </li>
            </ul>
            <p v-else class="text-sm text-gray-500">Nenhum arquivo anexado. Notas fiscais, laudos e manuais podem ficar aqui (até 20 MB).</p>
          </div>

          <!-- Linha do tempo -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-lg font-semibold text-gray-900">Histórico e comentários</h3>
              <span class="text-sm text-gray-500">{{ timeline.length }} {{ timeline.length === 1 ? 'item' : 'itens' }}</span>
            </div>

            <div v-if="timeline.length" class="space-y-5">
              <div v-for="item in timeline" :key="item.key" class="flex gap-4">
                <div class="flex-shrink-0">
                  <div
                    :class="[
                      'w-10 h-10 rounded-full flex items-center justify-center',
                      item.tipo === 'status' ? 'bg-purple-100 text-purple-600' : 'bg-blue-100 text-blue-600',
                    ]"
                  >
                    <RefreshCw v-if="item.tipo === 'status'" :size="18" />
                    <MessageSquare v-else :size="18" />
                  </div>
                </div>
                <div class="flex-1 bg-gray-50 rounded-lg p-4 min-w-0">
                  <div class="flex flex-wrap items-center justify-between gap-2 mb-2">
                    <div>
                      <p class="font-semibold text-gray-900">{{ item.autor }}</p>
                      <p class="text-xs text-gray-500">{{ formatDateTime(item.data) }}</p>
                    </div>
                    <span v-if="item.tipo === 'status'" :class="['text-xs px-2 py-1 rounded-full font-medium', statusClass(item.status || '')]">
                      {{ statusLabel(item.status || '') }}
                    </span>
                  </div>
                  <p class="text-gray-700 whitespace-pre-wrap break-words">{{ item.texto }}</p>
                  <div v-if="item.fotos.length" class="mt-3 grid grid-cols-3 sm:grid-cols-4 gap-2">
                    <a v-for="foto in item.fotos" :key="foto.id" :href="foto.url || '#'" target="_blank" rel="noopener">
                      <img :src="foto.url || ''" alt="Foto anexada" class="w-full h-24 object-cover rounded-lg border border-gray-200 hover:opacity-80" />
                    </a>
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-10 text-gray-500">Nenhum registro ainda.</div>
          </div>
        </div>

        <div class="space-y-6">
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Ativo</h3>
            <router-link
              v-if="task.ativo_detalhes"
              :to="`/assets/${task.ativo_detalhes.id}`"
              class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg hover:bg-blue-50 transition"
            >
              <Package :size="20" class="text-gray-600" />
              <div class="flex-1 min-w-0">
                <p class="text-sm font-semibold text-gray-900 truncate">{{ task.ativo_detalhes.codigo }} · {{ task.ativo_detalhes.nome }}</p>
                <p class="text-xs text-gray-500">Status do ativo: {{ task.ativo_detalhes.status }}</p>
              </div>
              <ChevronRight :size="16" class="text-gray-400" />
            </router-link>
            <div v-else class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg">
              <Package :size="20" class="text-gray-600" />
              <div class="min-w-0">
                <p class="text-sm font-semibold text-gray-900 truncate">{{ task.ativo || '—' }}</p>
                <p class="text-xs text-gray-500">Sem vínculo com um ativo cadastrado</p>
              </div>
            </div>
            <div class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg mt-3">
              <MapPin :size="20" class="text-gray-600" />
              <div class="min-w-0">
                <p class="text-xs text-gray-500">Localização</p>
                <p class="text-sm font-semibold text-gray-900 truncate">{{ task.ambiente }}</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Equipe</h3>
            <p class="text-sm text-gray-500">Solicitante</p>
            <p class="mt-1 text-gray-900 font-medium">{{ task.solicitante_nome || 'Não informado' }}</p>
            <p v-if="task.solicitante_email" class="text-xs text-gray-500">{{ task.solicitante_email }}</p>
            <div class="pt-4 mt-4 border-t border-gray-100">
              <p class="text-sm text-gray-500 mb-2">Responsáveis</p>
              <ul v-if="task.responsaveis_detalhes?.length" class="space-y-2">
                <li v-for="r in task.responsaveis_detalhes" :key="r.id" class="flex items-center gap-2">
                  <span class="w-7 h-7 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white text-xs font-semibold">
                    {{ initials(r) }}
                  </span>
                  <span class="text-sm text-gray-900">{{ fullName(r) }}</span>
                </li>
              </ul>
              <router-link v-else :to="`/tasks/${task.id}/edit`" class="text-sm text-blue-600 hover:underline">
                Não atribuído — definir responsáveis
              </router-link>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-lg font-semibold text-gray-900 mb-4">Datas</h3>
            <dl class="space-y-3 text-sm">
              <div>
                <dt class="text-gray-500">Abertura</dt>
                <dd class="text-gray-900">{{ formatDateTime(task.data_criacao) }}</dd>
              </div>
              <div>
                <dt class="text-gray-500">Prazo sugerido</dt>
                <dd :class="task.atrasado ? 'text-red-600 font-semibold' : 'text-gray-900'">
                  {{ formatDateTime(task.data_sugerida, 'Sem prazo') }}
                </dd>
              </div>
              <div>
                <dt class="text-gray-500">Última atualização</dt>
                <dd class="text-gray-900">{{ formatDateTime(task.data_atualizacao) }}</dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </template>

    <AddCommentModal
      v-if="task"
      :is-open="showCommentModal"
      :chamado-id="Number(task.id)"
      @close="showCommentModal = false"
      @comment-added="onCommentAdded"
    />
    <AdvanceStatusModal
      v-if="task"
      :is-open="showStatusModal"
      :chamado-id="Number(task.id)"
      :current-status="task.status"
      @close="showStatusModal = false"
      @status-changed="onStatusChanged"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  AlertCircle, ArrowLeft, ChevronRight, FileText, MapPin, MessageSquare, Package,
  Paperclip, Pencil, RefreshCw, Trash2, X,
} from 'lucide-vue-next'
import { tasksApi, extractError } from '@/api'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import type { Foto, Task } from '@/types'
import {
  formatDateTime, fullName, initials, priorityClass, statusClass, statusLabel, timeAgo,
} from '@/utils/display'
import AddCommentModal from '@/components/modals/AddCommentModal.vue'
import AdvanceStatusModal from '@/components/modals/AdvanceStatusModal.vue'

interface TimelineItem {
  key: string
  tipo: 'status' | 'comentario'
  status?: string
  autor: string
  texto: string
  data: string
  fotos: Foto[]
}

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const task = ref<Task | null>(null)
const loading = ref(true)
const error = ref('')
const deleting = ref(false)
const uploading = ref(false)
const showCommentModal = ref(false)
const showStatusModal = ref(false)

const canDelete = computed(() => {
  if (!task.value || !authStore.user) return false
  return authStore.isAdmin || task.value.solicitante === authStore.user.id
})

const timeline = computed<TimelineItem[]>(() => {
  if (!task.value) return []
  const itens: TimelineItem[] = [
    ...(task.value.comentarios || []).map((c) => ({
      key: `c${c.id}`,
      tipo: 'comentario' as const,
      autor: c.usuario_nome || 'Anônimo',
      texto: c.texto,
      data: c.data_criacao,
      fotos: c.fotos || [],
    })),
    ...(task.value.historico || []).map((h) => ({
      key: `h${h.id}`,
      tipo: 'status' as const,
      status: h.status,
      autor: h.usuario_nome || 'Sistema',
      texto: h.descricao,
      data: h.data_criacao,
      fotos: h.fotos || [],
    })),
  ]
  return itens.sort((a, b) => new Date(b.data).getTime() - new Date(a.data).getTime())
})

const loadTask = async (silencioso = false) => {
  if (!silencioso) loading.value = true
  error.value = ''
  try {
    task.value = await tasksApi.getById(String(route.params.id))
  } catch (err: any) {
    error.value = err?.response?.status === 404
      ? 'Chamado não encontrado ou você não tem acesso a ele.'
      : extractError(err)
  } finally {
    loading.value = false
  }
}

const goBack = () => {
  if (window.history.state?.back) router.back()
  else router.push('/tasks')
}

const onCommentAdded = () => {
  uiStore.showToast('success', 'Comentário adicionado.')
  loadTask(true)
}

const onStatusChanged = (payload: { chamado: Task }) => {
  task.value = payload.chamado
  uiStore.showToast('success', 'Status atualizado.')
}

const uploadAttachment = async (event: Event) => {
  const input = event.target as HTMLInputElement
  const arquivo = input.files?.[0]
  input.value = ''
  if (!arquivo || !task.value) return
  if (arquivo.size > 20 * 1024 * 1024) {
    uiStore.showToast('error', 'O arquivo passa de 20 MB.')
    return
  }
  uploading.value = true
  try {
    await tasksApi.addAttachment(task.value.id, arquivo)
    uiStore.showToast('success', 'Arquivo anexado.')
    await loadTask(true)
  } catch (err) {
    uiStore.showToast('error', extractError(err, 'Não foi possível anexar.'))
  } finally {
    uploading.value = false
  }
}

const removeAttachment = async (anexoId: number) => {
  if (!task.value || !confirm('Remover este anexo?')) return
  try {
    await tasksApi.removeAttachment(task.value.id, anexoId)
    task.value.anexos_detalhes = (task.value.anexos_detalhes || []).filter((a) => a.id !== anexoId)
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  }
}

const deleteTask = async () => {
  if (!task.value || !confirm(`Excluir o chamado #${task.value.id}? Esta ação não pode ser desfeita.`)) return
  deleting.value = true
  try {
    await tasksApi.remove(task.value.id)
    uiStore.showToast('success', 'Chamado excluído.')
    router.push('/tasks')
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  } finally {
    deleting.value = false
  }
}

onMounted(() => loadTask())
</script>
