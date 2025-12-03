<!-- src/views/DashboardView.vue -->
<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Dashboard Gerencial</h1>
        <p class="text-sm text-gray-500 mt-1">Visão geral dos chamados e indicadores</p>
      </div>

      <div class="flex items-center gap-3">
        <select
          v-model="selectedPeriod"
          @change="loadDashboard"
          class="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
        >
          <option value="7">Últimos 7 dias</option>
          <option value="30">Últimos 30 dias</option>
          <option value="90">Últimos 90 dias</option>
        </select>

        <button
          @click="exportPDF"
          :disabled="!dashboardData || loading"
          class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Download :size="18" />
          PDF
        </button>

        <button
          @click="exportCSV"
          :disabled="!dashboardData || loading"
          class="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Download :size="18" />
          CSV
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4 font-medium">Carregando indicadores...</p>
    </div>

    <!-- Dashboard Content -->
    <template v-else-if="dashboardData">
      <!-- KPI Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <!-- Total Chamados -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm text-gray-500 font-medium">Total Chamados</p>
              <h3 class="text-3xl font-bold text-gray-900 mt-2">
                {{ dashboardData.kpis.total_chamados || 0 }}
              </h3>
              <p class="text-xs text-gray-500 mt-1">Últimos {{ selectedPeriod }} dias</p>
            </div>
            <div class="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <ClipboardList :size="24" class="text-blue-600" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <TrendingUp :size="16" class="text-green-600 mr-1" />
            <span class="text-green-600 font-medium">12.5%</span>
            <span class="text-gray-500 ml-2">vs período anterior</span>
          </div>
        </div>

        <!-- SLA Compliance -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm text-gray-500 font-medium">SLA Compliance</p>
              <h3 class="text-3xl font-bold text-gray-900 mt-2">{{ slaPercentage }}%</h3>
              <p class="text-xs text-gray-500 mt-1">Meta: 90%</p>
            </div>
            <div class="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <CheckCircle :size="24" class="text-green-600" />
            </div>
          </div>
          <div class="mt-4 w-full bg-gray-200 rounded-full h-2">
            <div 
              class="bg-green-600 h-2 rounded-full transition-all duration-500" 
              :style="{ width: `${slaPercentage}%` }"
            ></div>
          </div>
        </div>

        <!-- Tempo Médio -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm text-gray-500 font-medium">Tempo Médio</p>
              <h3 class="text-3xl font-bold text-gray-900 mt-2">
                {{ dashboardData.kpis.tempo_medio || '4.2h' }}
              </h3>
              <p class="text-xs text-gray-500 mt-1">Média de resolução</p>
            </div>
            <div class="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center">
              <Clock :size="24" class="text-purple-600" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <TrendingDown :size="16" class="text-red-600 mr-1" />
            <span class="text-red-600 font-medium">8.7%</span>
            <span class="text-gray-500 ml-2">vs período anterior</span>
          </div>
        </div>

        <!-- Críticos Abertos -->
        <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm text-gray-500 font-medium">Críticos Abertos</p>
              <h3 class="text-3xl font-bold text-gray-900 mt-2">
                {{ dashboardData.kpis.criticos_abertos || 0 }}
              </h3>
              <p class="text-xs text-gray-500 mt-1">Prioridade alta/crítico</p>
            </div>
            <div class="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <AlertCircle :size="24" class="text-red-600" />
            </div>
          </div>
          <div class="mt-4 flex items-center text-sm">
            <TrendingUp :size="16" class="text-red-600 mr-1" />
            <span class="text-red-600 font-medium">28.6%</span>
            <span class="text-gray-500 ml-2">vs período anterior</span>
          </div>
        </div>
      </div>

      <!-- Charts Row 1 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Chamados por Status -->
        <div ref="statusChartContainer" class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Chamados por Status</h2>
            <span class="text-sm text-gray-500">Últimos {{ selectedPeriod }} dias</span>
          </div>
          <div class="h-64 relative">
            <canvas ref="statusChartRef"></canvas>
          </div>
          <div class="mt-4 grid grid-cols-2 gap-2 text-xs">
            <div v-for="(value, key) in dashboardData.por_status" :key="key" class="flex items-center">
              <div :class="['w-3 h-3 rounded-full mr-2', getStatusColor(key)]"></div>
              <span>{{ key }}: {{ value }}</span>
            </div>
          </div>
        </div>

        <!-- SLA Compliance Chart -->
        <div ref="slaChartContainer" class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-gray-900">SLA Compliance %</h2>
            <span class="text-sm text-gray-500">Últimos {{ selectedPeriod }} dias</span>
          </div>
          <div class="h-64 flex items-center justify-center">
            <div class="text-center">
              <div class="relative inline-flex items-center justify-center">
                <svg class="w-48 h-48">
                  <circle
                    class="text-gray-200"
                    stroke-width="12"
                    stroke="currentColor"
                    fill="transparent"
                    r="70"
                    cx="96"
                    cy="96"
                  />
                  <circle
                    :class="[
                      'transition-all duration-1000',
                      slaPercentage >= 90 ? 'text-green-600' : slaPercentage >= 70 ? 'text-yellow-600' : 'text-red-600'
                    ]"
                    stroke-width="12"
                    :stroke-dasharray="circumference"
                    :stroke-dashoffset="dashOffset"
                    stroke-linecap="round"
                    stroke="currentColor"
                    fill="transparent"
                    r="70"
                    cx="96"
                    cy="96"
                    transform="rotate(-90 96 96)"
                  />
                </svg>
                <div class="absolute inset-0 flex items-center justify-center">
                  <span 
                    :class="[
                      'text-5xl font-bold',
                      slaPercentage >= 90 ? 'text-green-600' : slaPercentage >= 70 ? 'text-yellow-600' : 'text-red-600'
                    ]"
                  >
                    {{ slaPercentage }}%
                  </span>
                </div>
              </div>
              <p class="text-gray-600 mt-4">Conformidade</p>
            </div>
          </div>
          <div class="mt-4 flex justify-center gap-6 text-sm">
            <div class="flex items-center">
              <div class="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span>Dentro do SLA</span>
            </div>
            <div class="flex items-center">
              <div class="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
              <span>Fora do SLA</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Charts Row 2 -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Chamados por Urgência -->
        <div ref="urgencyChartContainer" class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Chamados por Urgência</h2>
            <span class="text-sm text-gray-500">Últimos {{ selectedPeriod }} dias</span>
          </div>
          <div class="h-64 relative">
            <canvas ref="urgencyChartRef"></canvas>
          </div>
        </div>

        <!-- Tempo para Resolver -->
        <div ref="timeChartContainer" class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Tempo para Resolver</h2>
            <span class="text-sm text-gray-500">Últimos {{ selectedPeriod }} dias</span>
          </div>
          <div class="flex gap-6 mb-4">
            <div>
              <p class="text-sm text-gray-500">Média</p>
              <p class="text-2xl font-bold text-gray-900">{{ dashboardData.kpis.tempo_medio || '4.2h' }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Mediana</p>
              <p class="text-2xl font-bold text-gray-900">3.5h</p>
            </div>
          </div>
          <div class="h-40 relative">
            <canvas ref="timeChartRef"></canvas>
          </div>
        </div>
      </div>

      <!-- Chamados Críticos -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold text-gray-900">Chamados Críticos Abertos</h2>
        </div>

        <div v-if="dashboardData.criticos && dashboardData.criticos.length > 0" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Responsável</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ambiente</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Urgência</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Ações</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="task in dashboardData.criticos.slice(0, 5)" :key="task.id" class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  #{{ task.id }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ task.titulo }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ task.solicitante_nome || 'Não atribuído' }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ task.ambiente }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {{ formatDate(task.data_criacao) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span :class="['px-2 py-1 text-xs font-semibold rounded-full', getPriorityClass(task.urgencia)]">
                    {{ task.urgencia }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                  <router-link
                    :to="`/tasks/${task.id}`"
                    class="text-blue-600 hover:text-blue-900 font-medium"
                  >
                    Ver detalhes
                  </router-link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-else class="px-6 py-12 text-center">
          <CheckCircle :size="48" class="mx-auto text-green-500 mb-4" />
          <p class="text-gray-500">Nenhum chamado crítico no momento</p>
        </div>
      </div>
    </template>

    <!-- Error State -->
    <div v-else class="bg-white rounded-xl border border-gray-200 shadow-sm">
      <div class="text-center py-16 px-4">
        <AlertCircle :size="48" class="mx-auto text-red-500 mb-4" />
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Erro ao carregar dashboard</h3>
        <p class="text-gray-500 mb-6">Não foi possível carregar os dados do dashboard</p>
        <button
          @click="loadDashboard"
          class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          Tentar novamente
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, computed, onBeforeUnmount } from 'vue'
import { dashboardApi } from '@/api'
import { useUiStore } from '@/stores/ui'
import {
  ClipboardList,
  CheckCircle,
  Clock,
  AlertCircle,
  TrendingUp,
  TrendingDown,
  Download
} from 'lucide-vue-next'
import { Chart, registerables } from 'chart.js'
import { format } from 'date-fns'
import type { DashboardData } from '@/types'

Chart.register(...registerables)

const uiStore = useUiStore()
const loading = ref(false)
const dashboardData = ref<DashboardData | null>(null)
const selectedPeriod = ref('30')

const statusChartRef = ref<HTMLCanvasElement>()
const urgencyChartRef = ref<HTMLCanvasElement>()
const timeChartRef = ref<HTMLCanvasElement>()

const statusChartContainer = ref<HTMLDivElement>()
const slaChartContainer = ref<HTMLDivElement>()
const urgencyChartContainer = ref<HTMLDivElement>()
const timeChartContainer = ref<HTMLDivElement>()

let statusChart: Chart | null = null
let urgencyChart: Chart | null = null
let timeChart: Chart | null = null

// SLA Percentage Calculation
const slaPercentage = computed(() => {
  if (!dashboardData.value) return 0
  const total = dashboardData.value.kpis.total_chamados || 0
  const concluidos = dashboardData.value.kpis.concluido || 0
  return total > 0 ? Math.round((concluidos / total) * 100) : 0
})

// SLA Circle Progress
const circumference = computed(() => 2 * Math.PI * 70)
const dashOffset = computed(() => {
  return circumference.value - (slaPercentage.value / 100) * circumference.value
})

const getStatusColor = (status: string) => {
  const colors: Record<string, string> = {
    'aberto': 'bg-blue-500',
    'em_andamento': 'bg-yellow-500',
    'realizado': 'bg-cyan-500',
    'concluido': 'bg-green-500',
    'cancelado': 'bg-red-500',
  }
  return colors[status.toLowerCase().replace(/ /g, '_')] || 'bg-gray-500'
}

const getPriorityClass = (priority: string) => {
  const classes: Record<string, string> = {
    'Crítico': 'bg-red-100 text-red-800',
    'Alta': 'bg-orange-100 text-orange-800',
    'Média': 'bg-yellow-100 text-yellow-800',
    'Baixa': 'bg-green-100 text-green-800',
  }
  return classes[priority] || 'bg-gray-100 text-gray-800'
}

const formatDate = (date: string) => {
  try {
    return format(new Date(date), 'dd/MM/yyyy')
  } catch {
    return date
  }
}

const loadDashboard = async () => {
  loading.value = true
  try {
    dashboardData.value = await dashboardApi.getIndicators()
    await nextTick()
    // Pequeno delay para garantir que os canvas elements estejam renderizados
    setTimeout(() => {
      createCharts()
    }, 150)
  } catch (error: any) {
    console.error('Erro ao carregar dashboard:', error)
    uiStore.showToast('error', 'Erro ao carregar dashboard')
  } finally {
    loading.value = false
  }
}

const createCharts = () => {
  if (!dashboardData.value) return

  // Destroy existing charts
  if (statusChart) {
    statusChart.destroy()
    statusChart = null
  }
  if (urgencyChart) {
    urgencyChart.destroy()
    urgencyChart = null
  }
  if (timeChart) {
    timeChart.destroy()
    timeChart = null
  }

  // Status Chart (Doughnut)
  if (statusChartRef.value) {
    const ctx = statusChartRef.value.getContext('2d')
    if (ctx) {
      const statusData = dashboardData.value.por_status || {}
      const labels = Object.keys(statusData)
      const data = Object.values(statusData) as number[]

      if (labels.length > 0) {
        statusChart = new Chart(ctx, {
          type: 'doughnut',
          data: {
            labels,
            datasets: [{
              data,
              backgroundColor: [
                '#3B82F6', '#F59E0B', '#06B6D4', '#10B981', '#EF4444', '#6B7280'
              ],
              borderWidth: 2,
              borderColor: '#ffffff',
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
              legend: { display: false },
              tooltip: { enabled: true }
            }
          }
        })
      }
    }
  }

  // Urgency Chart (Bar)
  if (urgencyChartRef.value) {
    const ctx = urgencyChartRef.value.getContext('2d')
    if (ctx) {
      const urgencyData = dashboardData.value.por_urgencia || {}
      const labels = Object.keys(urgencyData)
      const data = Object.values(urgencyData) as number[]

      if (labels.length > 0) {
        const backgroundColors = labels.map(label => {
          const lower = label.toLowerCase()
          if (lower.includes('crítico')) return '#EF4444'
          if (lower.includes('alta')) return '#F97316'
          if (lower.includes('média') || lower.includes('media')) return '#F59E0B'
          return '#10B981'
        })

        urgencyChart = new Chart(ctx, {
          type: 'bar',
          data: {
            labels,
            datasets: [{
              label: 'Chamados',
              data,
              backgroundColor: backgroundColors,
              borderRadius: 6,
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
              y: {
                beginAtZero: true,
                ticks: { precision: 0 }
              }
            }
          }
        })
      }
    }
  }

  // Time Chart (Bar)
  if (timeChartRef.value) {
    const ctx = timeChartRef.value.getContext('2d')
    if (ctx) {
      const timeData = dashboardData.value.tempo_resolucao || {}
      const labels = Object.keys(timeData)
      const data = Object.values(timeData) as number[]

      if (labels.length > 0) {
        timeChart = new Chart(ctx, {
          type: 'bar',
          data: {
            labels,
            datasets: [{
              label: 'Chamados',
              data,
              backgroundColor: '#8B5CF6',
              borderRadius: 6,
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
              y: {
                beginAtZero: true,
                ticks: { precision: 0 }
              }
            }
          }
        })
      }
    }
  }
}

// Export PDF with Charts
const exportPDF = async () => {
  if (!dashboardData.value) return
  
  try {
    uiStore.showToast('info', 'Gerando PDF com gráficos...')
    
    // Import libraries
    const { jsPDF } = await import('jspdf')
    const html2canvas = (await import('html2canvas')).default
    
    const doc = new jsPDF('p', 'mm', 'a4')
    const pageWidth = doc.internal.pageSize.getWidth()
    const pageHeight = doc.internal.pageSize.getHeight()
    let yPos = 20
    
    // Título
    doc.setFontSize(20)
    doc.setTextColor(0, 0, 0)
    doc.text('Dashboard Gerencial', pageWidth / 2, yPos, { align: 'center' })
    
    // Subtítulo
    yPos += 10
    doc.setFontSize(11)
    doc.setTextColor(100, 100, 100)
    doc.text(`Relatório gerado em: ${format(new Date(), 'dd/MM/yyyy HH:mm:ss')}`, pageWidth / 2, yPos, { align: 'center' })
    yPos += 5
    doc.text(`Período: Últimos ${selectedPeriod.value} dias`, pageWidth / 2, yPos, { align: 'center' })
    
    // Linha separadora
    yPos += 5
    doc.setDrawColor(200, 200, 200)
    doc.setLineWidth(0.5)
    doc.line(20, yPos, pageWidth - 20, yPos)
    
    // KPIs
    yPos += 10
    doc.setFontSize(14)
    doc.setTextColor(0, 0, 0)
    doc.text('Indicadores Principais', 20, yPos)
    
    yPos += 8
    doc.setFontSize(10)
    doc.setTextColor(60, 60, 60)
    doc.text(`Total de Chamados: ${dashboardData.value.kpis.total_chamados || 0}`, 25, yPos)
    yPos += 6
    doc.text(`Críticos Abertos: ${dashboardData.value.kpis.criticos_abertos || 0}`, 25, yPos)
    yPos += 6
    doc.text(`Tempo Médio de Resolução: ${dashboardData.value.kpis.tempo_medio || 'N/A'}`, 25, yPos)
    yPos += 6
    doc.text(`SLA Compliance: ${slaPercentage.value}%`, 25, yPos)
    
    // Status
    yPos += 10
    doc.setFontSize(14)
    doc.setTextColor(0, 0, 0)
    doc.text('Chamados por Status', 20, yPos)
    
    yPos += 6
    doc.setFontSize(9)
    doc.setTextColor(60, 60, 60)
    for (const [status, count] of Object.entries(dashboardData.value.por_status || {})) {
      doc.text(`• ${status}: ${count}`, 25, yPos)
      yPos += 5
    }
    
    // Urgência
    yPos += 8
    doc.setFontSize(14)
    doc.setTextColor(0, 0, 0)
    doc.text('Chamados por Urgência', 20, yPos)
    
    yPos += 6
    doc.setFontSize(9)
    doc.setTextColor(60, 60, 60)
    for (const [urgencia, count] of Object.entries(dashboardData.value.por_urgencia || {})) {
      doc.text(`• ${urgencia}: ${count}`, 25, yPos)
      yPos += 5
    }
    
    // Nova página para gráficos
    doc.addPage()
    yPos = 20
    
    doc.setFontSize(16)
    doc.setTextColor(0, 0, 0)
    doc.text('Gráficos e Visualizações', pageWidth / 2, yPos, { align: 'center' })
    yPos += 10
    
   // Capturar e adicionar gráficos
    const chartContainers = [
      { ref: statusChartContainer, title: 'Chamados por Status' },
      { ref: slaChartContainer, title: 'SLA Compliance' },
      { ref: urgencyChartContainer, title: 'Chamados por Urgência' },
      { ref: timeChartContainer, title: 'Tempo para Resolver' },
    ]
    
    for (const container of chartContainers) {
      if (container.ref.value) {
        try {
          doc.setFontSize(12)
          doc.setTextColor(0, 0, 0)
          doc.text(container.title, 20, yPos)
          yPos += 8
          
          const canvas = await html2canvas(container.ref.value, {
            scale: 2,
            backgroundColor: '#ffffff'
          })
          
          const imgData = canvas.toDataURL('image/png')
          const imgWidth = pageWidth - 40
          const imgHeight = (canvas.height * imgWidth) / canvas.width
          
          // Verificar se precisa de nova página
          if (yPos + imgHeight > pageHeight - 20) {
            doc.addPage()
            yPos = 20
          }
          
          doc.addImage(imgData, 'PNG', 20, yPos, imgWidth, imgHeight)
          yPos += imgHeight + 10
        } catch (error) {
          console.error(`Erro ao capturar ${container.title}:`, error)
        }
      }
    }
    
    // Nova página para chamados críticos
    if (dashboardData.value.criticos && dashboardData.value.criticos.length > 0) {
      doc.addPage()
      yPos = 20
      
      doc.setFontSize(16)
      doc.setTextColor(0, 0, 0)
      doc.text('Chamados Críticos Abertos', 20, yPos)
      yPos += 10
      
      doc.setFontSize(9)
      doc.setTextColor(60, 60, 60)
      
      for (const task of dashboardData.value.criticos.slice(0, 10)) {
        if (yPos > pageHeight - 30) {
          doc.addPage()
          yPos = 20
        }
        
        doc.text(`#${task.id} - ${task.titulo}`, 25, yPos)
        yPos += 5
        doc.text(`  Responsável: ${task.solicitante_nome || 'Não atribuído'}`, 25, yPos)
        yPos += 5
        doc.text(`  Ambiente: ${task.ambiente} | Urgência: ${task.urgencia}`, 25, yPos)
        yPos += 5
        doc.text(`  Data: ${formatDate(task.data_criacao)}`, 25, yPos)
        yPos += 8
      }
    }
    
    // Rodapé
    const totalPages = doc.getNumberOfPages()
    for (let i = 1; i <= totalPages; i++) {
      doc.setPage(i)
      doc.setFontSize(9)
      doc.setTextColor(128, 128, 128)
      doc.text(
        `Sistema de Gestão de Chamados - Página ${i} de ${totalPages}`,
        pageWidth / 2,
        pageHeight - 10,
        { align: 'center' }
      )
    }
    
    // Salvar
    doc.save(`dashboard_${new Date().toISOString().split('T')[0]}.pdf`)
    
    uiStore.showToast('success', 'PDF gerado com sucesso!')
  } catch (error) {
    console.error('Erro ao gerar PDF:', error)
    uiStore.showToast('error', 'Erro ao gerar PDF. Instale: npm install jspdf html2canvas')
  }
}

const exportCSV = () => {
  if (!dashboardData.value) return

  const now = new Date()
  let csvContent = "data:text/csv;charset=utf-8,"
  csvContent += "Dashboard Gerencial - Relatório\n"
  csvContent += `Gerado em,${format(now, 'dd/MM/yyyy HH:mm:ss')}\n`
  csvContent += `Período,Últimos ${selectedPeriod.value} dias\n\n`
  
  csvContent += "=== INDICADORES PRINCIPAIS ===\n"
  csvContent += "Indicador,Valor\n"
  csvContent += `Total Chamados,${dashboardData.value.kpis.total_chamados || 0}\n`
  csvContent += `Críticos Abertos,${dashboardData.value.kpis.criticos_abertos || 0}\n`
  csvContent += `Tempo Médio,${dashboardData.value.kpis.tempo_medio || 'N/A'}\n`
  csvContent += `SLA Compliance,${slaPercentage.value}%\n\n`
  
  csvContent += "=== CHAMADOS POR STATUS ===\n"
  csvContent += "Status,Quantidade\n"
  for (const [status, count] of Object.entries(dashboardData.value.por_status || {})) {
    csvContent += `${status},${count}\n`
  }
  
  csvContent += "\n=== CHAMADOS POR URGÊNCIA ===\n"
  csvContent += "Urgência,Quantidade\n"
  for (const [urgencia, count] of Object.entries(dashboardData.value.por_urgencia || {})) {
    csvContent += `${urgencia},${count}\n`
  }
  
  csvContent += "\n=== TEMPO DE RESOLUÇÃO ===\n"
  csvContent += "Faixa,Quantidade\n"
  for (const [faixa, count] of Object.entries(dashboardData.value.tempo_resolucao || {})) {
    csvContent += `${faixa},${count}\n`
  }

  const encodedUri = encodeURI(csvContent)
  const link = document.createElement("a")
  link.setAttribute("href", encodedUri)
  link.setAttribute("download", `dashboard_${now.getTime()}.csv`)
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)

  uiStore.showToast('success', 'CSV exportado com sucesso')
}

onMounted(() => {
  loadDashboard()
})

onBeforeUnmount(() => {
  if (statusChart) statusChart.destroy()
  if (urgencyChart) urgencyChart.destroy()
  if (timeChart) timeChart.destroy()
})
</script>