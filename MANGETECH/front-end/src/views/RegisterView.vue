<!-- src/views/RegisterView.vue - APRIMORADO -->
<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4 py-12">
    <div class="w-full max-w-md">
      <!-- Logo -->
      <div class="flex justify-center mb-8">
        <div class="bg-gradient-to-br from-blue-600 to-indigo-700 text-white p-4 rounded-2xl w-20 h-20 flex items-center justify-center shadow-xl transform hover:scale-105 transition">
          <UserPlus class="w-10 h-10" />
        </div>
      </div>

      <!-- Card -->
      <div class="bg-white rounded-2xl shadow-2xl p-8">
        <h1 class="text-3xl font-bold text-gray-800 text-center mb-2">Criar Conta</h1>
        <p class="text-gray-500 text-center mb-8">Preencha seus dados para começar</p>

        <!-- Form -->
        <form @submit.prevent="handleRegister" class="space-y-5">
          <!-- Nome Completo -->
          <div>
            <label for="name" class="block text-gray-700 text-sm font-semibold mb-2">
              Nome Completo <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                v-model="formData.name"
                type="text"
                id="name"
                required
                minlength="3"
                maxlength="150"
                :class="[
                  'w-full px-4 py-3 pl-11 border rounded-lg focus:outline-none focus:ring-2 transition',
                  errors.name ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                ]"
                placeholder="João Silva"
                @blur="validateField('name')"
                @input="clearError('name')"
              />
              <User class="absolute left-3 top-3.5 text-gray-400" :size="20" />
            </div>
            <p v-if="errors.name" class="text-red-500 text-xs mt-1 flex items-center gap-1">
              <AlertCircle :size="14" />
              {{ errors.name }}
            </p>
            <p v-else class="text-gray-400 text-xs mt-1">
              Mínimo 3 caracteres
            </p>
          </div>

          <!-- Email -->
          <div>
            <label for="email" class="block text-gray-700 text-sm font-semibold mb-2">
              Email <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                v-model="formData.email"
                type="email"
                id="email"
                required
                :class="[
                  'w-full px-4 py-3 pl-11 border rounded-lg focus:outline-none focus:ring-2 transition',
                  errors.email ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                ]"
                placeholder="seu@email.com"
                @blur="validateField('email')"
                @input="clearError('email')"
              />
              <Mail class="absolute left-3 top-3.5 text-gray-400" :size="20" />
              
              <!-- Email Valid Icon -->
              <CheckCircle 
                v-if="formData.email && !errors.email && isValidEmail(formData.email)"
                class="absolute right-3 top-3.5 text-green-500" 
                :size="20" 
              />
            </div>
            <p v-if="errors.email" class="text-red-500 text-xs mt-1 flex items-center gap-1">
              <AlertCircle :size="14" />
              {{ errors.email }}
            </p>
          </div>

          <!-- Senha -->
          <div>
            <label for="password" class="block text-gray-700 text-sm font-semibold mb-2">
              Senha <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                v-model="formData.password"
                :type="showPassword ? 'text' : 'password'"
                id="password"
                required
                minlength="6"
                :class="[
                  'w-full px-4 py-3 pl-11 pr-11 border rounded-lg focus:outline-none focus:ring-2 transition',
                  errors.password ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                ]"
                placeholder="Mínimo 6 caracteres"
                @blur="validateField('password')"
                @input="clearError('password')"
              />
              <Lock class="absolute left-3 top-3.5 text-gray-400" :size="20" />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-3 text-gray-400 hover:text-gray-600 transition"
                tabindex="-1"
              >
                <Eye v-if="showPassword" :size="20" />
                <EyeOff v-else :size="20" />
              </button>
            </div>
            
            <!-- Password Strength Indicator -->
            <div v-if="formData.password" class="mt-2">
              <div class="flex gap-1 mb-1">
                <div 
                  v-for="i in 4" 
                  :key="i"
                  :class="[
                    'h-1 flex-1 rounded-full transition-all',
                    i <= passwordStrength.level ? passwordStrength.color : 'bg-gray-200'
                  ]"
                ></div>
              </div>
              <p :class="['text-xs', passwordStrength.textColor]">
                {{ passwordStrength.label }}
              </p>
            </div>
            
            <p v-if="errors.password" class="text-red-500 text-xs mt-1 flex items-center gap-1">
              <AlertCircle :size="14" />
              {{ errors.password }}
            </p>
          </div>

          <!-- Confirmar Senha -->
          <div>
            <label for="confirmPassword" class="block text-gray-700 text-sm font-semibold mb-2">
              Confirmar Senha <span class="text-red-500">*</span>
            </label>
            <div class="relative">
              <input
                v-model="formData.confirmPassword"
                :type="showPassword ? 'text' : 'password'"
                id="confirmPassword"
                required
                :class="[
                  'w-full px-4 py-3 pl-11 pr-11 border rounded-lg focus:outline-none focus:ring-2 transition',
                  errors.confirmPassword ? 'border-red-500 focus:ring-red-500' : 'border-gray-300 focus:ring-blue-500'
                ]"
                placeholder="Confirme sua senha"
                @blur="validateField('confirmPassword')"
                @input="clearError('confirmPassword')"
              />
              <Lock class="absolute left-3 top-3.5 text-gray-400" :size="20" />
              
              <!-- Passwords Match Icon -->
              <CheckCircle 
                v-if="formData.confirmPassword && formData.password === formData.confirmPassword"
                class="absolute right-3 top-3.5 text-green-500" 
                :size="20" 
              />
              <XCircle 
                v-else-if="formData.confirmPassword && formData.password !== formData.confirmPassword"
                class="absolute right-3 top-3.5 text-red-500" 
                :size="20" 
              />
            </div>
            <p v-if="errors.confirmPassword" class="text-red-500 text-xs mt-1 flex items-center gap-1">
              <AlertCircle :size="14" />
              {{ errors.confirmPassword }}
            </p>
          </div>

          <!-- Termos -->
          <div class="flex items-start pt-2">
            <input
              v-model="acceptTerms"
              id="terms"
              type="checkbox"
              required
              class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded mt-1 cursor-pointer"
            />
            <label for="terms" class="ml-3 block text-sm text-gray-700 cursor-pointer select-none">
              Concordo com os 
              <a href="#" class="text-blue-600 hover:text-blue-700 font-semibold underline">Termos de Uso</a> e 
              <a href="#" class="text-blue-600 hover:text-blue-700 font-semibold underline">Política de Privacidade</a>
            </label>
          </div>

          <!-- Error Message -->
          <div 
            v-if="errorMessage" 
            class="p-4 bg-red-50 border-l-4 border-red-500 rounded-r-lg flex items-start gap-3 animate-shake"
          >
            <AlertCircle class="text-red-600 flex-shrink-0 mt-0.5" :size="20" />
            <div>
              <p class="text-sm font-semibold text-red-800">Erro ao criar conta</p>
              <p class="text-sm text-red-700">{{ errorMessage }}</p>
            </div>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="loading || !isFormValid"
            class="w-full py-3.5 bg-gradient-to-r from-blue-600 to-indigo-700 text-white rounded-lg hover:from-blue-700 hover:to-indigo-800 disabled:opacity-50 disabled:cursor-not-allowed transition-all font-semibold shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 flex items-center justify-center gap-2"
          >
            <div v-if="loading" class="flex items-center gap-2">
              <div class="loader"></div>
              <span>Criando conta...</span>
            </div>
            <div v-else class="flex items-center gap-2">
              <UserPlus :size="20" />
              <span>Criar Conta</span>
            </div>
          </button>
        </form>

        <!-- Login Link -->
        <div class="mt-8 text-center">
          <p class="text-sm text-gray-600">
            Já tem uma conta? 
            <router-link 
              to="/login" 
              class="text-blue-600 hover:text-blue-700 font-semibold ml-1 hover:underline"
            >
              Fazer login
            </router-link>
          </p>
        </div>

        <!-- Divider -->
        <div class="mt-6 pt-6 border-t border-gray-200">
          <p class="text-xs text-center text-gray-500">
            Ao criar uma conta, você concorda com nossos termos e políticas
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { isValidEmail } from '@/utils/validators'
import { 
  UserPlus, 
  Eye, 
  EyeOff, 
  User, 
  Mail, 
  Lock,
  AlertCircle,
  CheckCircle,
  XCircle
} from 'lucide-vue-next'

