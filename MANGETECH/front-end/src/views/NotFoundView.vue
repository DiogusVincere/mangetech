<!-- src/views/NotFoundView.vue -->
<template>
  <div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 px-4">
    <div class="max-w-2xl w-full text-center">
      <!-- Ilustração 404 -->
      <div class="mb-8 relative">
        <div class="text-[200px] font-bold text-blue-600 opacity-10 leading-none select-none">
          404
        </div>
        <div class="absolute inset-0 flex items-center justify-center">
          <div class="bg-white rounded-full p-8 shadow-xl">
            <AlertCircle :size="80" class="text-blue-600" />
          </div>
        </div>
      </div>

      <!-- Conteúdo -->
      <div class="bg-white rounded-2xl shadow-xl p-8 md:p-12">
        <h1 class="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
          Página não encontrada
        </h1>
        <p class="text-lg text-gray-600 mb-8">
          Ops! A página que você está procurando não existe ou foi movida.
        </p>

        <!-- Sugestões -->
        <div class="bg-blue-50 rounded-lg p-6 mb-8 text-left">
          <h3 class="font-semibold text-gray-900 mb-3 flex items-center">
            <HelpCircle :size="20" class="mr-2 text-blue-600" />
            O que você pode fazer?
          </h3>
          <ul class="space-y-2 text-sm text-gray-700">
            <li class="flex items-start">
              <ChevronRight :size="16" class="mr-2 mt-0.5 text-blue-600 flex-shrink-0" />
              <span>Verifique se o endereço foi digitado corretamente</span>
            </li>
            <li class="flex items-start">
              <ChevronRight :size="16" class="mr-2 mt-0.5 text-blue-600 flex-shrink-0" />
              <span>Volte para a página inicial e tente novamente</span>
            </li>
            <li class="flex items-start">
              <ChevronRight :size="16" class="mr-2 mt-0.5 text-blue-600 flex-shrink-0" />
              <span>Use o menu de navegação para encontrar o que procura</span>
            </li>
          </ul>
        </div>

        <!-- Botões de Ação -->
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <button
            @click="$router.go(-1)"
            class="inline-flex items-center justify-center px-6 py-3 border-2 border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition"
          >
            <ArrowLeft :size="20" class="mr-2" />
            Voltar
          </button>
          
          <router-link
            to="/"
            class="inline-flex items-center justify-center px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition shadow-sm"
          >
            <Home :size="20" class="mr-2" />
            Ir para Início
          </router-link>
        </div>

        <!-- Links Rápidos -->
        <div class="mt-8 pt-8 border-t border-gray-200">
          <p class="text-sm text-gray-500 mb-4">Acesso rápido:</p>
          <div class="flex flex-wrap justify-center gap-4">
            <router-link
              to="/tasks"
              class="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center"
            >
              <ClipboardList :size="16" class="mr-1" />
              Chamados
            </router-link>
            <router-link
              to="/assets"
              class="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center"
            >
              <Package :size="16" class="mr-1" />
              Ativos
            </router-link>
            <router-link
              to="/profile"
              class="text-sm text-blue-600 hover:text-blue-700 font-medium flex items-center"
            >
              <User :size="16" class="mr-1" />
              Meu Perfil
            </router-link>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <p class="mt-8 text-sm text-gray-500">
        Precisa de ajuda? Entre em contato com o suporte
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { 
  AlertCircle, 
  HelpCircle, 
  ChevronRight, 
  ArrowLeft, 
  Home,
  ClipboardList,
  Package,
  User
} from 'lucide-vue-next'
</script>