<template>
  <div class="max-w-4xl mx-auto">
    <div class="flex items-center mb-8">
      <router-link to="/assets" class="p-2 hover:bg-gray-100 rounded-lg transition mr-4" title="Voltar">
        <ArrowLeft :size="20" class="text-gray-600" />
      </router-link>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Cadastrar ativo</h1>
        <p class="text-sm text-gray-500 mt-1">Depois de salvar, imprima o QR code e cole no equipamento.</p>
      </div>
    </div>

    <AssetForm
      :saving="saving"
      :server-error="serverError"
      :server-field-errors="fieldErrors"
      :ambientes="ambientes"
      submit-label="Cadastrar ativo"
      @submit="create"
      @cancel="router.push('/assets')"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ArrowLeft } from 'lucide-vue-next'
import { assetsApi, extractError, extractFieldErrors } from '@/api'
import { useUiStore } from '@/stores/ui'
import AssetForm from '@/components/AssetForm.vue'

const router = useRouter()
const uiStore = useUiStore()

const saving = ref(false)
const serverError = ref('')
const fieldErrors = ref<Record<string, string>>({})
const ambientes = ref<string[]>([])

const create = async (payload: Record<string, any>) => {
  saving.value = true
  serverError.value = ''
  try {
    const ativo = await assetsApi.create(payload)
    uiStore.showToast('success', `Ativo ${ativo.codigo} cadastrado.`)
    router.push({ path: `/assets/${ativo.id}`, query: { qr: '1' } })
  } catch (err: any) {
    serverError.value = extractError(err, 'Não foi possível cadastrar o ativo.')
    fieldErrors.value = extractFieldErrors(err)
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    const todos = await assetsApi.getAll()
    ambientes.value = [...new Set(todos.map((a) => a.ambiente).filter(Boolean))].sort()
  } catch {
    // só sugestões de local; sem elas o formulário funciona igual
  }
})
</script>
