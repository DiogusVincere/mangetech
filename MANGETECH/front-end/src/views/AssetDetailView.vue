<template>
  <div class="max-w-6xl mx-auto">
    <div v-if="loading" class="flex justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="!asset" class="bg-white rounded-xl border border-gray-200 text-center py-16">
      <AlertCircle :size="40" class="mx-auto text-gray-400 mb-3" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Ativo não encontrado</h3>
      <p class="text-gray-500 mb-6">{{ loadError }}</p>
      <router-link to="/assets" class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Voltar para ativos</router-link>
    </div>

    <div v-else class="space-y-6">
      <div class="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
        <div class="flex items-center gap-3">
          <router-link to="/assets" class="p-2 hover:bg-gray-100 rounded-lg" title="Voltar"><ArrowLeft :size="20" class="text-gray-600" /></router-link>
          <div>
            <div class="flex flex-wrap items-center gap-3 mb-1">
              <h1 class="text-2xl font-bold text-gray-900">{{ asset.nome }}</h1>
              <span :class="['px-3 py-1 text-xs font-semibold rounded-full', assetStatusClass(asset.status)]">{{ asset.status }}</span>
            </div>
            <p class="text-sm text-gray-500">Código <span class="font-mono">{{ asset.codigo }}</span> · {{ asset.ambiente }}</p>
          </div>
        </div>

        <div v-if="!editMode" class="flex flex-wrap gap-2">
          <router-link
            :to="{ path: '/tasks/create', query: { ativo: asset.id } }"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Wrench :size="18" /> Abrir chamado
          </router-link>
          <button @click="showQR = true" class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <QrCode :size="18" /> QR code
          </button>
          <button @click="editMode = true" class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2">
            <Pencil :size="18" /> Editar
          </button>
          <button
            v-if="authStore.isAdmin"
            @click="removeAsset"
            class="px-3 py-2 border border-red-200 text-red-600 rounded-lg hover:bg-red-50"
            title="Excluir ativo"
          >
            <Trash2 :size="18" />
          </button>
        </div>
      </div>

      <AssetForm
        v-if="editMode"
        :initial="asset"
        :saving="saving"
        :server-error="serverError"
        :server-field-errors="fieldErrors"
        submit-label="Salvar alterações"
        @submit="save"
        @cancel="cancelEdit"
      />

      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div class="lg:col-span-2 space-y-6">
          <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Dados do equipamento</h2>
            <dl class="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-4 text-sm">
              <div v-for="campo in campos" :key="campo.label">
                <dt class="text-gray-500">{{ campo.label }}</dt>
                <dd class="font-medium text-gray-900 break-words">{{ campo.value || '—' }}</dd>
              </div>
            </dl>
            <div v-if="asset.observacoes" class="mt-4 pt-4 border-t border-gray-100">
              <p class="text-sm text-gray-500 mb-1">Observações</p>
              <p class="text-sm text-gray-900 whitespace-pre-wrap">{{ asset.observacoes }}</p>
            </div>
          </section>

          <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-semibold text-gray-900">Chamados deste ativo</h2>
              <router-link :to="{ path: '/tasks', query: { search: asset.codigo } }" class="text-sm text-blue-600 hover:underline">
                Ver na lista
              </router-link>
            </div>
            <div v-if="loadingTasks" class="py-6 text-center text-gray-500">Carregando…</div>
            <ul v-else-if="tasks.length" class="divide-y divide-gray-100">
              <li v-for="t in tasks" :key="t.id">
                <router-link :to="`/tasks/${t.id}`" class="flex items-center justify-between gap-3 py-3 hover:bg-gray-50 -mx-2 px-2 rounded-lg">
                  <div class="min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">#{{ t.id }} · {{ t.titulo }}</p>
                    <p class="text-xs text-gray-500">
                      {{ formatDateTime(t.data_criacao) }} · {{ t.urgencia }}
                      <template v-if="t.responsaveis_nomes?.length"> · {{ t.responsaveis_nomes.join(', ') }}</template>
                    </p>
                  </div>
                  <span :class="['px-2 py-1 text-xs font-semibold rounded-full whitespace-nowrap', statusClass(t.status)]">{{ statusLabel(t.status) }}</span>
                </router-link>
              </li>
            </ul>
            <p v-else class="text-sm text-gray-500 py-4">Nenhum chamado aberto para este ativo{{ authStore.isAdmin ? '' : ' (que você possa ver)' }}.</p>
          </section>

          <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">Histórico do ativo</h2>

            <form @submit.prevent="addHistory" class="grid grid-cols-1 sm:grid-cols-4 gap-2 mb-5">
              <select v-model="novoHistorico.tipo" class="px-3 py-2 border border-gray-300 rounded-lg bg-white text-sm">
                <option v-for="t in tiposHistorico" :key="t" :value="t">{{ t }}</option>
              </select>
              <input
                v-model="novoHistorico.descricao"
                class="sm:col-span-2 px-3 py-2 border border-gray-300 rounded-lg text-sm"
                placeholder="O que foi feito? Ex.: troca preventiva do filtro"
              />
              <button
                type="submit"
                :disabled="addingHistory || !novoHistorico.descricao.trim()"
                class="px-3 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50"
              >
                Registrar
              </button>
            </form>

            <ol v-if="asset.historico_movimentacoes?.length" class="relative border-l border-gray-200 ml-2 space-y-4">
              <li v-for="h in asset.historico_movimentacoes" :key="h.id" class="ml-4">
                <span class="absolute -left-1.5 mt-1.5 w-3 h-3 rounded-full bg-blue-500 border-2 border-white"></span>
                <p class="text-sm"><span class="font-semibold text-gray-900">{{ h.tipo }}</span> · <span class="text-gray-500">{{ formatDateTime(h.data_criacao) }}</span></p>
                <p class="text-sm text-gray-700">{{ h.descricao }}</p>
                <p class="text-xs text-gray-400">{{ h.usuario_nome }}</p>
              </li>
            </ol>
            <p v-else class="text-sm text-gray-500">Sem registros ainda.</p>
          </section>
        </div>

        <aside class="space-y-6">
          <div class="bg-gradient-to-br from-blue-600 to-blue-700 rounded-xl shadow-sm p-6 text-white">
            <h3 class="text-sm font-semibold mb-4 opacity-90">Chamados</h3>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <p class="text-3xl font-bold">{{ asset.total_chamados || 0 }}</p>
                <p class="text-sm opacity-90">no total</p>
              </div>
              <div>
                <p class="text-3xl font-bold">{{ asset.chamados_abertos || 0 }}</p>
                <p class="text-sm opacity-90">em aberto</p>
              </div>
            </div>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-sm font-semibold text-gray-900 mb-4">Garantia</h3>
            <template v-if="asset.garantia_ate">
              <p :class="['text-lg font-bold', asset.em_garantia ? 'text-green-700' : 'text-gray-500']">
                {{ asset.em_garantia ? 'Em garantia' : 'Garantia vencida' }}
              </p>
              <p class="text-sm text-gray-600">até {{ formatDate(asset.garantia_ate) }}</p>
            </template>
            <p v-else class="text-sm text-gray-500">Informe a data de aquisição e os meses de garantia para acompanhar.</p>
          </div>

          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 text-sm space-y-3">
            <div>
              <p class="text-gray-500">Cadastrado em</p>
              <p class="font-medium text-gray-900">{{ formatDateTime(asset.data_cadastro) }}</p>
            </div>
            <div>
              <p class="text-gray-500">Atualizado em</p>
              <p class="font-medium text-gray-900">{{ formatDateTime(asset.data_atualizacao) }}</p>
            </div>
          </div>
        </aside>
      </div>
    </div>

    <QRCodeModal :is-open="showQR" :ativo-id="asset?.id || 0" @close="showQR = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { AlertCircle, ArrowLeft, Pencil, QrCode, Trash2, Wrench } from 'lucide-vue-next'
