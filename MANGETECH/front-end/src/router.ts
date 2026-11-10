// src/router.ts
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'

declare module 'vue-router' {
  interface RouteMeta {
    requiresAuth?: boolean
    requiresStaff?: boolean
    title?: string
  }
}

const router = createRouter({
  history: createWebHistory(),
  scrollBehavior: () => ({ top: 0 }),
  routes: [
    { path: '/login', name: 'Login', component: () => import('@/views/LoginView.vue'), meta: { title: 'Entrar' } },
    { path: '/register', name: 'Register', component: () => import('@/views/RegisterView.vue'), meta: { title: 'Cadastro' } },
    {
      path: '/forgot-password',
      name: 'ForgotPassword',
      component: () => import('@/views/ForgotPasswordView.vue'),
      meta: { title: 'Recuperar senha' },
    },
    {
      path: '/',
      component: () => import('@/components/Layout.vue'),
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'Dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { requiresAuth: true, requiresStaff: true, title: 'Dashboard' },
        },
        { path: 'tasks', name: 'Tasks', component: () => import('@/views/TaskView.vue'), meta: { requiresAuth: true, title: 'Chamados' } },
        {
          path: 'tasks/create',
          name: 'CreateTask',
          component: () => import('@/views/CreateTaskView.vue'),
          meta: { requiresAuth: true, title: 'Novo chamado' },
        },
        {
          path: 'tasks/:id/edit',
          name: 'EditTask',
          component: () => import('@/views/CreateTaskView.vue'),
          meta: { requiresAuth: true, title: 'Editar chamado' },
        },
        {
          path: 'tasks/:id',
          name: 'TaskDetail',
          component: () => import('@/views/TaskDetailView.vue'),
          meta: { requiresAuth: true, title: 'Chamado' },
        },
        { path: 'assets', name: 'Assets', component: () => import('@/views/AssetsView.vue'), meta: { requiresAuth: true, title: 'Ativos' } },
        {
          path: 'assets/create',
          name: 'CreateAsset',
          component: () => import('@/views/CreateAssetView.vue'),
          meta: { requiresAuth: true, requiresStaff: true, title: 'Novo ativo' },
        },
        {
          path: 'assets/:id',
          name: 'AssetDetail',
          component: () => import('@/views/AssetDetailView.vue'),
          meta: { requiresAuth: true, title: 'Ativo' },
        },
        {
          path: 'users',
          name: 'Users',
          component: () => import('@/views/UsersView.vue'),
          meta: { requiresAuth: true, requiresStaff: true, title: 'Usuários' },
        },
        {
          path: 'users/:id',
          name: 'UserDetail',
          component: () => import('@/views/UserDetailView.vue'),
          meta: { requiresAuth: true, requiresStaff: true, title: 'Usuário' },
        },
        { path: 'profile', name: 'Profile', component: () => import('@/views/ProfileView.vue'), meta: { requiresAuth: true, title: 'Meu perfil' } },
      ],
    },
    { path: '/:pathMatch(.*)*', name: 'NotFound', component: () => import('@/views/NotFoundView.vue'), meta: { title: 'Página não encontrada' } },
  ],
})

router.beforeEach(async (to) => {
  const authStore = useAuthStore()
  const uiStore = useUiStore()
  const precisaLogin = to.matched.some((r) => r.meta.requiresAuth)

  if (precisaLogin && !authStore.isAuthenticated) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }

  // Depois de recarregar a página o token existe mas o usuário pode não ter
  // sido lido ainda: espera antes de decidir o que é de staff.
  if (authStore.isAuthenticated) {
    await authStore.ensureUser()
    if (!authStore.isAuthenticated) {
      return { path: '/login', query: { redirect: to.fullPath } }
    }
  }

  const home = authStore.isAdmin ? '/' : '/tasks'

  if ((to.name === 'Login' || to.name === 'Register') && authStore.isAuthenticated) {
    return home
  }

  if (to.matched.some((r) => r.meta.requiresStaff) && authStore.user && !authStore.isAdmin) {
    // A raiz é o dashboard; quem não é staff começa pelos chamados, sem aviso.
    if (to.name !== 'Dashboard') {
      uiStore.showToast('error', 'Esta área é restrita aos administradores.')
    }
    return '/tasks'
  }

  return true
})

router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} · MangeTech` : 'MangeTech'
})

export default router
