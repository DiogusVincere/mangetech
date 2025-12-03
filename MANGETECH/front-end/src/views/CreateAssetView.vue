<!-- src/views/CreateAssetView.vue -->
<template>
  <div class="max-w-4xl mx-auto px-4 py-6">
    <!-- Header -->
    <div class="flex items-center mb-8">
      <router-link
        to="/assets"
        class="p-2 hover:bg-gray-100 rounded-lg transition mr-4"
      >
        <ArrowLeft :size="20" class="text-gray-600" />
      </router-link>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Cadastrar Novo Ativo</h1>
        <p class="text-sm text-gray-500 mt-1">Preencha as informações do equipamento</p>
      </div>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleSubmit" class="space-y-6">
      <!-- Informações Básicas -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Package :size="20" class="mr-2 text-blue-600" />
          Informações Básicas
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Nome -->
          <div>
            <label for="nome" class="block text-sm font-semibold text-gray-700 mb-2">
              Nome do Ativo <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.nome"
              type="text"
              id="nome"
              required
              minlength="3"
              :class="[
                'w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition',
                errors.nome ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
              ]"
              placeholder="Ex: Impressora HP LaserJet Pro"
              @blur="validateField('nome')"
            />
            <p v-if="errors.nome" class="text-sm text-red-600 mt-1 flex items-center">
              <AlertCircle :size="14" class="mr-1" />
              {{ errors.nome }}
            </p>
          </div>

          <!-- Código -->
          <div>
            <label for="codigo" class="block text-sm font-semibold text-gray-700 mb-2">
              Código/Patrimônio <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.codigo"
              type="text"
              id="codigo"
              required
              :class="[
                'w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition',
                errors.codigo ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
              ]"
              placeholder="Ex: IMP-001 ou 123456"
              @blur="validateField('codigo')"
            />
            <p v-if="errors.codigo" class="text-sm text-red-600 mt-1 flex items-center">
              <AlertCircle :size="14" class="mr-1" />
              {{ errors.codigo }}
            </p>
          </div>

          <!-- Modelo -->
          <div>
            <label for="modelo" class="block text-sm font-semibold text-gray-700 mb-2">
              Modelo <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.modelo"
              type="text"
              id="modelo"
              required
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="Ex: HP LaserJet Pro M404dn"
            />
          </div>

          <!-- Fabricante -->
          <div>
            <label for="fabricante" class="block text-sm font-semibold text-gray-700 mb-2">
              Fabricante
            </label>
            <input
              v-model="formData.fabricante"
              type="text"
              id="fabricante"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="Ex: HP, Dell, Lenovo"
            />
          </div>
        </div>
      </div>

      <!-- Localização -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <MapPin :size="20" class="mr-2 text-blue-600" />
          Localização
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Ambiente -->
          <div>
            <label for="ambiente" class="block text-sm font-semibold text-gray-700 mb-2">
              Ambiente/Sala <span class="text-red-500">*</span>
            </label>
            <input
              v-model="formData.ambiente"
              type="text"
              id="ambiente"
              required
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="Ex: Sala 102 - Administrativo"
            />
          </div>

          <!-- Status -->
          <div>
            <label for="status" class="block text-sm font-semibold text-gray-700 mb-2">
              Status <span class="text-red-500">*</span>
            </label>
            <select
              v-model="formData.status"
              id="status"
              required
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition appearance-none"
            >
              <option value="Ativo">Ativo</option>
              <option value="Inativo">Inativo</option>
              <option value="Manutenção">Manutenção</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Detalhes Técnicos -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <Settings :size="20" class="mr-2 text-blue-600" />
          Detalhes Técnicos (Opcional)
        </h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Número de Série -->
          <div>
            <label for="numero_serie" class="block text-sm font-semibold text-gray-700 mb-2">
              Número de Série
            </label>
            <input
              v-model="formData.numero_serie"
              type="text"
              id="numero_serie"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="Ex: SN123456789"
            />
          </div>

          <!-- Data de Aquisição -->
          <div>
            <label for="data_aquisicao" class="block text-sm font-semibold text-gray-700 mb-2">
              Data de Aquisição
            </label>
            <input
              v-model="formData.data_aquisicao"
              type="date"
              id="data_aquisicao"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
            />
          </div>

          <!-- Valor -->
          <div>
            <label for="valor" class="block text-sm font-semibold text-gray-700 mb-2">
              Valor de Aquisição
            </label>
            <div class="relative">
              <span class="absolute left-3 top-3 text-gray-500">R$</span>
              <input
                v-model="formData.valor"
                type="number"
                step="0.01"
                min="0"
                id="valor"
                class="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
                placeholder="0,00"
              />
            </div>
          </div>

          <!-- Garantia (meses) -->
          <div>
            <label for="garantia" class="block text-sm font-semibold text-gray-700 mb-2">
              Garantia (meses)
            </label>
            <input
              v-model="formData.garantia_meses"
              type="number"
              min="0"
              id="garantia"
              class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition"
              placeholder="12"
            />
          </div>
        </div>
      </div>

      <!-- Observações -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <FileText :size="20" class="mr-2 text-blue-600" />
          Observações
        </h2>
        
        <textarea
          v-model="formData.observacoes"
          rows="4"
          class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 transition resize-none"
          placeholder="Informações adicionais sobre o ativo..."
        ></textarea>
      </div>

      <!-- Error Message -->
      <div
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start"
      >
        <AlertCircle :size="20" class="text-red-600 mr-2 flex-shrink-0 mt-0.5" />
        <p class="text-sm text-red-800">{{ errorMessage }}</p>
      </div>

      <!-- Botões -->
      <div class="flex justify-end gap-4 pt-6">
        <router-link
          to="/assets"
          class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50 transition"
        >
          Cancelar
        </router-link>
        <button
          type="submit"
          :disabled="loading || !isFormValid"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition shadow-sm flex items-center gap-2"
        >
          <span v-if="!loading">Cadastrar Ativo</span>
          <span v-else class="flex items-center gap-2">
            <div class="loader"></div>
            Cadastrando...
          </span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAssetsStore } from '@/stores/assets'
