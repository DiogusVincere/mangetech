<!-- src/views/ForgotPasswordView.vue -->
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-12">
    <div class="w-full max-w-md">
      <!-- Logo -->
      <div class="flex justify-center mb-8">
        <div class="bg-blue-600 text-white p-4 rounded-full w-16 h-16 flex items-center justify-center shadow-lg">
          <Key class="w-8 h-8" />
        </div>
      </div>

      <!-- Card -->
      <div class="bg-white rounded-xl shadow-md p-8">
        <!-- Step 1: Email -->
        <div v-if="step === 1">
          <h1 class="text-2xl font-bold text-gray-800 text-center mb-2">Recuperar Senha</h1>
          <p class="text-gray-500 text-center mb-6">Digite seu email para receber o código</p>

          <form @submit.prevent="handleSendCode" class="space-y-4">
            <div>
              <label for="email" class="block text-gray-700 text-sm font-medium mb-2">
                Email
              </label>
              <input
                v-model="formData.email"
                type="email"
                id="email"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="seu@email.com"
              />
            </div>

            <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p class="text-sm text-red-800">{{ errorMessage }}</p>
            </div>

            <button
              type="submit"
              :disabled="loading"
              class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition font-medium"
            >
              {{ loading ? 'Enviando...' : 'Enviar Código' }}
            </button>
          </form>
        </div>

        <!-- Step 2: Token -->
        <div v-if="step === 2">
          <h1 class="text-2xl font-bold text-gray-800 text-center mb-2">Digite o Código</h1>
          <p class="text-gray-500 text-center mb-6">
            Enviamos um código de 6 dígitos para<br/>
            <strong>{{ maskEmail(formData.email) }}</strong>
          </p>

          <form @submit.prevent="handleVerifyToken" class="space-y-4">
            <div>
              <label class="block text-gray-700 text-sm font-medium mb-2 text-center">
                Código de Verificação
              </label>
              <div class="flex gap-2 justify-center">
                <input
                  v-for="i in 6"
                  :key="i"
                  v-model="tokenDigits[i-1]"
                  :ref="el => tokenInputs[i-1] = el as HTMLInputElement"
                  type="text"
                  maxlength="1"
                  class="w-12 h-14 text-center text-xl font-bold border-2 border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  @input="handleTokenInput(i-1, $event)"
                  @keydown="handleTokenKeydown(i-1, $event)"
                />
              </div>
            </div>

            <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p class="text-sm text-red-800">{{ errorMessage }}</p>
            </div>

            <button
              type="submit"
              :disabled="loading || !isTokenComplete"
              class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition font-medium"
            >
              {{ loading ? 'Verificando...' : 'Verificar Código' }}
            </button>

            <button
              type="button"
              @click="handleResendCode"
              :disabled="resendCooldown > 0"
              class="w-full py-2 text-sm text-blue-600 hover:text-blue-700 disabled:text-gray-400 transition"
            >
              {{ resendCooldown > 0 ? `Reenviar em ${resendCooldown}s` : 'Reenviar código' }}
            </button>
          </form>
        </div>

        <!-- Step 3: New Password -->
        <div v-if="step === 3">
          <h1 class="text-2xl font-bold text-gray-800 text-center mb-2">Nova Senha</h1>
          <p class="text-gray-500 text-center mb-6">Digite sua nova senha</p>

          <form @submit.prevent="handleResetPassword" class="space-y-4">
            <div>
              <label for="newPassword" class="block text-gray-700 text-sm font-medium mb-2">
                Nova Senha
              </label>
              <div class="relative">
                <input
                  v-model="formData.newPassword"
                  :type="showPassword ? 'text' : 'password'"
                  id="newPassword"
                  required
                  minlength="6"
                  class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 pr-10"
                  placeholder="Mínimo 6 caracteres"
                />
                <button
                  type="button"
                  @click="showPassword = !showPassword"
                  class="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
                >
                  <Eye v-if="showPassword" :size="20" />
                  <EyeOff v-else :size="20" />
                </button>
              </div>
            </div>

            <div>
              <label for="confirmPassword" class="block text-gray-700 text-sm font-medium mb-2">
                Confirmar Senha
              </label>
              <input
                v-model="formData.confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                id="confirmPassword"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Confirme sua senha"
              />
            </div>

            <div v-if="errorMessage" class="p-4 bg-red-50 border border-red-200 rounded-lg">
              <p class="text-sm text-red-800">{{ errorMessage }}</p>
            </div>

            <button
              type="submit"
              :disabled="loading || !isPasswordValid"
              class="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition font-medium"
            >
              {{ loading ? 'Redefinindo...' : 'Redefinir Senha' }}
            </button>
          </form>
        </div>

        <!-- Back to Login -->
        <div class="mt-6 text-center text-sm">
          <router-link to="/login" class="text-blue-600 hover:text-blue-700 font-medium">
            ← Voltar para o login
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUiStore } from '@/stores/ui'
import api from '@/api/client'
import { Key, Eye, EyeOff } from 'lucide-vue-next'
import { usersApi } from '@/api'