import { assetsApi, extractError, extractFieldErrors } from '@/api'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import type { Asset, AssetTask } from '@/types'
import { assetStatusClass, formatDate, formatDateTime, formatMoney, statusClass, statusLabel } from '@/utils/display'
import AssetForm from '@/components/AssetForm.vue'
import QRCodeModal from '@/components/modals/QRCodeModal.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()
const id = String(route.params.id)

const asset = ref<Asset | null>(null)
const tasks = ref<AssetTask[]>([])
const loading = ref(true)
const loadingTasks = ref(true)
const loadError = ref('')
const editMode = ref(false)
const saving = ref(false)
const serverError = ref('')
const fieldErrors = ref<Record<string, string>>({})
const showQR = ref(route.query.qr === '1') // logo após cadastrar, já mostra o QR
const addingHistory = ref(false)

const tiposHistorico = ['Manutenção preventiva', 'Manutenção corretiva', 'Inspeção', 'Calibração', 'Movimentação', 'Observação']
const novoHistorico = ref({ tipo: tiposHistorico[0] as string, descricao: '' })

const campos = computed(() => {
  const a = asset.value
  if (!a) return []
  return [
    { label: 'Modelo', value: a.modelo },
    { label: 'Fabricante', value: a.fabricante },
    { label: 'Número de série', value: a.numero_serie },
    { label: 'Fornecedor', value: a.fornecedor },
    { label: 'Localização', value: a.ambiente },
    { label: 'Data de aquisição', value: a.data_aquisicao ? formatDate(a.data_aquisicao) : '' },
    { label: 'Valor', value: a.valor ? formatMoney(a.valor) : '' },
    { label: 'Garantia', value: a.garantia_meses ? `${a.garantia_meses} meses` : '' },
  ]
})