const router = useRouter()
const authStore = useAuthStore()
const uiStore = useUiStore()

const formData = ref({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const errors = ref<Record<string, string>>({})
const loading = ref(false)
const showPassword = ref(false)
const acceptTerms = ref(false)
const errorMessage = ref('')

// TIPO PARA STRENGTH
interface PasswordStrength {
  level: number
  label: string
  color: string
  textColor: string
}

// INDICADOR DE FORÇA DA SENHA (COM TIPO EXPLÍCITO)
const passwordStrength = computed<PasswordStrength>(() => {
  const password = formData.value.password
  
  const defaultStrength: PasswordStrength = { 
    level: 0, 
    label: 'Muito fraca', 
    color: 'bg-red-500', 
    textColor: 'text-red-600' 
  }
  
  if (!password) return defaultStrength
  
  let strength = 0
  
  // Calcular força
  if (password.length >= 6) strength++
  if (password.length >= 10) strength++
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) strength++
  if (/[0-9]/.test(password)) strength++
  if (/[^a-zA-Z0-9]/.test(password)) strength++
  
  const levels: Record<number, PasswordStrength> = {
    0: { level: 0, label: 'Muito fraca', color: 'bg-red-500', textColor: 'text-red-600' },
    1: { level: 1, label: 'Fraca', color: 'bg-orange-500', textColor: 'text-orange-600' },
    2: { level: 2, label: 'Razoável', color: 'bg-yellow-500', textColor: 'text-yellow-600' },
    3: { level: 3, label: 'Boa', color: 'bg-blue-500', textColor: 'text-blue-600' },
    4: { level: 4, label: 'Forte', color: 'bg-green-500', textColor: 'text-green-600' },
    5: { level: 5, label: 'Muito forte', color: 'bg-green-600', textColor: 'text-green-700' }
  }
  
  return levels[strength] ?? defaultStrength
})

// VALIDAÇÃO COMPLETA DO FORMULÁRIO
const isFormValid = computed(() => {
  return formData.value.name.trim().length >= 3 &&
         isValidEmail(formData.value.email) &&
         formData.value.password.length >= 6 &&
         formData.value.password === formData.value.confirmPassword &&
         acceptTerms.value &&
         !errors.value.name &&
         !errors.value.email &&
         !errors.value.password &&
         !errors.value.confirmPassword
})

// VALIDAÇÃO DE CAMPOS INDIVIDUAIS
const validateField = (field: string) => {
  switch (field) {
    case 'name':
      if (!formData.value.name.trim()) {
        errors.value.name = 'Nome é obrigatório'
      } else if (formData.value.name.trim().length < 3) {
        errors.value.name = 'Nome deve ter pelo menos 3 caracteres'
      } else if (formData.value.name.trim().length > 150) {
        errors.value.name = 'Nome muito longo (máx. 150 caracteres)'
      } else if (!/^[a-zA-ZÀ-ÿ\s]+$/.test(formData.value.name)) {
        errors.value.name = 'Nome deve conter apenas letras'
      } else {
        errors.value.name = ''
      }
      break
      
    case 'email':
      if (!formData.value.email) {
        errors.value.email = 'Email é obrigatório'
      } else if (!isValidEmail(formData.value.email)) {
        errors.value.email = 'Email inválido'
      } else {
        errors.value.email = ''
      }
      break
      
    case 'password':
      if (!formData.value.password) {
        errors.value.password = 'Senha é obrigatória'
      } else if (formData.value.password.length < 6) {
        errors.value.password = 'Senha deve ter pelo menos 6 caracteres'
      } else {
        errors.value.password = ''
        if (formData.value.confirmPassword) {
          validateField('confirmPassword')
        }
      }
      break
      
    case 'confirmPassword':
      if (!formData.value.confirmPassword) {
        errors.value.confirmPassword = 'Confirme sua senha'
      } else if (formData.value.password !== formData.value.confirmPassword) {
        errors.value.confirmPassword = 'As senhas não coincidem'
      } else {
        errors.value.confirmPassword = ''
      }
      break
  }
}

// LIMPAR ERRO AO DIGITAR
const clearError = (field: string) => {
  errors.value[field] = ''
  errorMessage.value = ''
}

// REGISTRO COM LOGIN AUTOMÁTICO
const handleRegister = async () => {
  validateField('name')
  validateField('email')
  validateField('password')
  validateField('confirmPassword')
  
  if (!isFormValid.value) {
    uiStore.showToast('error', 'Por favor, corrija os erros no formulário')
    return
  }

  if (!acceptTerms.value) {
    uiStore.showToast('error', 'Você precisa aceitar os termos de uso')
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    console.log('📝 Iniciando registro...')

    await authStore.register(
      formData.value.name.trim(),
      formData.value.email.trim().toLowerCase(),
      formData.value.password
    )

    console.log('Registro bem-sucedido!')
    
    await authStore.fetchUser()
    
    console.log('Usuário autenticado:', authStore.user)

    uiStore.showToast('success', `Bem-vindo(a), ${formData.value.name.split(' ')[0]}!`)
    
    setTimeout(() => {
      if (authStore.user?.is_staff) {
        router.push('/')
      } else {
        router.push('/tasks')
      }
    }, 500)

  } catch (error: any) {
    console.error('❌ Erro no registro:', error)
    
    if (error.response?.status === 400) {
      const errorData = error.response.data
      
      if (errorData.errors?.email) {
        errors.value.email = Array.isArray(errorData.errors.email) 
          ? errorData.errors.email[0] 
          : errorData.errors.email
        errorMessage.value = 'Este email já está cadastrado'
      }
      else if (errorData.errors?.senha) {
        errors.value.password = Array.isArray(errorData.errors.senha)
          ? errorData.errors.senha[0]
          : errorData.errors.senha
        errorMessage.value = 'Senha não atende aos requisitos'
      }
      else if (errorData.errors) {
        const firstError = Object.values(errorData.errors)[0]
        errorMessage.value = Array.isArray(firstError) ? firstError[0] : String(firstError)
      }
      else if (errorData.message) {
        errorMessage.value = errorData.message
      }
      else {
        errorMessage.value = 'Dados inválidos. Verifique e tente novamente.'
      }
    }
    else if (error.code === 'ERR_NETWORK') {
      errorMessage.value = 'Erro de conexão. Verifique sua internet.'
    }
    else {
      errorMessage.value = error.response?.data?.message || 
                          'Erro ao criar conta. Tente novamente.'
    }
    
    uiStore.showToast('error', errorMessage.value)
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

@keyframes shake {
  0%, 100% { transform: translateX(0); }
  10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
  20%, 40%, 60%, 80% { transform: translateX(5px); }
}

.animate-shake {
  animation: shake 0.5s;
}
</style>