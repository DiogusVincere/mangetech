// src/router/index.ts - CORRIGIDO COM REDIRECIONAMENTO INTELIGENTE
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Public Routes
    {
      path: '/login',
      name: 'Login',
      component: () => import('@/views/LoginView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/register',
      name: 'Register',
      component: () => import('@/views/RegisterView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/forgot-password',
      name: 'ForgotPassword',
      component: () => import('@/views/ForgotPasswordView.vue'),
      meta: { requiresAuth: false },
    },
    
    // Protected Routes
    {
      path: '/',
      component: () => import('@/components/Layout.vue'),
      meta: { requiresAuth: true },
      children: [
        // Dashboard - APENAS STAFF
        {
          path: '/',
          name: 'Dashboard',
          component: () => import('@/views/DashboardView.vue'),
          meta: { 
            requiresAuth: true,
            requiresStaff: true 
          },
        },
        
        // Tasks - TODOS USUÁRIOS
        {
          path: 'tasks',
          name: 'Tasks',
          component: () => import('@/views/TaskView.vue'),
          meta: { requiresAuth: true },
        },
        {
          path: 'tasks/create', 
          name: 'CreateTask',
          component: () => import('@/views/CreateTaskView.vue'),
          meta: { requiresAuth: true },
        },
        {
          path: 'tasks/:id',
          name: 'TaskDetail',
          component: () => import('@/views/TaskDetailView.vue'),
          meta: { requiresAuth: true },
        },
        
        // Assets - TODOS USUÁRIOS
        {
          path: 'assets',
          name: 'Assets',
          component: () => import('@/views/AssetsView.vue'),
          meta: { requiresAuth: true },
        },
        {
          path: 'assets/create', 
          name: 'CreateAsset',
          component: () => import('@/views/CreateAssetView.vue'),
          meta: { 
            requiresAuth: true,
            requiresStaff: true
          },
        },
        {
          path: 'assets/:id',
          name: 'AssetDetail',
          component: () => import('@/views/AssetDetailView.vue'),
          meta: { requiresAuth: true },
        },
        
        // Users - APENAS STAFF
        {
          path: 'users',
          name: 'Users',
          component: () => import('@/views/UsersView.vue'),
          meta: { 
            requiresAuth: true,
            requiresStaff: true
          },
        },
        {
          path: 'users/:id',
          name: 'UserDetail',
          component: () => import('@/views/UserDetailView.vue'),
          meta: { 
            requiresAuth: true,
            requiresStaff: true
          },
        },
        
        // Profile - TODOS USUÁRIOS
        {
          path: 'profile',
          name: 'Profile',
          component: () => import('@/views/ProfileView.vue'),
          meta: { requiresAuth: true },
        },
      ],
    },
    
    // 404 - Not Found
    {
      path: '/:pathMatch(.*)*',
      name: 'NotFound',
      component: () => import('@/views/NotFoundView.vue'),
    },
  ],
})

// GUARD DE AUTENTICAÇÃO COM TRY-CATCH E REDIRECIONAMENTO INTELIGENTE
router.beforeEach(async (to, from, next) => {
  try {
    const authStore = useAuthStore()
    const uiStore = useUiStore()

    console.log('Router Guard - Indo para:', to.path)
    console.log('Autenticado:', authStore.isAuthenticated)
    console.log('É Staff:', authStore.user?.is_staff)

    // Se a rota requer autenticação e o usuário não está autenticado
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
      console.log('Rota protegida, redirecionando para login')
      uiStore.showToast('warning', 'Você precisa fazer login para acessar esta página')
      next({
        path: '/login',
        query: { redirect: to.fullPath }
      })
      return
    }

    // Se o usuário está autenticado e tenta acessar login/register
    if ((to.path === '/login' || to.path === '/register') && authStore.isAuthenticated) {
      console.log('Já autenticado, redirecionando para home apropriado')
      // Redireciona staff para dashboard, usuários normais para tasks
      next(authStore.user?.is_staff ? '/' : '/tasks')
      return
    }

    // REDIRECIONAMENTO INTELIGENTE NA RAIZ
    // Se o usuário acessa "/" e não é staff, redireciona para /tasks
    if (to.path === '/' && authStore.isAuthenticated && !authStore.user?.is_staff) {
      console.log('Usuário não-staff tentando acessar dashboard, redirecionando para tasks')
      next('/tasks')
      return
    }

    // VERIFICAÇÃO DE PERMISSÃO STAFF PARA OUTRAS ROTAS
    if (to.meta.requiresStaff && authStore.isAuthenticated) {
      if (!authStore.user?.is_staff) {
        console.log('Acesso negado - Requer permissão de staff')
        uiStore.showToast('error', 'Acesso negado. Esta área é restrita para administradores.')
        
        // Redireciona para tasks ao invés de bloquear
        next('/tasks')
        return
      }
    }

    console.log('Navegação permitida')
    next()
  } catch (error) {
    console.error('Erro no router guard:', error)
    // Em caso de erro, redireciona para tasks como fallback seguro
    next('/tasks')
  }
})

// GUARD APÓS NAVEGAÇÃO
router.afterEach((to) => {
  const titles: Record<string, string> = {
    'Dashboard': 'Dashboard - Sistema de Chamados',
    'Tasks': 'Chamados - Sistema de Chamados',
    'CreateTask': 'Novo Chamado - Sistema de Chamados',
    'TaskDetail': 'Detalhes do Chamado - Sistema de Chamados',
    'Assets': 'Ativos - Sistema de Chamados',
    'CreateAsset': 'Novo Ativo - Sistema de Chamados',
    'AssetDetail': 'Detalhes do Ativo - Sistema de Chamados',
    'Users': 'Usuários - Sistema de Chamados',
    'UserDetail': 'Detalhes do Usuário - Sistema de Chamados',
    'Profile': 'Meu Perfil - Sistema de Chamados',
    'Login': 'Login - Sistema de Chamados',
    'Register': 'Cadastro - Sistema de Chamados',
    'ForgotPassword': 'Recuperar Senha - Sistema de Chamados',
  }
  
  document.title = titles[to.name as string] || 'Sistema de Chamados'
})

export default router