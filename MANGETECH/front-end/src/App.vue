<template>
  <router-view />
  <Toast />
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import Toast from '@/components/Toast.vue'

const authStore = useAuthStore()

// Atualiza nome/permissões do usuário salvo (podem ter mudado em outra sessão).
onMounted(() => {
  if (authStore.isAuthenticated) authStore.fetchUser()
})
</script>
