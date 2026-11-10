<template>
  <div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Chamados</h1>
        <p class="text-sm text-gray-500 mt-1">
          <template v-if="!loading">{{ total }} chamado{{ total === 1 ? '' : 's' }} encontrado{{ total === 1 ? '' : 's' }}</template>
          <template v-else>Carregando…</template>
          <span v-if="!authStore.isAdmin"> · você vê os chamados que abriu ou em que é responsável</span>
        </p>
      </div>

      <div class="flex items-center gap-2">
        <button
          @click="exportCSV"
          :disabled="exporting || total === 0"
          class="inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-gray-700 rounded-lg hover:bg-gray-50 disabled:opacity-50 transition"
        >
          <Download :size="18" class="mr-2" />
          {{ exporting ? 'Exportando…' : 'Exportar CSV' }}
        </button>
        <router-link
          to="/tasks/create"
          class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-sm"
        >
          <Plus :size="20" class="mr-2" />
          Novo chamado
        </router-link>
      </div>
    </div>

    <!-- Filtros -->
    <form @submit.prevent="applyFilters" class="bg-white rounded-xl shadow-sm border border-gray-200 p-4 space-y-3">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <div class="relative md:col-span-2">
          <Search :size="18" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
          <input
            v-model="filters.search"
            type="search"
            placeholder="Buscar por título, descrição, ativo, ambiente ou nº"
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <select v-model="filters.status" @change="applyFilters" class="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white">
          <option value="">Todos os status</option>
          <option value="ABERTO,AGUARDANDO RESP,EM ANDAMENTO">Em aberto (todos)</option>
          <option v-for="s in STATUS_OPTIONS" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
        <select v-model="filters.urgencia" @change="applyFilters" class="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white">
          <option value="">Todas as urgências</option>
          <option v-for="u in URGENCIA_OPTIONS" :key="u" :value="u">{{ u }}</option>
        </select>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <button
          v-for="chip in chips"
          :key="chip.key"
          type="button"
          @click="toggleChip(chip.key)"
          :class="[
            'px-3 py-1.5 text-sm rounded-full border transition',
            filters[chip.key] ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50',
          ]"
        >
          {{ chip.label }}
        </button>

        <select v-model="filters.ordering" @change="applyFilters" class="ml-auto px-3 py-1.5 text-sm border border-gray-300 rounded-lg bg-white">
          <option value="-data_criacao">Mais recentes</option>
          <option value="data_criacao">Mais antigos</option>
          <option value="-data_atualizacao">Atualizados recentemente</option>
          <option value="data_sugerida">Prazo mais próximo</option>
        </select>
        <button type="submit" class="px-4 py-1.5 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center">
          <Filter :size="16" class="mr-1.5" /> Filtrar
        </button>
        <button v-if="hasFilters" type="button" @click="clearFilters" class="px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900">
          Limpar
        </button>
      </div>
    </form>

    <!-- Barra de seleção (staff) -->
    <div
      v-if="authStore.isAdmin && selected.length > 0"
      class="sticky top-0 z-10 bg-blue-50 border border-blue-200 rounded-xl px-4 py-3 flex items-center justify-between"
    >
      <span class="text-sm text-blue-900 font-medium">{{ selected.length }} selecionado(s)</span>
      <div class="flex gap-2">
        <button @click="selected = []" class="px-3 py-1.5 text-sm text-gray-700 hover:bg-white rounded-lg">Desmarcar</button>
        <button @click="bulkDelete" :disabled="deleting" class="px-3 py-1.5 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 flex items-center gap-1.5">
          <Trash2 :size="16" /> Excluir
        </button>
      </div>
    </div>

    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4">Carregando chamados…</p>
    </div>

    <div v-else-if="loadError" class="bg-white rounded-xl border border-red-200 p-8 text-center">
      <AlertCircle :size="32" class="mx-auto text-red-500 mb-3" />
      <p class="text-gray-800 mb-4">{{ loadError }}</p>
      <button @click="loadTasks()" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Tentar de novo</button>
    </div>

    <div v-else-if="tasks.length > 0" class="space-y-4">
      <div
        v-for="task in tasks"
        :key="task.id"
        class="bg-white rounded-xl shadow-sm border border-gray-200 p-5 hover:shadow-md hover:border-blue-300 transition-all"
      >
        <div class="flex items-start gap-3">
          <input
            v-if="authStore.isAdmin"
            type="checkbox"
            :value="task.id"
            v-model="selected"
            class="mt-1.5 h-4 w-4 rounded border-gray-300 text-blue-600"
            :aria-label="`Selecionar chamado ${task.id}`"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2 mb-1.5">
                  <span class="text-xs font-medium text-gray-500">#{{ task.id }}</span>
                  <span :class="['px-2.5 py-0.5 text-xs font-semibold rounded-full', statusClass(task.status)]">
                    {{ statusLabel(task.status) }}
                  </span>
                  <span v-if="task.atrasado" class="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-red-600 text-white">
                    Atrasado
                  </span>
                </div>
                <router-link :to="`/tasks/${task.id}`" class="text-lg font-semibold text-gray-900 hover:text-blue-600 transition">
                  {{ task.titulo }}
                </router-link>
              </div>
              <span :class="['px-3 py-1 text-xs font-bold rounded-full whitespace-nowrap', priorityClass(task.urgencia)]">
                {{ task.urgencia }}
              </span>
            </div>

            <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-gray-600 mt-2">
              <router-link
                v-if="task.ativo_detalhes"
                :to="`/assets/${task.ativo_detalhes.id}`"
                class="flex items-center hover:text-blue-600"
              >
                <Package :size="15" class="mr-1" /> {{ task.ativo }}
              </router-link>
              <span v-else class="flex items-center"><Package :size="15" class="mr-1" /> {{ task.ativo || '—' }}</span>
              <span class="flex items-center"><MapPin :size="15" class="mr-1" /> {{ task.ambiente }}</span>
              <span class="flex items-center">
                <Users :size="15" class="mr-1" />
                {{ task.responsaveis_nomes?.length ? task.responsaveis_nomes.join(', ') : 'Sem responsável' }}
              </span>
            </div>

            <p class="text-sm text-gray-600 line-clamp-2 mt-2">{{ task.descricao }}</p>

            <div class="flex flex-wrap items-center justify-between gap-2 pt-3 mt-3 border-t border-gray-100">
              <div class="flex items-center gap-3 text-xs text-gray-500">
                <span class="flex items-center"><Calendar :size="14" class="mr-1" /> {{ formatDateTime(task.data_criacao) }}</span>
                <span v-if="task.data_sugerida" class="flex items-center" :class="task.atrasado ? 'text-red-600 font-medium' : ''">
                  <Clock :size="14" class="mr-1" /> prazo {{ formatDateTime(task.data_sugerida) }}
                </span>
                <span v-if="task.solicitante_nome">por {{ task.solicitante_nome }}</span>
              </div>
              <div class="flex items-center gap-2">
                <button
                  @click="openCommentModal(task)"
                  class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition"
                >
                  <MessageSquare :size="14" /> Comentar
                </button>
                <button
                  @click="openStatusModal(task)"
                  class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-purple-600 bg-purple-50 rounded-lg hover:bg-purple-100 transition"
                >
                  <RefreshCw :size="14" /> Status
                </button>
                <router-link
                  :to="`/tasks/${task.id}`"
                  class="flex items-center gap-1 px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                >
                  Abrir <ChevronRight :size="14" />
                </router-link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="hasMore" class="text-center pt-2">
        <button
          @click="loadMore"
          :disabled="loadingMore"
          class="px-6 py-2 border border-gray-300 bg-white rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50"
        >
          {{ loadingMore ? 'Carregando…' : `Carregar mais (${tasks.length} de ${total})` }}
        </button>
      </div>
    </div>

    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm text-center py-16 px-4">
      <div class="mx-auto w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mb-4">
        <ClipboardList :size="36" class="text-gray-400" />
      </div>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum chamado encontrado</h3>
      <p class="text-gray-500 mb-6">{{ hasFilters ? 'Tente mudar ou limpar os filtros.' : 'Abra um chamado para começar.' }}</p>
      <button v-if="hasFilters" @click="clearFilters" class="px-5 py-2.5 border border-gray-300 rounded-lg mr-2 hover:bg-gray-50">Limpar filtros</button>
      <router-link to="/tasks/create" class="inline-flex items-center px-5 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
        <Plus :size="18" class="mr-2" /> Novo chamado
      </router-link>
    </div>

    <AddCommentModal
      v-if="selectedTask"
      :is-open="showCommentModal"
      :chamado-id="Number(selectedTask.id)"
      @close="showCommentModal = false"
      @comment-added="showCommentModal = false"
    />
    <AdvanceStatusModal
      v-if="selectedTask"
      :is-open="showStatusModal"
      :chamado-id="Number(selectedTask.id)"
      :current-status="selectedTask.status"
      @close="showStatusModal = false"
      @status-changed="onTaskChanged"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  AlertCircle, Calendar, ChevronRight, ClipboardList, Clock, Download, Filter,
  MapPin, MessageSquare, Package, Plus, RefreshCw, Search, Trash2, Users,
} from 'lucide-vue-next'
import { tasksApi, extractError, downloadBlob } from '@/api'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import type { Task } from '@/types'
import {
  STATUS_OPTIONS, URGENCIA_OPTIONS, formatDateTime, priorityClass, statusClass, statusLabel,
} from '@/utils/display'
import AddCommentModal from '@/components/modals/AddCommentModal.vue'
import AdvanceStatusModal from '@/components/modals/AdvanceStatusModal.vue'

