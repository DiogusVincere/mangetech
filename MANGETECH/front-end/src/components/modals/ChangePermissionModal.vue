<template>
  <div v-if="isOpen" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4" @click.self="$emit('close')">
    <div class="bg-white rounded-lg shadow-xl max-w-md w-full overflow-hidden">
      <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
        <h3 class="text-lg font-semibold text-gray-900">Alterar Permissões</h3>
        <button @click="$emit('close')" class="text-gray-400 hover:text-gray-600">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
        </button>
      </div>

      <div class="p-6 space-y-4">
        <p class="text-sm text-gray-600 mb-4">
          Selecione o nível de acesso para <strong>{{ userName }}</strong>:
        </p>

        <div class="space-y-3">
          <label class="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition" :class="{'border-blue-500 bg-blue-50': selectedRole === 'requester'}">
            <input type="radio" v-model="selectedRole" value="requester" class="h-4 w-4 text-blue-600 focus:ring-blue-500">
            <div class="ml-3">
              <span class="block text-sm font-medium text-gray-900">Solicitante (Padrão)</span>
              <span class="block text-xs text-gray-500">Apenas abre chamados e visualiza os seus.</span>
            </div>
          </label>

          <label class="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition" :class="{'border-purple-500 bg-purple-50': selectedRole === 'technician'}">
            <input type="radio" v-model="selectedRole" value="technician" class="h-4 w-4 text-purple-600 focus:ring-purple-500">
            <div class="ml-3">
              <span class="block text-sm font-medium text-gray-900">Técnico</span>
              <span class="block text-xs text-gray-500">Pode atender chamados e gerenciar ativos.</span>
            </div>
          </label>

          <label class="flex items-center p-3 border rounded-lg cursor-pointer hover:bg-gray-50 transition" :class="{'border-red-500 bg-red-50': selectedRole === 'admin'}">
            <input type="radio" v-model="selectedRole" value="admin" class="h-4 w-4 text-red-600 focus:ring-red-500">
            <div class="ml-3">
              <span class="block text-sm font-medium text-gray-900">Administrador</span>
              <span class="block text-xs text-gray-500">Acesso total ao sistema e configurações.</span>
            </div>
          </label>
        </div>
      </div>

      <div class="px-6 py-4 bg-gray-50 flex justify-end gap-3">
        <button @click="$emit('close')" class="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-white">Cancelar</button>
        <button 
          @click="handleSave" 
          :disabled="isSubmitting"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center"
        >
          <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></span>
          Salvar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  isOpen: boolean
  userName: string
  isStaff: boolean
  isSuperuser: boolean
  isSubmitting: boolean
}>()

const emit = defineEmits(['close', 'save'])

const selectedRole = ref('requester')

// Atualiza o radio button quando o modal abre baseado nas props atuais
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    if (props.isSuperuser) {
      selectedRole.value = 'admin'
    } else if (props.isStaff) {
      selectedRole.value = 'technician'
    } else {
      selectedRole.value = 'requester'
    }
  }
})

const handleSave = () => {
  emit('save', selectedRole.value)
}
</script>