const router = useRouter()
const uiStore = useUiStore()

const step = ref(1)
const loading = ref(false)
const errorMessage = ref('')
const showPassword = ref(false)
const resendCooldown = ref(0)
let cooldownInterval: any = null

const formData = ref({
  email: '',
  token: '',
  newPassword: '',
  confirmPassword: ''
})

const tokenDigits = ref(['', '', '', '', '', ''])
const tokenInputs = ref<HTMLInputElement[]>([])

const isTokenComplete = computed(() => tokenDigits.value.every(d => d.length === 1))
const isPasswordValid = computed(() => {
  return formData.value.newPassword.length >= 6 &&
         formData.value.newPassword === formData.value.confirmPassword
})

const maskEmail = (email: string) => {
  const [user, domain] = email.split('@')
  if (user.length <= 2) return `${user}@${domain}`
  return `${user[0]}${'*'.repeat(user.length - 2)}${user[user.length - 1]}@${domain}`
}

const handleTokenInput = (index: number, event: Event) => {
  const input = event.target as HTMLInputElement
  const value = input.value

  if (value.length === 1 && index < 5) {
    tokenInputs.value[index + 1]?.focus()
  }
}

const handleTokenKeydown = (index: number, event: KeyboardEvent) => {
  if (event.key === 'Backspace' && !tokenDigits.value[index] && index > 0) {
    tokenInputs.value[index - 1]?.focus()
  }
}

const startResendCooldown = () => {
  resendCooldown.value = 60
  cooldownInterval = setInterval(() => {
    resendCooldown.value--
    if (resendCooldown.value <= 0) {
      clearInterval(cooldownInterval)
    }
  }, 1000)
}

const handleSendCode = async () => {
  loading.value = true
  errorMessage.value = ''

  try {
    await api.post('/auth/solicitar-recuperacao-senha/', {
      email: formData.value.email
    })

    uiStore.showToast('success', 'Código enviado para seu email!')
    step.value = 2
    startResendCooldown()
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Erro ao enviar código'
  } finally {
    loading.value = false
  }
}

const handleVerifyToken = async () => {
  formData.value.token = tokenDigits.value.join('')
  loading.value = true
  errorMessage.value = ''

  try {
    await api.post('/auth/verificar-token-recuperacao/', {
      email: formData.value.email,
      token: formData.value.token
    })

    uiStore.showToast('success', 'Código verificado!')
    step.value = 3
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Código inválido'
    tokenDigits.value = ['', '', '', '', '', '']
    tokenInputs.value[0]?.focus()
  } finally {
    loading.value = false
  }
}

const handleResetPassword = async () => {
  if (!isPasswordValid.value) return

  loading.value = true
  errorMessage.value = ''

  try {
    await api.post('/auth/resetar-senha/', {
      email: formData.value.email,
      token: formData.value.token,
      nova_senha: formData.value.newPassword,
      confirmar_senha: formData.value.confirmPassword
    })

    uiStore.showToast('success', 'Senha redefinida com sucesso!')
    router.push('/login')
  } catch (error: any) {
    errorMessage.value = error.response?.data?.message || 'Erro ao redefinir senha'
  } finally {
    loading.value = false
  }
}

const handleResendCode = async () => {
  await handleSendCode()
  tokenDigits.value = ['', '', '', '', '', '']
  tokenInputs.value[0]?.focus()
}

onUnmounted(() => {
  if (cooldownInterval) {
    clearInterval(cooldownInterval)
  }
})
</script>