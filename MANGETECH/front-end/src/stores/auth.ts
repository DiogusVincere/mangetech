// src/stores/auth.ts
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api'
import { TOKEN_KEY, USER_KEY } from '@/api/client'
import type { User } from '@/types'

function readUser(): User | null {
  try {
    const raw = localStorage.getItem(USER_KEY)
    return raw ? (JSON.parse(raw) as User) : null
  } catch {
    return null
  }
}

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem(TOKEN_KEY))
  // O usuário fica salvo junto com o token: sem isso, ao recarregar a página
  // o guard das rotas não sabia se a pessoa era staff e mandava para /tasks.
  const user = ref<User | null>(token.value ? readUser() : null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.is_staff === true)

  function setSession(newToken: string, newUser: User) {
    token.value = newToken
    user.value = newUser
    localStorage.setItem(TOKEN_KEY, newToken)
    localStorage.setItem(USER_KEY, JSON.stringify(newUser))
  }

  function setUser(newUser: User) {
    user.value = newUser
    localStorage.setItem(USER_KEY, JSON.stringify(newUser))
  }

  function setToken(newToken: string) {
    token.value = newToken
    localStorage.setItem(TOKEN_KEY, newToken)
  }

  function clearSession() {
    user.value = null
    token.value = null
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
  }

  async function login(email: string, password: string) {
    loading.value = true
    try {
      const response = await authApi.login(email.trim(), password)
      setSession(response.token, response.user)
    } finally {
      loading.value = false
    }
  }

  async function register(name: string, email: string, password: string) {
    loading.value = true
    try {
      const response = await authApi.register(name.trim(), email.trim(), password)
      setSession(response.token, response.user)
    } finally {
      loading.value = false
    }
  }

  async function logout() {
    try {
      if (token.value) await authApi.logout()
    } catch {
      // sem rede ou token já inválido: sai do mesmo jeito
    } finally {
      clearSession()
    }
  }

  /** Atualiza os dados do usuário logado a partir da API. */
  async function fetchUser() {
    if (!token.value) return null
    try {
      setUser(await authApi.getMe())
    } catch (error: any) {
      if (error?.response?.status === 401) clearSession()
    }
    return user.value
  }

  /** Garante que `user` está carregado (usado pelo guard das rotas). */
  async function ensureUser() {
    if (token.value && !user.value) await fetchUser()
    return user.value
  }

  return {
    user,
    token,
    loading,
    isAuthenticated,
    isAdmin,
    login,
    register,
    logout,
    fetchUser,
    ensureUser,
    setUser,
    setToken,
    clearSession,
  }
})