type ChipKey = 'meus_chamados' | 'atrasados' | 'sem_responsavel' | 'criticos_abertos'

const PAGE_SIZE = 20
const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const tasks = ref<Task[]>([])
const total = ref(0)
const page = ref(1)
const loading = ref(false)
const loadingMore = ref(false)
const loadError = ref('')
const exporting = ref(false)
const deleting = ref(false)
const selected = ref<string[]>([])

const showCommentModal = ref(false)
const showStatusModal = ref(false)
const selectedTask = ref<Task | null>(null)

const q = route.query
const filters = ref({
  search: (q.search as string) || '',
  status: (q.status as string) || '',
  urgencia: (q.urgencia as string) || '',
  ordering: (q.ordering as string) || '-data_criacao',
  meus_chamados: q.meus_chamados === 'true',
  atrasados: q.atrasados === 'true',
  sem_responsavel: q.sem_responsavel === 'true',
  criticos_abertos: q.criticos_abertos === 'true',
})

const chips: { key: ChipKey; label: string }[] = [
  { key: 'meus_chamados', label: 'Meus chamados' },
  { key: 'criticos_abertos', label: 'Críticos/altos em aberto' },
  { key: 'atrasados', label: 'Atrasados' },
  { key: 'sem_responsavel', label: 'Sem responsável' },
]

