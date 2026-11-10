<template>
  <div class="max-w-4xl mx-auto">
    <div class="flex items-center mb-8">
      <button type="button" @click="cancel" class="p-2 hover:bg-gray-100 rounded-lg transition mr-4" title="Voltar">
        <ArrowLeft :size="20" class="text-gray-600" />
      </button>
      <div>
        <h1 class="text-2xl font-bold text-gray-900">{{ isEdit ? `Editar chamado #${taskId}` : 'Novo chamado' }}</h1>
        <p class="text-sm text-gray-500 mt-1">
          {{ isEdit ? 'Altere os dados e os responsáveis. Para mudar o status, use "Mudar status" no chamado.' : 'Descreva o problema e o equipamento afetado.' }}
        </p>
      </div>
    </div>

    <div v-if="loadingTask" class="flex justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <form v-else @submit.prevent="handleSubmit" class="space-y-6" novalidate>
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <label for="titulo" class="block text-sm font-semibold text-gray-700 mb-2">
          Título <span class="text-red-500">*</span>
        </label>
        <input
          v-model="form.titulo"
          id="titulo"
          type="text"
          maxlength="255"
          :class="inputClass(errors.titulo)"
          placeholder="Ex.: Compressor desarmando por alta temperatura"
          @blur="validate('titulo')"
        />
        <p v-if="errors.titulo" class="text-sm text-red-600 mt-1">{{ errors.titulo }}</p>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label for="ativo" class="block text-sm font-semibold text-gray-700 mb-2">
              Ativo / equipamento <span class="text-red-500">*</span>
            </label>
            <div v-if="loadingAtivos" class="px-4 py-3 border border-gray-300 rounded-lg bg-gray-50 text-sm text-gray-500">
              Carregando ativos…
            </div>
            <template v-else>
              <select
                id="ativo"
                v-model="ativoSelecionado"
                @change="onAtivoChange"
                :class="inputClass(errors.ativo) + ' bg-white'"
              >
                <option value="">Selecione um ativo</option>
                <option v-for="asset in ativos" :key="asset.id" :value="String(asset.id)">
                  {{ asset.codigo }} · {{ asset.nome }}{{ asset.status !== 'Ativo' ? ` (${asset.status})` : '' }}
                </option>
                <option value="outro">Outro (não cadastrado)…</option>
              </select>
              <input
                v-if="ativoSelecionado === 'outro'"
                v-model="form.ativo"
                type="text"
                maxlength="200"
                :class="inputClass(errors.ativo) + ' mt-2'"
                placeholder="Descreva o equipamento"
              />
              <p v-if="errors.ativo" class="text-sm text-red-600 mt-1">{{ errors.ativo }}</p>
              <p v-else-if="!ativos.length" class="text-xs text-amber-700 mt-1">
                Nenhum ativo cadastrado ainda.
                <router-link v-if="authStore.isAdmin" to="/assets/create" class="underline">Cadastrar ativo</router-link>
              </p>
            </template>
          </div>

          <div>
            <label for="ambiente" class="block text-sm font-semibold text-gray-700 mb-2">Ambiente / localização</label>
            <input
              v-model="form.ambiente"
              id="ambiente"
              type="text"
              maxlength="200"
              :class="inputClass()"
              placeholder="Preenchido pelo ativo; ajuste se precisar"
            />
            <p class="text-xs text-gray-500 mt-1">Onde o problema está acontecendo</p>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <label for="descricao" class="block text-sm font-semibold text-gray-700 mb-2">
          Descrição <span class="text-red-500">*</span>
        </label>
        <textarea
          v-model="form.descricao"
          id="descricao"
          rows="5"
          :class="inputClass(errors.descricao) + ' resize-y'"
          placeholder="O que está acontecendo, desde quando, o que já foi tentado…"
          @blur="validate('descricao')"
        ></textarea>
        <p v-if="errors.descricao" class="text-sm text-red-600 mt-1">{{ errors.descricao }}</p>
        <p v-else class="text-xs text-gray-500 mt-1">{{ form.descricao.trim().length }} caracteres (mínimo 15)</p>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label for="data-sugerida" class="block text-sm font-semibold text-gray-700 mb-2">Prazo sugerido</label>
            <input v-model="form.data_sugerida" id="data-sugerida" type="datetime-local" :class="inputClass()" />
            <p class="text-xs text-gray-500 mt-1">Opcional. Depois desse prazo o chamado aparece como atrasado.</p>
          </div>
          <div>
            <span class="block text-sm font-semibold text-gray-700 mb-2">Urgência <span class="text-red-500">*</span></span>
            <div class="grid grid-cols-4 gap-2">
              <button
                v-for="nivel in niveis"
                :key="nivel"
                type="button"
                @click="form.urgencia = nivel"
                :class="[
                  'px-2 py-3 text-sm font-medium rounded-lg border-2 transition-all',
                  form.urgencia === nivel ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-gray-300 hover:border-gray-400 text-gray-700',
                ]"
              >
                {{ nivel }}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <span class="block text-sm font-semibold text-gray-700 mb-3">Responsáveis (opcional)</span>
        <div class="relative" ref="dropdownContainer">
          <input
            v-model="searchResponsavel"
            type="text"
            placeholder="Buscar pessoas pelo nome ou e-mail…"
            class="w-full px-4 py-3 pr-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            @focus="showDropdown = true"
            @input="showDropdown = true"
          />
          <Search :size="18" class="absolute right-3 top-3.5 text-gray-400 pointer-events-none" />
          <div
            v-if="showDropdown && filteredUsers.length"
            class="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-auto"
          >
            <button
              v-for="user in filteredUsers"
              :key="user.id"
              type="button"
              @click="toggleResponsavel(user.id)"
              :class="[
                'w-full text-left px-4 py-3 border-b border-gray-100 last:border-b-0 flex items-center justify-between',
                form.responsaveis.includes(user.id) ? 'bg-blue-50' : 'hover:bg-gray-50',
              ]"
            >
              <span class="flex items-center gap-3">
                <span class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                  {{ initials(user) }}
                </span>
                <span>
                  <span class="block font-medium text-gray-900">{{ fullName(user) }}</span>
                  <span class="block text-xs text-gray-500">{{ user.email }}</span>
                </span>
              </span>
              <CheckCircle v-if="form.responsaveis.includes(user.id)" :size="20" class="text-blue-600" />
            </button>
          </div>
        </div>

        <div v-if="selectedUsers.length" class="mt-4 flex flex-wrap gap-2">
          <span
            v-for="user in selectedUsers"
            :key="user.id"
            class="flex items-center gap-2 px-3 py-2 bg-blue-50 border border-blue-200 rounded-lg text-sm font-medium text-blue-900"
          >
            {{ fullName(user) }}
            <button type="button" @click="toggleResponsavel(user.id)" class="p-0.5 hover:bg-blue-100 rounded" :title="`Remover ${fullName(user)}`">
              <X :size="14" class="text-blue-600" />
            </button>
          </span>
        </div>
      </div>

      <div v-if="submitError" class="bg-red-50 border border-red-200 rounded-lg p-4 text-sm text-red-800">{{ submitError }}</div>

      <div class="flex justify-end gap-4">
        <button type="button" @click="cancel" class="px-6 py-3 border border-gray-300 rounded-lg text-gray-700 font-medium hover:bg-gray-50">
          Cancelar
        </button>
        <button
          type="submit"
          :disabled="saving"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ saving ? 'Salvando…' : isEdit ? 'Salvar alterações' : 'Abrir chamado' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, CheckCircle, Search, X } from 'lucide-vue-next'
