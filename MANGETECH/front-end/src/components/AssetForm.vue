<template>
  <form @submit.prevent="submit" class="space-y-6" novalidate>
    <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"><Package :size="20" /> Identificação</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div>
          <label for="nome" class="label">Nome <span class="text-red-500">*</span></label>
          <input id="nome" v-model="form.nome" maxlength="200" :class="input(errors.nome)" placeholder="Ex.: Compressor de ar parafuso" />
          <p v-if="errors.nome" class="erro">{{ errors.nome }}</p>
        </div>
        <div>
          <label for="codigo" class="label">Código / tag do QR <span class="text-red-500">*</span></label>
          <input id="codigo" v-model="form.codigo" maxlength="50" :class="input(errors.codigo) + ' font-mono'" placeholder="Ex.: AST-005" />
          <p v-if="errors.codigo" class="erro">{{ errors.codigo }}</p>
          <p v-else class="text-xs text-gray-500 mt-1">É o texto gravado no QR code. Não pode repetir.</p>
        </div>
        <div>
          <label for="modelo" class="label">Modelo</label>
          <input id="modelo" v-model="form.modelo" maxlength="200" :class="input()" />
        </div>
        <div>
          <label for="fabricante" class="label">Fabricante</label>
          <input id="fabricante" v-model="form.fabricante" maxlength="200" :class="input()" />
        </div>
        <div>
          <label for="numero_serie" class="label">Número de série</label>
          <input id="numero_serie" v-model="form.numero_serie" maxlength="200" :class="input()" />
        </div>
        <div>
          <label for="fornecedor" class="label">Fornecedor</label>
          <input id="fornecedor" v-model="form.fornecedor" maxlength="200" :class="input()" />
        </div>
      </div>
    </section>

    <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"><MapPin :size="20" /> Localização e status</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div>
          <label for="ambiente" class="label">Ambiente / local <span class="text-red-500">*</span></label>
          <input id="ambiente" v-model="form.ambiente" maxlength="200" :class="input(errors.ambiente)" placeholder="Ex.: Usinagem" list="ambientes-conhecidos" />
          <datalist id="ambientes-conhecidos">
            <option v-for="a in ambientes" :key="a" :value="a" />
          </datalist>
          <p v-if="errors.ambiente" class="erro">{{ errors.ambiente }}</p>
          <p v-else-if="initial" class="text-xs text-gray-500 mt-1">Mudar o local registra uma movimentação no histórico.</p>
        </div>
        <div>
          <label for="status" class="label">Status <span class="text-red-500">*</span></label>
          <select id="status" v-model="form.status" :class="input() + ' bg-white'">
            <option v-for="s in ASSET_STATUS_OPTIONS" :key="s" :value="s">{{ s }}</option>
          </select>
        </div>
      </div>
    </section>

    <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2"><FileText :size="20" /> Aquisição e garantia</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div>
          <label for="data_aquisicao" class="label">Data de aquisição</label>
          <input id="data_aquisicao" v-model="form.data_aquisicao" type="date" :class="input()" />
        </div>
        <div>
          <label for="valor" class="label">Valor (R$)</label>
          <input id="valor" v-model="form.valor" type="number" min="0" step="0.01" :class="input(errors.valor)" placeholder="0,00" />
          <p v-if="errors.valor" class="erro">{{ errors.valor }}</p>
        </div>
        <div>
          <label for="garantia" class="label">Garantia (meses)</label>
          <input id="garantia" v-model="form.garantia_meses" type="number" min="0" step="1" :class="input(errors.garantia_meses)" />
          <p v-if="errors.garantia_meses" class="erro">{{ errors.garantia_meses }}</p>
        </div>
      </div>
      <div class="mt-5">
        <label for="observacoes" class="label">Observações</label>
        <textarea id="observacoes" v-model="form.observacoes" rows="3" :class="input() + ' resize-y'" placeholder="Acessórios, contrato de manutenção, cuidados…"></textarea>
      </div>
    </section>

    <div v-if="serverError" class="bg-red-50 border border-red-200 rounded-lg p-4 text-sm text-red-800">{{ serverError }}</div>

    <div class="flex justify-end gap-4">
      <button type="button" @click="emit('cancel')" class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50">
        Cancelar
      </button>
      <button type="submit" :disabled="saving" class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50">
        {{ saving ? 'Salvando…' : submitLabel }}
      </button>
    </div>
  </form>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { FileText, MapPin, Package } from 'lucide-vue-next'