const hasFilters = computed(() => {
  const f = filters.value
  return !!(f.search || f.status || f.urgencia || f.meus_chamados || f.atrasados || f.sem_responsavel || f.criticos_abertos)
})
const hasMore = computed(() => tasks.value.length < total.value)

const apiFilters = () => {
  const f = filters.value
  return {
    search: f.search.trim(),
    status: f.status,
    urgencia: f.urgencia,
    ordering: f.ordering,
    meus_chamados: f.meus_chamados ? 'true' : '',
    atrasados: f.atrasados ? 'true' : '',
    sem_responsavel: f.sem_responsavel ? 'true' : '',
    criticos_abertos: f.criticos_abertos ? 'true' : '',
  }
}

const loadTasks = async () => {
  loading.value = true
  loadError.value = ''
  selected.value = []
  page.value = 1
  try {
    const data = await tasksApi.list(apiFilters(), 1, PAGE_SIZE)
    tasks.value = data.results
    total.value = data.count
  } catch (err) {
    loadError.value = extractError(err, 'Não foi possível carregar os chamados.')
    tasks.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

const loadMore = async () => {
  loadingMore.value = true
  try {
    const data = await tasksApi.list(apiFilters(), page.value + 1, PAGE_SIZE)
    page.value += 1
    const ids = new Set(tasks.value.map((t) => t.id))
    tasks.value.push(...data.results.filter((t) => !ids.has(t.id)))
    total.value = data.count
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  } finally {
    loadingMore.value = false
  }
}

const applyFilters = () => {
  // Mantém os filtros na URL: voltar do detalhe preserva a lista filtrada.
  const query: Record<string, string> = {}
  for (const [k, v] of Object.entries(apiFilters())) {
    if (v && !(k === 'ordering' && v === '-data_criacao')) query[k] = v
  }
  router.replace({ query })
  loadTasks()
}

const toggleChip = (key: ChipKey) => {
  filters.value[key] = !filters.value[key]
  applyFilters()
}

const clearFilters = () => {
  filters.value = {
    search: '', status: '', urgencia: '', ordering: '-data_criacao',
    meus_chamados: false, atrasados: false, sem_responsavel: false, criticos_abertos: false,
  }
  applyFilters()
}

const exportCSV = async () => {
  exporting.value = true
  try {
    const blob = await tasksApi.exportCSV(apiFilters())
    downloadBlob(blob, `chamados_${new Date().toISOString().slice(0, 10)}.csv`)
  } catch (err) {
    uiStore.showToast('error', extractError(err, 'Não foi possível exportar.'))
  } finally {
    exporting.value = false
  }
}

const bulkDelete = async () => {
  const n = selected.value.length
  if (!confirm(`Excluir ${n} chamado(s)? Esta ação não pode ser desfeita.`)) return
  deleting.value = true
  try {
    const r = await tasksApi.bulkDelete(selected.value)
    let msg = `${r.quantidade_excluida} chamado(s) excluído(s).`
    if (r.ids_em_andamento.length) msg += ` ${r.ids_em_andamento.length} em andamento não pode(m) ser excluído(s).`
    uiStore.showToast(r.ids_em_andamento.length ? 'warning' : 'success', msg)
    await loadTasks()
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  } finally {
    deleting.value = false
  }
}

const openCommentModal = (task: Task) => {
  selectedTask.value = task
  showCommentModal.value = true
}

const openStatusModal = (task: Task) => {
  selectedTask.value = task
  showStatusModal.value = true
}

const onTaskChanged = (payload: { chamado: Task }) => {
  const atualizado = payload.chamado
  if (atualizado) {
    const i = tasks.value.findIndex((t) => t.id === atualizado.id)
    if (i !== -1) tasks.value[i] = atualizado
  }
}

onMounted(loadTasks)
</script>