import { assetsApi, tasksApi, usersApi, extractError } from '@/api'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import type { Asset, User } from '@/types'
import { URGENCIA_OPTIONS, fullName, initials, toDateTimeLocal } from '@/utils/display'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const taskId = route.params.id ? String(route.params.id) : ''
const isEdit = !!taskId
const niveis = [...URGENCIA_OPTIONS].reverse()

const form = ref({
  titulo: '',
  ativo: '',
  ambiente: '',
  descricao: '',
  urgencia: 'Média' as string,
  data_sugerida: '',
  responsaveis: [] as number[],
})
const ativoSelecionado = ref('') // id do ativo, 'outro' ou ''
const errors = ref<Record<string, string>>({})
const submitError = ref('')
const saving = ref(false)
const loadingTask = ref(isEdit)
const loadingAtivos = ref(true)

const usuarios = ref<User[]>([])
const ativos = ref<Asset[]>([])
const searchResponsavel = ref('')
const showDropdown = ref(false)
const dropdownContainer = ref<HTMLElement | null>(null)

const inputClass = (erro?: string) =>
  `w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition ${
    erro ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
  }`

const filteredUsers = computed(() => {
  const q = searchResponsavel.value.trim().toLowerCase()
  const lista = q
    ? usuarios.value.filter((u) => fullName(u).toLowerCase().includes(q) || (u.email || '').toLowerCase().includes(q))
    : usuarios.value
  return lista.slice(0, 20)
})

const selectedUsers = computed(() => usuarios.value.filter((u) => form.value.responsaveis.includes(u.id)))