import type { Asset } from '@/types'
import { ASSET_STATUS_OPTIONS } from '@/utils/display'

const props = withDefaults(
  defineProps<{
    initial?: Asset | null
    saving?: boolean
    serverError?: string
    serverFieldErrors?: Record<string, string>
    submitLabel?: string
    ambientes?: string[]
  }>(),
  { initial: null, saving: false, serverError: '', serverFieldErrors: () => ({}), submitLabel: 'Salvar', ambientes: () => [] }
)

const emit = defineEmits<{
  submit: [payload: Record<string, any>]
  cancel: []
}>()

const vazio = () => ({
  nome: '',
  codigo: '',
  modelo: '',
  fabricante: '',
  numero_serie: '',
  fornecedor: '',
  ambiente: '',
  status: 'Ativo' as string,
  data_aquisicao: '',
  valor: '' as string | number,
  garantia_meses: '' as string | number,
  observacoes: '',
})

const form = ref(vazio())
const errors = ref<Record<string, string>>({})

watch(
  () => props.initial,
  (a) => {
    form.value = a
      ? {
          nome: a.nome,
          codigo: a.codigo,
          modelo: a.modelo || '',
          fabricante: a.fabricante || '',
          numero_serie: a.numero_serie || '',
          fornecedor: a.fornecedor || '',
          ambiente: a.ambiente || '',
          status: a.status,
          data_aquisicao: a.data_aquisicao || '',
          valor: a.valor ?? '',
          garantia_meses: a.garantia_meses ?? '',
          observacoes: a.observacoes || '',
        }
      : vazio()
  },
  { immediate: true }
)

// Erros por campo vindos da API (ex.: código repetido).
watch(
  () => props.serverFieldErrors,
  (e) => {
    errors.value = { ...errors.value, ...e }
  }
)

const input = (erro?: string) =>
  `w-full px-4 py-2.5 border rounded-lg focus:outline-none focus:ring-2 transition ${
    erro ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
  }`

const validar = () => {
  const f = form.value
  const e: Record<string, string> = {}
  if (f.nome.trim().length < 2) e.nome = 'Informe o nome do ativo.'
  if (!f.codigo.trim()) e.codigo = 'Informe o código.'
  else if (f.codigo.includes('/')) e.codigo = 'O código não pode ter barra (/).'
  if (!f.ambiente.trim()) e.ambiente = 'Informe onde o ativo fica.'
  if (f.valor !== '' && Number(f.valor) < 0) e.valor = 'Valor inválido.'
  if (f.garantia_meses !== '' && (!Number.isInteger(Number(f.garantia_meses)) || Number(f.garantia_meses) < 0)) {
    e.garantia_meses = 'Use um número inteiro de meses.'
  }
  errors.value = e
  return !Object.keys(e).length
}

const submit = () => {
  if (!validar()) return
  const f = form.value
  // Campos opcionais vazios vão como "" / null para que apagar um valor também salve.
  emit('submit', {
    nome: f.nome.trim(),
    codigo: f.codigo.trim(),
    modelo: f.modelo.trim(),
    fabricante: f.fabricante.trim(),
    numero_serie: f.numero_serie.trim(),
    fornecedor: f.fornecedor.trim(),
    ambiente: f.ambiente.trim(),
    status: f.status,
    data_aquisicao: f.data_aquisicao || null,
    valor: f.valor === '' ? null : Number(f.valor).toFixed(2),
    garantia_meses: f.garantia_meses === '' ? null : Number(f.garantia_meses),
    observacoes: f.observacoes.trim(),
  })
}
</script>

<style scoped>
.label {
  @apply block text-sm font-semibold text-gray-700 mb-2;
}
.erro {
  @apply text-sm text-red-600 mt-1;
}
</style>
