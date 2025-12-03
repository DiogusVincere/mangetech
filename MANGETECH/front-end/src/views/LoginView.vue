<!-- src/views/LoginView.vue - VERSÃO CORRIGIDA -->
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-12">
    <div class="w-full max-w-md">
      <!-- Logo -->
      <div class="flex justify-center mb-8" data-aos="fade-down">
        <div class="bg-blue-600 text-white p-4 rounded-full w-16 h-16 flex items-center justify-center shadow-lg">
          <Lock class="w-8 h-8" />
        </div>
      </div>

      <!-- Card -->
      <div class="bg-white rounded-xl shadow-md p-8" data-aos="fade-up">
        <h1 class="text-2xl font-bold text-gray-800 text-center mb-2">Entrar</h1>
        <p class="text-gray-500 text-center mb-6">Acesse sua conta para continuar</p>

        <!-- Form -->
        <form @submit.prevent="handleLogin" class="space-y-6">
          <!-- Email Field -->
          <div>
            <label for="email" class="block text-gray-700 text-sm font-medium mb-2">
              Email
            </label>
            <div class="relative">
              <input
                v-model="credentials.email"
                type="email"
                id="email"
                name="email"
                autocomplete="email"
                required
                :class="[
                  'w-full px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 transition',
                  emailError ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500 focus:border-transparent'
                ]"
                placeholder="seu@email.com"
                @input="validateEmail"
                @blur="validateEmail"
              />
              <div v-if="emailError" class="absolute right-3 top-3 text-red-500">
                <AlertCircle :size="20" />
              </div>
            </div>
            <p v-if="emailError" class="text-red-500 text-xs mt-1">
              {{ emailError }}
            </p>
          </div>

          <!-- Password Field -->
          <div>
            <label for="password" class="block text-gray-700 text-sm font-medium mb-2">
              Senha
            </label>
            <div class="relative">
              <input
                v-model="credentials.password"
                :type="showPassword ? 'text' : 'password'"
                id="password"
                name="password"
                autocomplete="current-password"
                required
                class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition pr-10"
                placeholder="••••••••"
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

          <!-- Remember Me -->
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                v-model="rememberMe"
                id="remember"
                type="checkbox"
                class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label for="remember" class="ml-2 block text-sm text-gray-700">
                Lembrar-me
              </label>
            </div>
            <router-link
              to="/forgot-password"
              class="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              Esqueci a senha
            </router-link>
          </div>

          <!-- Error Message -->
          <div
            v-if="errorMessage"
            class="p-4 bg-red-50 border border-red-200 rounded-lg flex items-start"
          >
            <AlertCircle :size="20" class="text-red-600 mr-2 flex-shrink-0 mt-0.5" />
            <p class="text-sm text-red-800">{{ errorMessage }}</p>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading || !isFormValid"
            :class="[
              'w-full font-medium py-4 px-4 rounded-lg transition duration-150 flex items-center justify-center relative overflow-hidden',
              loading ? 'bg-blue-400 cursor-not-allowed' : 
              buttonState === 'success' ? 'bg-green-500 hover:bg-green-600' :
              'bg-blue-600 hover:bg-blue-700 active:scale-95',
              'text-white shadow-sm'
            ]"
          >
            <!-- Ripple Effect -->
            <span
              v-if="rippleEffect"
              class="absolute inset-0 bg-white opacity-30 rounded-full animate-ping"
            ></span>

            <!-- Button Content -->
            <span v-if="!loading && buttonState === 'idle'" class="flex items-center">
              Entrar
            </span>
            <span v-else-if="!loading && buttonState === 'success'" class="flex items-center">
              <CheckCircle :size="20" class="mr-2" />
              Login realizado!
            </span>
            <span v-else class="flex items-center">
              <div class="loader mr-2"></div>
              Entrando...
            </span>
          </button>
        </form>

        <!-- Links -->
        <div class="mt-6 text-center text-sm">
          <router-link to="/register" class="text-blue-600 hover:text-blue-700 font-medium">
            Criar uma conta
          </router-link>
          <span class="mx-2 text-gray-400">•</span>
          <a href="#" class="text-blue-600 hover:text-blue-700 font-medium">
            Contato suporte
          </a>
        </div>
      </div>

      <!-- Footer -->
      <div class="mt-8 text-center text-sm text-gray-500">
        <p>&copy; 2025 MANGE_TECH. Todos os direitos reservados.</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { Lock, Eye, EyeOff, AlertCircle, CheckCircle } from 'lucide-vue-next'
import AOS from 'aos'
import 'aos/dist/aos.css'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const uiStore = useUiStore()

const credentials = ref({
  email: '',
  password: ''
})

const loading = ref(false)
const showPassword = ref(false)
const rememberMe = ref(false)
const emailError = ref('')
const errorMessage = ref('')
const buttonState = ref<'idle' | 'success'>('idle')
const rippleEffect = ref(false)

const isFormValid = computed(() => {
  return credentials.value.email && 
         credentials.value.password && 
         !emailError.value
})

const validateEmail = () => {
  if (!credentials.value.email) {
    emailError.value = ''
    return
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  if (!emailRegex.test(credentials.value.email)) {
    emailError.value = 'Por favor, insira um email válido'
  } else {
    emailError.value = ''
  }
}

const handleLogin = async () => {
  if (!isFormValid.value) return

  loading.value = true
  errorMessage.value = ''
  rippleEffect.value = true

  setTimeout(() => {
    rippleEffect.value = false
  }, 500)

  try {
    await authStore.login(credentials.value.email, credentials.value.password)

    // Success state
    buttonState.value = 'success'
    uiStore.showToast('success', 'Login realizado com sucesso!')

    // Redirect after success animation
    setTimeout(() => {
      const redirect = route.query.redirect as string || '/'
      router.push(redirect)
    }, 1000)

  } catch (error: any) {
    console.error('Erro no login:', error)
    
    // Determine error message
    if (error.response?.status === 401) {
      errorMessage.value = 'Email ou senha incorretos. Verifique suas credenciais e tente novamente.'
    } else if (error.response?.status === 400) {
      errorMessage.value = error.response.data?.message || 'Dados inválidos. Verifique os campos e tente novamente.'
    } else if (error.message === 'Network Error') {
      errorMessage.value = 'Erro de conexão. Verifique sua internet e tente novamente.'
    } else {
      errorMessage.value = error.response?.data?.message || 'Erro ao fazer login. Tente novamente.'
    }

    uiStore.showToast('error', 'Erro ao fazer login')
    buttonState.value = 'idle'
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  AOS.init({
    duration: 600,
    easing: 'ease-out',
    once: true
  })

  // Check if user is already authenticated
  if (authStore.isAuthenticated) {
    router.push('/')
  }
})
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

/* Ripple effect animation */
@keyframes ping {
  75%, 100% {
    transform: scale(2);
    opacity: 0;
  }
}

.animate-ping {
  animation: ping 1s cubic-bezier(0, 0, 0.2, 1) infinite;
}

/* Button active scale effect */
button:active {
  transform: scale(0.98);
}

/* Input focus effect */
input:focus {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

/* Smooth transitions */
* {
  transition: all 0.2s ease;
}
</style>