const loadAsset = async () => {
  try {
    asset.value = await assetsApi.getById(id)
  } catch (err: any) {
    asset.value = null
    loadError.value = err?.response?.status === 404 ? 'O ativo não existe ou foi excluído.' : extractError(err)
  } finally {
    loading.value = false
  }
}

const loadTasks = async () => {
  loadingTasks.value = true
  try {
    tasks.value = await assetsApi.getTasks(id)
  } catch {
    tasks.value = []
  } finally {
    loadingTasks.value = false
  }
}

const save = async (payload: Record<string, any>) => {
  saving.value = true
  serverError.value = ''
  fieldErrors.value = {}
  try {
    asset.value = await assetsApi.update(id, payload)
    editMode.value = false
    uiStore.showToast('success', 'Ativo atualizado.')
  } catch (err: any) {
    serverError.value = extractError(err, 'Não foi possível salvar.')
    fieldErrors.value = extractFieldErrors(err)
  } finally {
    saving.value = false
  }
}

const cancelEdit = () => {
  editMode.value = false
  serverError.value = ''
  fieldErrors.value = {}
}

const addHistory = async () => {
  if (!asset.value) return
  addingHistory.value = true
  try {
    const item = await assetsApi.addHistory(id, novoHistorico.value.tipo, novoHistorico.value.descricao.trim())
    asset.value.historico_movimentacoes = [item, ...(asset.value.historico_movimentacoes || [])]
    novoHistorico.value.descricao = ''
    uiStore.showToast('success', 'Registro adicionado ao histórico.')
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  } finally {
    addingHistory.value = false
  }
}

const removeAsset = async () => {
  if (!asset.value) return
  if (!confirm(`Excluir o ativo ${asset.value.codigo}? Os chamados antigos continuam, mas perdem o vínculo.`)) return
  try {
    await assetsApi.remove(id)
    uiStore.showToast('success', 'Ativo excluído.')
    router.push('/assets')
  } catch (err) {
    uiStore.showToast('error', extractError(err))
  }
}

onMounted(() => {
  loadAsset()
  loadTasks()
})
</script>
