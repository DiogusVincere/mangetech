<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Ativos</h1>
        <p class="text-gray-600 mt-1">Gerencie equipamentos e ativos</p>
      </div>
      <button 
        @click="navigateToCreateAsset"
        class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
      >
        <Plus :size="20" />
        Cadastrar Ativo
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-4">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="relative">
          <Search class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" :size="18" />
          <input
            v-model="filters.search"
            type="text"
            placeholder="Buscar ativos..."
            @keyup.enter="applyFilters"
            class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <select
          v-model="filters.status"
          @change="applyFilters"
          class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">Todos os Status</option>
          <option value="Ativo">Ativo</option>
          <option value="Inativo">Inativo</option>
          <option value="Manutenção">Manutenção</option>
        </select>
        <button
          @click="applyFilters"
          class="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center justify-center gap-2"
        >
          <Filter :size="18" />
          Filtrar
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
    </div>

    <!-- Assets Grid -->
    <div v-else-if="assetsStore.assets.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="asset in assetsStore.assets"
        :key="asset.id"
        class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition"
      >
        <!-- Asset Icon/Image -->
        <div class="flex items-start justify-between mb-4">
          <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
            <Package :size="24" class="text-blue-600" />
          </div>
          <span :class="[
            'px-3 py-1 text-xs rounded-full font-medium',
            asset.status === 'Ativo' ? 'bg-green-100 text-green-800' : 
            asset.status === 'Inativo' ? 'bg-red-100 text-red-800' : 
            'bg-yellow-100 text-yellow-800'
          ]">
            {{ asset.status }}
          </span>
        </div>

        <!-- Asset Info -->
        <div 
          @click="navigateToAsset(asset.id)"
          class="flex-1 cursor-pointer hover:text-blue-600 transition"
        >
          <h3 class="font-semibold text-gray-900 mb-1">{{ asset.nome }}</h3>
          <p class="text-sm text-gray-500 mb-3">{{ asset.codigo }}</p>
        </div>

        <!-- Asset Details -->
        <div class="space-y-2 text-sm text-gray-600">
          <div class="flex items-center gap-2">
            <Building2 :size="16" />
            <span>{{ asset.modelo }}</span>
          </div>
          <div class="flex items-center gap-2">
            <MapPin :size="16" />
            <span>{{ asset.ambiente }}</span>
          </div>
          <div v-if="asset.total_chamados !== undefined" class="flex items-center gap-2">
            <ClipboardList :size="16" />
            <span>{{ asset.total_chamados }} chamados</span>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="mt-4 pt-4 border-t border-gray-200 flex items-center gap-2">
          <button
            @click="viewAssetDetails(asset.id)"
            class="flex-1 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 text-center text-sm font-medium transition"
          >
            <Eye :size="16" class="inline mr-1" />
            Ver Detalhes
          </button>
          <button
            @click="openQRCodeModal(asset.id)"
            class="p-2 hover:bg-gray-100 rounded-lg transition"
            title="Ver QR Code"
          >
            <QrCode :size="18" />
          </button>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div class="text-center py-16 px-4">
        <Package :size="64" class="mx-auto text-gray-300 mb-4" />
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Nenhum ativo encontrado</h3>
        <p class="text-gray-500 mb-6">Comece cadastrando seu primeiro ativo</p>
        <button 
          @click="navigateToCreateAsset"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          Cadastrar Primeiro Ativo
        </button>
      </div>
    </div>

    <!-- 🆕 QR Code Modal -->
    <QRCodeModal
      :is-open="showQRModal"
      :ativo-id="selectedAssetId || 0"
      @close="closeQRModal"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAssetsStore } from '@/stores/assets'
import { useUiStore } from '@/stores/ui'
import { 
  Plus, 
  Search, 
  Filter, 
  Package, 
  Building2, 
  MapPin, 
  ClipboardList, 
  Eye, 
  QrCode 
} from 'lucide-vue-next'
import QRCodeModal from '@/components/modals/QRCodeModal.vue'

const router = useRouter()
const assetsStore = useAssetsStore()
const uiStore = useUiStore()

const loading = ref(false)
const filters = ref({
  search: '',
  status: ''
})

// 🆕 Estados do QR Code Modal
const showQRModal = ref(false)
const selectedAssetId = ref<number | null>(null)

// Navegação para ativo específico
const navigateToAsset = (assetId: number | string) => {
  if (!assetId || assetId === null || assetId === undefined) {
    console.error('ID do ativo inválido:', assetId)
    uiStore.showToast('error', 'ID do ativo inválido')
    return
  }

  const numericId = typeof assetId === 'string' ? parseInt(assetId, 10) : assetId

  if (isNaN(numericId)) {
    console.error('ID do ativo não é um número válido:', assetId)
    uiStore.showToast('error', 'ID do ativo não é válido')
    return
  }

  router.push(`/assets/${numericId}`)
}

// Navegação para criar ativo
const navigateToCreateAsset = () => {
  router.push('/assets/create')
}

// Ver detalhes do ativo
const viewAssetDetails = (assetId: number | string) => {
  navigateToAsset(assetId)
}

// 🆕 Abrir modal de QR Code
const openQRCodeModal = (assetId: number | string) => {
  const numericId = typeof assetId === 'string' ? parseInt(assetId, 10) : assetId
  
  if (isNaN(numericId)) {
    uiStore.showToast('error', 'ID do ativo inválido')
    return
  }

  selectedAssetId.value = numericId
  showQRModal.value = true
}

// 🆕 Fechar modal de QR Code
const closeQRModal = () => {
  showQRModal.value = false
  // Aguarda animação antes de limpar
  setTimeout(() => {
    selectedAssetId.value = null
  }, 300)
}

const applyFilters = async () => {
  loading.value = true
  try {
    const filterParams: any = {}
    
    if (filters.value.search) {
      filterParams.search = filters.value.search
    }
    
    if (filters.value.status) {
      filterParams.status = filters.value.status
    }
    
    await assetsStore.fetchAssets(filterParams)
  } catch (error) {
    console.error('Erro ao aplicar filtros:', error)
    uiStore.showToast('error', 'Erro ao carregar ativos')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await applyFilters()
})
</script>