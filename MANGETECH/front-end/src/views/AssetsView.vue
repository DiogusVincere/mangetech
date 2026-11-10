<template>
  <div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Ativos</h1>
        <p class="text-sm text-gray-500 mt-1">Equipamentos cadastrados, onde estão e como estão</p>
      </div>
      <router-link
        v-if="authStore.isAdmin"
        to="/assets/create"
        class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
      >
        <Plus :size="20" /> Cadastrar ativo
      </router-link>
    </div>

    <!-- Resumo -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <button
        v-for="card in resumo"
        :key="card.label"
        @click="card.action()"
        class="bg-white rounded-xl border border-gray-200 p-4 text-left hover:border-blue-300 transition"
      >
        <p class="text-sm text-gray-500">{{ card.label }}</p>
        <p :class="['text-2xl font-bold mt-1', card.color]">{{ card.value }}</p>
      </button>
    </div>

    <form @submit.prevent="loadAssets" class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
        <div class="relative md:col-span-2">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" :size="18" />
          <input
            v-model="filters.search"
            type="search"
            placeholder="Código, nome, modelo, fabricante, nº de série ou local"
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <select v-model="filters.status" @change="loadAssets" class="px-3 py-2 border border-gray-300 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-blue-500">
          <option value="">Todos os status</option>
          <option v-for="s in ASSET_STATUS_OPTIONS" :key="s" :value="s">{{ s }}</option>
        </select>
        <div class="flex gap-2">
          <label class="flex-1 flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-lg text-sm text-gray-700 cursor-pointer">
            <input type="checkbox" v-model="filters.com_chamados_abertos" @change="loadAssets" class="h-4 w-4 rounded border-gray-300 text-blue-600" />
            Com chamado aberto
          </label>
          <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700" title="Buscar">
            <Filter :size="18" />
          </button>
        </div>
      </div>
    </form>

    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="loadError" class="bg-white rounded-xl border border-red-200 p-8 text-center">
      <p class="text-gray-800 mb-4">{{ loadError }}</p>
      <button @click="loadAssets" class="px-4 py-2 bg-blue-600 text-white rounded-lg">Tentar de novo</button>
    </div>

    <div v-else-if="assets.length" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      <div
        v-for="asset in assets"
        :key="asset.id"
        class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md hover:border-blue-300 transition flex flex-col"
      >
        <div class="flex items-start justify-between mb-4">
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <Package :size="24" class="text-blue-600" />
          </div>
          <span :class="['px-3 py-1 text-xs rounded-full font-medium', assetStatusClass(asset.status)]">{{ asset.status }}</span>
        </div>

        <router-link :to="`/assets/${asset.id}`" class="hover:text-blue-600 transition">
          <h3 class="font-semibold text-gray-900">{{ asset.nome }}</h3>
          <p class="text-sm text-gray-500 mb-3 font-mono">{{ asset.codigo }}</p>
        </router-link>

        <div class="space-y-2 text-sm text-gray-600 flex-1">
          <div class="flex items-center gap-2"><Building2 :size="16" /> {{ [asset.fabricante, asset.modelo].filter(Boolean).join(' · ') || '—' }}</div>
          <div class="flex items-center gap-2"><MapPin :size="16" /> {{ asset.ambiente }}</div>
          <div class="flex items-center gap-2">
            <ClipboardList :size="16" />
            {{ asset.total_chamados || 0 }} chamado(s)
            <span v-if="asset.chamados_abertos" class="px-2 py-0.5 text-xs rounded-full bg-orange-100 text-orange-800 font-medium">
              {{ asset.chamados_abertos }} em aberto
            </span>
          </div>
        </div>

        <div class="mt-4 pt-4 border-t border-gray-200 flex items-center gap-2">
          <router-link
            :to="`/assets/${asset.id}`"
            class="flex-1 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 text-center text-sm font-medium"
          >
            Ver detalhes
          </router-link>
          <router-link
            :to="{ path: '/tasks/create', query: { ativo: asset.id } }"
            class="p-2 hover:bg-gray-100 rounded-lg"
            title="Abrir chamado para este ativo"
          >
            <Wrench :size="18" />
          </router-link>
          <button @click="openQR(asset.id)" class="p-2 hover:bg-gray-100 rounded-lg" title="QR code">
            <QrCode :size="18" />
          </button>
        </div>
      </div>
    </div>

    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm text-center py-16 px-4">
      <Package :size="56" class="mx-auto text-gray-300 mb-4" />
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum ativo encontrado</h3>
      <p class="text-gray-500 mb-6">{{ hasFilters ? 'Tente outros filtros.' : 'Cadastre o primeiro equipamento.' }}</p>
      <router-link v-if="authStore.isAdmin && !hasFilters" to="/assets/create" class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
        Cadastrar ativo
      </router-link>
    </div>

    <QRCodeModal :is-open="showQRModal" :ativo-id="selectedAssetId || 0" @close="showQRModal = false" />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Building2, ClipboardList, Filter, MapPin, Package, Plus, QrCode, Search, Wrench } from 'lucide-vue-next'
import { assetsApi, extractError } from '@/api'
import { useAuthStore } from '@/stores/auth'
import type { Asset } from '@/types'
import { ASSET_STATUS_OPTIONS, assetStatusClass } from '@/utils/display'
import QRCodeModal from '@/components/modals/QRCodeModal.vue'

const authStore = useAuthStore()

const assets = ref<Asset[]>([])
const todos = ref<Asset[]>([]) // para o resumo, sem filtros
const loading = ref(false)
const loadError = ref('')
const showQRModal = ref(false)
const selectedAssetId = ref<number | null>(null)

const filters = ref({ search: '', status: '', com_chamados_abertos: false })
const hasFilters = computed(() => !!(filters.value.search || filters.value.status || filters.value.com_chamados_abertos))

const resumo = computed(() => [
  { label: 'Total', value: todos.value.length, color: 'text-gray-900', action: () => setFilter('', false) },
  { label: 'Em operação', value: todos.value.filter((a) => a.status === 'Ativo').length, color: 'text-green-700', action: () => setFilter('Ativo', false) },
  { label: 'Em manutenção', value: todos.value.filter((a) => a.status === 'Manutenção').length, color: 'text-yellow-700', action: () => setFilter('Manutenção', false) },
  { label: 'Com chamado aberto', value: todos.value.filter((a) => (a.chamados_abertos || 0) > 0).length, color: 'text-orange-700', action: () => setFilter('', true) },
])

const setFilter = (status: string, abertos: boolean) => {
  filters.value = { search: '', status, com_chamados_abertos: abertos }
  loadAssets()
}

const loadAssets = async () => {
  loading.value = true
  loadError.value = ''
  try {
    assets.value = await assetsApi.getAll({
      search: filters.value.search.trim(),
      status: filters.value.status,
      com_chamados_abertos: filters.value.com_chamados_abertos ? 'true' : '',
    })
    if (!hasFilters.value) todos.value = assets.value
  } catch (err) {
    loadError.value = extractError(err, 'Não foi possível carregar os ativos.')
  } finally {
    loading.value = false
  }
}

const openQR = (id: number) => {
  selectedAssetId.value = id
  showQRModal.value = true
}

onMounted(loadAssets)
</script>