import { useUiStore } from '@/stores/ui'
import {
  ArrowLeft,
  AlertCircle,
  Package,
  MapPin,
  Settings,
  FileText
} from 'lucide-vue-next'

const router = useRouter()
const assetsStore = useAssetsStore()
const uiStore = useUiStore()

const formData = ref({
  nome: '',
  codigo: '',
  modelo: '',
  fabricante: '',
  ambiente: '',
  status: 'Ativo',
  numero_serie: '',
  data_aquisicao: '',
  valor: null as number | null,
  garantia_meses: null as number | null,
  observacoes: ''
})

const errors = ref<Record<string, string>>({})
const loading = ref(false)
const errorMessage = ref('')

const isFormValid = computed(() => {
  return formData.value.nome.length >= 3 &&
         formData.value.codigo &&
         formData.value.modelo &&
         formData.value.ambiente &&
         formData.value.status
})

const validateField = (field: string) => {
  errors.value[field] = ''

  if (field === 'nome' && formData.value.nome.length < 3) {
    errors.value.nome = 'O nome deve ter pelo menos 3 caracteres'
  }

  if (field === 'codigo' && !formData.value.codigo) {
    errors.value.codigo = 'O código é obrigatório'
  }
}

const handleSubmit = async () => {
  // Validate all fields
  validateField('nome')
  validateField('codigo')

  if (!isFormValid.value) {
    uiStore.showToast('error', 'Por favor, preencha todos os campos obrigatórios')
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    // Preparar dados para envio
    const assetData: any = {
      nome: formData.value.nome,
      codigo: formData.value.codigo,
      modelo: formData.value.modelo,
      ambiente: formData.value.ambiente,
      status: formData.value.status,
    }

    // Adicionar campos opcionais apenas se preenchidos
    if (formData.value.fabricante) assetData.fabricante = formData.value.fabricante
    if (formData.value.numero_serie) assetData.numero_serie = formData.value.numero_serie
    if (formData.value.data_aquisicao) assetData.data_aquisicao = formData.value.data_aquisicao
    if (formData.value.valor) assetData.valor = formData.value.valor
    if (formData.value.garantia_meses) assetData.garantia_meses = formData.value.garantia_meses
    if (formData.value.observacoes) assetData.observacoes = formData.value.observacoes

    const createdAsset = await assetsStore.createAsset(assetData)

    uiStore.showToast('success', 'Ativo cadastrado com sucesso!')
    router.push(`/assets/${createdAsset.id}`)
  } catch (error: any) {
    console.error('Erro ao cadastrar ativo:', error)
    errorMessage.value = error.response?.data?.message || 'Erro ao cadastrar ativo'
    uiStore.showToast('error', 'Erro ao cadastrar ativo')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.loader {
  border: 3px solid rgba(255, 255, 255, 0.3);
  border-top: 3px solid #ffffff;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>