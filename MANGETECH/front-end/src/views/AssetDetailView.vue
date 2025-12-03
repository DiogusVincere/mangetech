<!-- src/views/AssetDetailView.vue - INTEGRADO COM BACKEND E QR CODE -->
<template>
  <div class="max-w-6xl mx-auto px-4 py-6">
    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando ativo...</p>
    </div>

    <!-- Content -->
    <div v-else-if="asset" class="space-y-6">
      <!-- Header -->
      <div class="flex items-start justify-between">
        <div class="flex items-center">
          <button
            @click="goBack"
            class="p-2 hover:bg-gray-100 rounded-lg transition mr-4"
          >
            ← Voltar
          </button>
          <div>
            <div class="flex items-center gap-3 mb-2">
              <h1 class="text-2xl font-bold text-gray-900">{{ asset.nome }}</h1>
              <span :class="statusBadgeClass">
                {{ asset.status }}
              </span>
            </div>
            <p class="text-sm text-gray-500">Código: {{ asset.codigo }}</p>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-3">
          <button
            v-if="!editMode"
            @click="openQRCodeModal"
            class="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition flex items-center gap-2"
          >
            <QrCode :size="18" />
            QR Code
          </button>
          <button
            v-if="!editMode && canEdit"
            @click="enableEditMode"
            class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition flex items-center gap-2"
          >
            ✏️ Editar
          </button>
        </div>
      </div>

      <!-- Edit Mode -->
      <div v-if="editMode" class="space-y-6">
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">📦 Informações Básicas</h2>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Nome do Ativo <span class="text-red-500">*</span>
              </label>
              <input
                v-model="editData.nome"
                type="text"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Código <span class="text-red-500">*</span>
              </label>
              <input
                v-model="editData.codigo"
                type="text"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Modelo <span class="text-red-500">*</span>
              </label>
              <input
                v-model="editData.modelo"
                type="text"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Fabricante
              </label>
              <input
                v-model="editData.fabricante"
                type="text"
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Ambiente <span class="text-red-500">*</span>
              </label>
              <input
                v-model="editData.ambiente"
                type="text"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div>
              <label class="block text-sm font-semibold text-gray-700 mb-2">
                Status <span class="text-red-500">*</span>
              </label>
              <select
                v-model="editData.status"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="Ativo">Ativo</option>
                <option value="Inativo">Inativo</option>
                <option value="Manutenção">Manutenção</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start">
          <span class="text-red-600 mr-2">⚠️</span>
          <p class="text-sm text-red-800">{{ errorMessage }}</p>
        </div>

        <!-- Botões -->
        <div class="flex justify-end gap-4">
          <button
            type="button"
            @click="cancelEdit"
            class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
          >
            Cancelar
          </button>
          <button
            @click="handleUpdate"
            :disabled="updating"
            class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 transition"
          >
            {{ updating ? 'Salvando...' : 'Salvar Alterações' }}
          </button>
        </div>
      </div>

      <!-- View Mode -->
      <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Main Info -->
        <div class="lg:col-span-2 space-y-6">
          <!-- Informações Básicas -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">📦 Informações Básicas</h2>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <p class="text-sm text-gray-500 mb-1">Modelo</p>
                <p class="font-medium text-gray-900">{{ asset.modelo }}</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 mb-1">Fabricante</p>
                <p class="font-medium text-gray-900">{{ asset.fabricante || 'Não informado' }}</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 mb-1">Número de Série</p>
                <p class="font-medium text-gray-900">{{ asset.numero_serie || 'Não informado' }}</p>
              </div>
              <div>
                <p class="text-sm text-gray-500 mb-1">Ambiente</p>
                <p class="font-medium text-gray-900">📍 {{ asset.ambiente }}</p>
              </div>
            </div>
          </div>

          <!-- Chamados Relacionados -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h2 class="text-lg font-semibold text-gray-900 mb-4">📋 Chamados Relacionados</h2>
            
            <div v-if="loadingTasks" class="text-center py-8">
              <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            </div>
            
            <div v-else-if="relatedTasks.length > 0" class="space-y-3">
              <div
                v-for="task in relatedTasks"
                :key="task.id"
                @click="goToTask(task.id)"
                class="block p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition cursor-pointer"
              >
                <div class="flex items-center justify-between mb-2">
                  <span class="text-sm font-medium text-gray-900">#{{ task.id }} - {{ task.titulo }}</span>
                  <span :class="getStatusBadgeClass(task.status)">
                    {{ task.status }}
                  </span>
                </div>
                <p class="text-xs text-gray-500">{{ formatDate(task.data_criacao) }}</p>
              </div>
            </div>
            
            <div v-else class="text-center py-8 text-gray-500">
              <p class="text-4xl mb-2">📋</p>
              <p>Nenhum chamado relacionado</p>
            </div>
          </div>
        </div>

        <!-- Sidebar -->
        <div class="space-y-6">
          <!-- Stats Card -->
          <div class="bg-gradient-to-br from-blue-600 to-blue-700 rounded-xl shadow-sm p-6 text-white">
            <h3 class="text-sm font-semibold mb-4 opacity-90">Estatísticas</h3>
            <div class="space-y-4">
              <div>
                <p class="text-2xl font-bold">{{ asset.total_chamados || 0 }}</p>
                <p class="text-sm opacity-90">Chamados Totais</p>
              </div>
              <div>
                <p class="text-2xl font-bold">{{ asset.chamados_abertos || 0 }}</p>
                <p class="text-sm opacity-90">Chamados Abertos</p>
              </div>
            </div>
          </div>

          <!-- Metadata -->
          <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <h3 class="text-sm font-semibold text-gray-900 mb-4">Metadados</h3>
            <div class="space-y-3 text-sm">
              <div class="flex items-start">
                <span class="mr-2">📅</span>
                <div>
                  <p class="text-gray-500">Criado em</p>
                  <p class="font-medium text-gray-900">{{ formatDate(asset.data_cadastro) }}</p>
                </div>
              </div>
              <div v-if="asset.data_atualizacao" class="flex items-start">
                <span class="mr-2">🕒</span>
                <div>
                  <p class="text-gray-500">Atualizado em</p>
                  <p class="font-medium text-gray-900">{{ formatDate(asset.data_atualizacao) }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else class="text-center py-16">
      <p class="text-6xl mb-4">⚠️</p>
      <h3 class="text-lg font-semibold text-gray-900 mb-2">Ativo não encontrado</h3>
      <p class="text-gray-500 mb-6">O ativo que você está procurando não existe.</p>
      <button
        @click="goBack"
        class="inline-flex items-center px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
      >
        ← Voltar para Ativos
      </button>
    </div>

    <!-- QR Code Modal -->
    <QRCodeModal
      :is-open="showQRCodeModal"
      :ativo-id="asset?.id || 0"
      @close="closeQRCodeModal"
    />
  </div>
</template>

<script>
import QRCodeModal from '@/components/modals/QRCodeModal.vue'
import { QrCode } from 'lucide-vue-next'

export default {
  components: {
    QRCodeModal,
    QrCode
  },
  data() {
    return {
      asset: null,
      relatedTasks: [],
      loading: true,
      loadingTasks: true,
      updating: false,
      editMode: false,
      editData: {},
      errorMessage: '',
      showQRCodeModal: false
    }
  },
  computed: {
    canEdit() {
      return true // Ajustar conforme authStore.user?.is_staff
    },
    statusBadgeClass() {
      if (!this.asset) return ''
      const classes = {
        'Ativo': 'px-3 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800',
        'Inativo': 'px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800',
        'Manutenção': 'px-3 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800'
      }
      return classes[this.asset.status] || 'px-3 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-700'
    }
  },
  async mounted() {
    await this.loadAsset()
    if (this.asset) {
      await this.loadRelatedTasks()
    }
  },
  methods: {
    formatDate(dateString) {
      if (!dateString) return 'Não informado'
      try {
        const date = new Date(dateString)
        return date.toLocaleDateString('pt-BR') + ' ' + date.toLocaleTimeString('pt-BR')
      } catch {
        return dateString
      }
    },
    getStatusBadgeClass(status) {
      const classes = {
        'ABERTO': 'px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800',
        'AGUARDANDO RESP': 'px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800',
        'EM ANDAMENTO': 'px-2 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-800',
        'REALIZADO': 'px-2 py-1 text-xs font-semibold rounded-full bg-cyan-100 text-cyan-800',
        'CONCLUÍDO': 'px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-800',
        'CANCELADO': 'px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-800'
      }
      return classes[status] || 'px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-700'
    },
    async loadAsset() {
      this.loading = true
      try {
        const id = window.location.pathname.split('/').pop()
        const response = await fetch(`http://localhost:8000/api/ativos/${id}/`, {
          headers: {
            'Authorization': `Token ${localStorage.getItem('token')}`
          }
        })
        
        if (!response.ok) throw new Error('Ativo não encontrado')
        
        this.asset = await response.json()
      } catch (error) {
        console.error('Erro ao carregar ativo:', error)
        this.asset = null
      } finally {
        this.loading = false
      }
    },
    async loadRelatedTasks() {
      if (!this.asset) return
      
      this.loadingTasks = true
      try {
        const response = await fetch(`http://localhost:8000/api/ativos/${this.asset.id}/chamados/`, {
          headers: {
            'Authorization': `Token ${localStorage.getItem('token')}`
          }
        })
        
        if (response.ok) {
          const data = await response.json()
          this.relatedTasks = data.chamados || []
        }
      } catch (error) {
        console.error('Erro ao carregar chamados:', error)
        this.relatedTasks = []
      } finally {
        this.loadingTasks = false
      }
    },
    enableEditMode() {
      this.editMode = true
      this.editData = { ...this.asset }
    },
    cancelEdit() {
      this.editMode = false
      this.editData = {}
      this.errorMessage = ''
    },
    async handleUpdate() {
      if (!this.asset) return
      
      this.updating = true
      this.errorMessage = ''
      
      try {
        const response = await fetch(`http://localhost:8000/api/ativos/${this.asset.id}/`, {
          method: 'PATCH',
          headers: {
            'Authorization': `Token ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.editData)
        })
        
        if (!response.ok) throw new Error('Erro ao atualizar ativo')
        
        this.asset = await response.json()
        this.editMode = false
        alert('Ativo atualizado com sucesso!')
      } catch (error) {
        console.error('Erro ao atualizar ativo:', error)
        this.errorMessage = 'Erro ao atualizar ativo'
      } finally {
        this.updating = false
      }
    },
    openQRCodeModal() {
      this.showQRCodeModal = true
    },
    closeQRCodeModal() {
      this.showQRCodeModal = false
    },
    goBack() {
      window.history.back()
    },
    goToTask(taskId) {
      window.location.href = `/tasks/${taskId}`
    }
  }
}
</script>