const validate = (campo: 'titulo' | 'descricao' | 'ativo') => {
  delete errors.value[campo]
  const f = form.value
  if (campo === 'titulo' && f.titulo.trim().length < 5) errors.value.titulo = 'O título precisa ter pelo menos 5 caracteres.'
  if (campo === 'descricao' && f.descricao.trim().length < 15) errors.value.descricao = 'Descreva com pelo menos 15 caracteres.'
  if (campo === 'ativo' && !ativoSelecionado.value) errors.value.ativo = 'Escolha o ativo (ou "Outro").'
  if (campo === 'ativo' && ativoSelecionado.value === 'outro' && !f.ativo.trim()) errors.value.ativo = 'Descreva o equipamento.'
}

const onAtivoChange = () => {
  delete errors.value.ativo
  const ativo = ativos.value.find((a) => String(a.id) === ativoSelecionado.value)
  if (ativo) {
    form.value.ambiente = ativo.ambiente
    form.value.ativo = `${ativo.codigo} - ${ativo.nome}`
  } else if (ativoSelecionado.value === 'outro') {
    form.value.ativo = ''
  }
}

const toggleResponsavel = (id: number) => {
  const lista = form.value.responsaveis
  form.value.responsaveis = lista.includes(id) ? lista.filter((x) => x !== id) : [...lista, id]
  searchResponsavel.value = ''
}

const cancel = () => router.push(isEdit ? `/tasks/${taskId}` : '/tasks')

const handleSubmit = async () => {
  ;(['titulo', 'descricao', 'ativo'] as const).forEach(validate)
  if (Object.keys(errors.value).length) {
    uiStore.showToast('error', 'Confira os campos destacados.')
    return
  }

  saving.value = true
  submitError.value = ''
  const f = form.value
  const ativoId = ativoSelecionado.value && ativoSelecionado.value !== 'outro' ? Number(ativoSelecionado.value) : null
  const payload = {
    titulo: f.titulo.trim(),
    descricao: f.descricao.trim(),
    ativo: f.ativo.trim(),
    ativo_ref: ativoId,
    ambiente: f.ambiente.trim(),
    urgencia: f.urgencia,
    data_sugerida: f.data_sugerida ? new Date(f.data_sugerida).toISOString() : null,
    responsaveis: f.responsaveis,
  }

  try {
    const salvo = isEdit ? await tasksApi.update(taskId, payload) : await tasksApi.create(payload)
    uiStore.showToast('success', isEdit ? 'Chamado atualizado.' : `Chamado #${salvo.id} aberto.`)
    router.push(`/tasks/${salvo.id}`)
  } catch (err) {
    submitError.value = extractError(err, 'Não foi possível salvar o chamado.')
  } finally {
    saving.value = false
  }
}

const loadTask = async () => {
  try {
    const t = await tasksApi.getById(taskId)
    form.value = {
      titulo: t.titulo,
      ativo: t.ativo,
      ambiente: t.ambiente,
      descricao: t.descricao,
      urgencia: t.urgencia,
      data_sugerida: toDateTimeLocal(t.data_sugerida),
      responsaveis: t.responsaveis || [],
    }
    ativoSelecionado.value = t.ativo_ref ? String(t.ativo_ref) : t.ativo ? 'outro' : ''
  } catch (err) {
    uiStore.showToast('error', extractError(err, 'Chamado não encontrado.'))
    router.push('/tasks')
  } finally {
    loadingTask.value = false
  }
}

const loadAtivos = async () => {
  try {
    ativos.value = await assetsApi.getAll({ ordering: 'codigo' })
    // Vindo da tela do ativo ("Abrir chamado"): já deixa o ativo escolhido.
    const preset = route.query.ativo as string | undefined
    if (!isEdit && preset && ativos.value.some((a) => String(a.id) === preset)) {
      ativoSelecionado.value = preset
      onAtivoChange()
    }
  } catch (err) {
    ativoSelecionado.value = 'outro'
    uiStore.showToast('warning', 'Não foi possível carregar os ativos; descreva o equipamento.')
  } finally {
    loadingAtivos.value = false
  }
}

const loadUsuarios = async () => {
  try {
    usuarios.value = (await usersApi.getAll({ ordering: 'first_name' })).filter((u) => u.is_active !== false)
  } catch {
    usuarios.value = []
  }
}

const handleClickOutside = (event: MouseEvent) => {
  if (dropdownContainer.value && !dropdownContainer.value.contains(event.target as Node)) {
    showDropdown.value = false
  }
}

onMounted(async () => {
  document.addEventListener('click', handleClickOutside)
  await Promise.all([loadAtivos(), loadUsuarios(), isEdit ? loadTask() : Promise.resolve()])
})

onUnmounted(() => document.removeEventListener('click', handleClickOutside))
</script>
