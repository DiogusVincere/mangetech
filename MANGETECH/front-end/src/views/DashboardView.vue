<template>
  <div class="space-y-6">
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900">Dashboard gerencial</h1>
        <p class="text-sm text-gray-500 mt-1">Chamados abertos {{ periodoTexto }} e situação dos ativos</p>
      </div>
      <div class="flex items-center gap-2">
        <select
          v-model="selectedPeriod"
          @change="loadDashboard"
          class="px-3 py-2 border border-gray-300 rounded-lg bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="7">Últimos 7 dias</option>
          <option value="30">Últimos 30 dias</option>
          <option value="90">Últimos 90 dias</option>
          <option value="365">Últimos 12 meses</option>
          <option value="">Todo o período</option>
        </select>
        <button
          @click="exportPDF"
          :disabled="!data || loading"
          class="flex items-center gap-2 px-4 py-2 border border-gray-300 bg-white rounded-lg hover:bg-gray-50 disabled:opacity-50"
        >
          <Download :size="18" /> PDF
        </button>
        <button
          @click="exportCSV"
          :disabled="!data || loading"
          class="flex items-center gap-2 px-4 py-2 border border-gray-300 bg-white rounded-lg hover:bg-gray-50 disabled:opacity-50"
        >
          <Download :size="18" /> CSV
        </button>
      </div>
    </div>

    <div v-if="loading && !data" class="flex flex-col items-center justify-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      <p class="text-gray-600 mt-4">Carregando indicadores…</p>
    </div>

    <div v-else-if="loadError" class="bg-white rounded-xl border border-gray-200 text-center py-16 px-4">
      <AlertCircle :size="40" class="mx-auto text-red-500 mb-4" />
      <p class="text-gray-700 mb-6">{{ loadError }}</p>
      <button @click="loadDashboard" class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Tentar novamente</button>
    </div>

    <template v-else-if="data">
      <div :class="['grid grid-cols-2 lg:grid-cols-4 gap-4 transition-opacity', loading ? 'opacity-50' : '']">
        <router-link
          v-for="kpi in kpis"
          :key="kpi.label"
          :to="kpi.link"
          class="bg-white rounded-xl shadow-sm border border-gray-200 p-5 hover:shadow-md hover:border-blue-300 transition"
        >
          <div class="flex items-start justify-between">
            <div>
              <p class="text-sm text-gray-500 font-medium">{{ kpi.label }}</p>
              <p :class="['text-3xl font-bold mt-2', kpi.color]">{{ kpi.value }}</p>
              <p class="text-xs text-gray-500 mt-1">{{ kpi.hint }}</p>
            </div>
            <div :class="['w-11 h-11 rounded-lg flex items-center justify-center', kpi.bg]">
              <component :is="kpi.icon" :size="22" :class="kpi.color" />
            </div>
          </div>
        </router-link>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Por status</h2>
          <div v-if="data.kpis.total_chamados" class="h-64 relative"><canvas ref="statusChartRef"></canvas></div>
          <p v-else class="text-sm text-gray-500 py-16 text-center">Nenhum chamado no período.</p>
        </section>

        <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Por urgência</h2>
          <div v-if="data.kpis.total_chamados" class="h-64 relative"><canvas ref="urgencyChartRef"></canvas></div>
          <p v-else class="text-sm text-gray-500 py-16 text-center">Nenhum chamado no período.</p>
        </section>

        <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-1">Tempo até resolver</h2>
          <p class="text-xs text-gray-500 mb-4">Da abertura até o primeiro "Realizado" ou "Concluído"</p>
          <div class="flex gap-6 mb-3">
            <div>
              <p class="text-xs text-gray-500">Média</p>
              <p class="text-2xl font-bold text-gray-900">{{ data.kpis.tempo_medio }}</p>
            </div>
            <div>
              <p class="text-xs text-gray-500">Resolvidos no prazo</p>
              <p class="text-2xl font-bold text-gray-900">
                {{ data.kpis.no_prazo_percentual === null ? '—' : `${data.kpis.no_prazo_percentual}%` }}
              </p>
            </div>
          </div>
          <div v-if="totalResolvidos" class="h-40 relative"><canvas ref="timeChartRef"></canvas></div>
          <p v-else class="text-sm text-gray-500 py-10 text-center">Nenhum chamado resolvido no período.</p>
        </section>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <section class="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 class="text-lg font-semibold text-gray-900">Críticos e altos em aberto</h2>
            <router-link to="/tasks?criticos_abertos=true" class="text-sm text-blue-600 hover:underline">Ver todos</router-link>
          </div>
          <div v-if="data.criticos.length" class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Nº</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Título</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Responsáveis</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Urgência</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="task in data.criticos"
                  :key="task.id"
                  class="hover:bg-gray-50 cursor-pointer"
                  @click="router.push(`/tasks/${task.id}`)"
                >
                  <td class="px-4 py-3 font-medium text-gray-900">#{{ task.id }}</td>
                  <td class="px-4 py-3 text-gray-700">
                    {{ task.titulo }}
                    <span v-if="task.atrasado" class="ml-1 px-1.5 py-0.5 text-[10px] font-semibold rounded bg-red-600 text-white">ATRASADO</span>
                  </td>
                  <td class="px-4 py-3 text-gray-500">{{ task.responsaveis_nomes?.join(', ') || 'Sem responsável' }}</td>
                  <td class="px-4 py-3"><span :class="['px-2 py-0.5 text-xs font-semibold rounded-full', statusClass(task.status)]">{{ statusLabel(task.status) }}</span></td>
                  <td class="px-4 py-3"><span :class="['px-2 py-0.5 text-xs font-semibold rounded-full', priorityClass(task.urgencia)]">{{ task.urgencia }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div v-else class="px-6 py-12 text-center">
            <CheckCircle :size="40" class="mx-auto text-green-500 mb-3" />
            <p class="text-gray-500">Nenhum chamado crítico ou alto em aberto.</p>
          </div>
        </section>

        <section class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Ativos</h2>
            <router-link to="/assets" class="text-sm text-blue-600 hover:underline">Abrir</router-link>
          </div>
          <div class="grid grid-cols-3 gap-2 mb-5 text-center">
            <div class="rounded-lg bg-green-50 py-3">
              <p class="text-2xl font-bold text-green-700">{{ data.ativos.ativos }}</p>
              <p class="text-xs text-green-800">em operação</p>
            </div>
            <div class="rounded-lg bg-yellow-50 py-3">
              <p class="text-2xl font-bold text-yellow-700">{{ data.ativos.manutencao }}</p>
              <p class="text-xs text-yellow-800">manutenção</p>
            </div>
            <div class="rounded-lg bg-gray-100 py-3">
              <p class="text-2xl font-bold text-gray-700">{{ data.ativos.inativos }}</p>
              <p class="text-xs text-gray-600">inativos</p>
            </div>
          </div>
          <p class="text-sm font-medium text-gray-700 mb-2">Mais chamados no período</p>
          <ul v-if="data.ativos.mais_chamados.length" class="space-y-2">
            <li v-for="a in data.ativos.mais_chamados" :key="a.id">
              <router-link :to="`/assets/${a.id}`" class="flex items-center justify-between gap-2 text-sm hover:text-blue-600">
                <span class="truncate"><span class="font-mono text-gray-500">{{ a.codigo }}</span> {{ a.nome }}</span>
                <span class="font-semibold">{{ a.total_chamados }}</span>
              </router-link>
            </li>
          </ul>
          <p v-else class="text-sm text-gray-500">Nenhum chamado ligado a ativos no período.</p>
        </section>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { AlertCircle, AlertTriangle, CheckCircle, ClipboardList, Clock, Download } from 'lucide-vue-next'
import { Chart, registerables } from 'chart.js'
import { dashboardApi, extractError, downloadBlob } from '@/api'
import { useUiStore } from '@/stores/ui'
import type { DashboardData } from '@/types'
import { priorityClass, statusClass, statusLabel } from '@/utils/display'

Chart.register(...registerables)

const router = useRouter()
const uiStore = useUiStore()
const loading = ref(false)
const loadError = ref('')
const data = ref<DashboardData | null>(null)
const selectedPeriod = ref('30')

const statusChartRef = ref<HTMLCanvasElement>()
const urgencyChartRef = ref<HTMLCanvasElement>()
const timeChartRef = ref<HTMLCanvasElement>()
let charts: Chart[] = []

const periodoTexto = computed(() => {
  if (!selectedPeriod.value) return 'em todo o período'
  return selectedPeriod.value === '365' ? 'nos últimos 12 meses' : `nos últimos ${selectedPeriod.value} dias`
})

const emAberto = computed(() => {
  const k = data.value?.kpis
  return k ? k.abertos + k.aguardando + k.em_andamento : 0
})

const totalResolvidos = computed(() =>
  Object.values(data.value?.tempo_resolucao || {}).reduce((a, b) => a + b, 0)
)

const kpis = computed(() => {
  const k = data.value?.kpis
  if (!k) return []
  return [
    { label: 'Chamados', value: k.total_chamados, hint: periodoTexto.value, icon: ClipboardList, color: 'text-blue-600', bg: 'bg-blue-100', link: '/tasks' },
    {
      label: 'Em aberto', value: emAberto.value, hint: `${k.criticos_abertos} crítico(s)/alto(s)`, icon: AlertTriangle,
      color: 'text-orange-600', bg: 'bg-orange-100', link: '/tasks?status=ABERTO,AGUARDANDO%20RESP,EM%20ANDAMENTO',
    },
    {
      label: 'Atrasados', value: k.atrasados, hint: 'prazo sugerido vencido', icon: Clock,
      color: k.atrasados ? 'text-red-600' : 'text-gray-700', bg: 'bg-red-100', link: '/tasks?atrasados=true',
    },
    {
      label: 'Taxa de resolução', value: `${k.taxa_resolucao}%`, hint: `tempo médio ${k.tempo_medio}`, icon: CheckCircle,
      color: 'text-green-600', bg: 'bg-green-100', link: '/tasks?status=REALIZADO,CONCLU%C3%8DDO',
    },
  ]
})

const STATUS_CORES: Record<string, [string, string]> = {
  aberto: ['Aberto', '#3B82F6'],
  aguardando: ['Aguardando', '#EAB308'],
  em_andamento: ['Em andamento', '#A855F7'],
  realizado: ['Realizado', '#06B6D4'],
  concluido: ['Concluído', '#22C55E'],
  cancelado: ['Cancelado', '#9CA3AF'],
}
const URGENCIA: [string, string, string][] = [
  ['critico', 'Crítico', '#DC2626'],
  ['alta', 'Alta', '#F97316'],
  ['media', 'Média', '#EAB308'],
  ['baixa', 'Baixa', '#22C55E'],
]
const FAIXAS: [string, string][] = [
  ['menos_1h', '< 1h'], ['1_2h', '1–2h'], ['2_4h', '2–4h'], ['4_8h', '4–8h'],
  ['8_12h', '8–12h'], ['12_24h', '12–24h'], ['mais_24h', '> 24h'],
]

const destroyCharts = () => {
  charts.forEach((c) => c.destroy())
  charts = []
}

const createCharts = () => {
  destroyCharts()
  const d = data.value
  if (!d) return

  if (statusChartRef.value) {
    const chaves = Object.keys(STATUS_CORES).filter((k) => (d.por_status[k] || 0) > 0)
    charts.push(new Chart(statusChartRef.value, {
      type: 'doughnut',
      data: {
        labels: chaves.map((k) => STATUS_CORES[k]![0]),
        datasets: [{ data: chaves.map((k) => d.por_status[k] || 0), backgroundColor: chaves.map((k) => STATUS_CORES[k]![1]), borderWidth: 2, borderColor: '#fff' }],
      },
      options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom', labels: { boxWidth: 12, padding: 12 } } } },
    }))
  }

  if (urgencyChartRef.value) {
    charts.push(new Chart(urgencyChartRef.value, {
      type: 'bar',
      data: {
        labels: URGENCIA.map((u) => u[1]),
        datasets: [{ data: URGENCIA.map((u) => d.por_urgencia[u[0]] || 0), backgroundColor: URGENCIA.map((u) => u[2]), borderRadius: 6 }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { grid: { display: false } } },
      },
    }))
  }

  if (timeChartRef.value) {
    charts.push(new Chart(timeChartRef.value, {
      type: 'bar',
      data: {
        labels: FAIXAS.map((f) => f[1]),
        datasets: [{ data: FAIXAS.map((f) => d.tempo_resolucao[f[0]] || 0), backgroundColor: '#3B82F6', borderRadius: 4 }],
      },
      options: {
        responsive: true, maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { precision: 0 } }, x: { grid: { display: false } } },
      },
    }))
  }
}

const loadDashboard = async () => {
  loading.value = true
  loadError.value = ''
  try {
    data.value = await dashboardApi.getIndicators(selectedPeriod.value)
    loading.value = false
    await nextTick()
    createCharts()
  } catch (err) {
    loadError.value = extractError(err, 'Não foi possível carregar os indicadores.')
  } finally {
    loading.value = false
  }
}

const linhasRelatorio = (): [string, string | number][] => {
  const d = data.value!
  const k = d.kpis
  return [
    ['Período', periodoTexto.value],
    ['Chamados', k.total_chamados],
    ['Em aberto', emAberto.value],
    ['Críticos/altos em aberto', k.criticos_abertos],
    ['Atrasados', k.atrasados],
    ['Taxa de resolução', `${k.taxa_resolucao}%`],
    ['Tempo médio até resolver', k.tempo_medio],
    ['Resolvidos no prazo', k.no_prazo_percentual === null ? '—' : `${k.no_prazo_percentual}%`],
    ...Object.entries(STATUS_CORES).map(([key, [label]]) => [`Status: ${label}`, d.por_status[key] || 0] as [string, number]),
    ...URGENCIA.map(([key, label]) => [`Urgência: ${label}`, d.por_urgencia[key] || 0] as [string, number]),
    ['Ativos em operação', d.ativos.ativos],
    ['Ativos em manutenção', d.ativos.manutencao],
    ['Ativos inativos', d.ativos.inativos],
  ]
}

const exportCSV = () => {
  if (!data.value) return
  const linhas = [['Indicador', 'Valor'], ...linhasRelatorio()]
  const csv = linhas.map((l) => l.map((c) => `"${String(c).replace(/"/g, '""')}"`).join(';')).join('\r\n')
  downloadBlob(new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' }), `dashboard_${new Date().toISOString().slice(0, 10)}.csv`)
}

const exportPDF = async () => {
  if (!data.value) return
  try {
    const { jsPDF } = await import('jspdf')
    const doc = new jsPDF()
    doc.setFontSize(16)
    doc.text('MangeTech · Dashboard gerencial', 14, 18)
    doc.setFontSize(10)
    doc.setTextColor(110)
    doc.text(`Gerado em ${new Date().toLocaleString('pt-BR')}`, 14, 25)
    doc.setTextColor(20)
    let y = 36
    for (const [label, valor] of linhasRelatorio()) {
      doc.text(label, 14, y)
      doc.text(String(valor), 120, y)
      y += 7
    }
    if (data.value.criticos.length) {
      y += 4
      doc.setFontSize(12)
      doc.text('Críticos e altos em aberto', 14, y)
      doc.setFontSize(10)
      y += 7
      for (const t of data.value.criticos) {
        if (y > 280) { doc.addPage(); y = 20 }
        doc.text(`#${t.id} ${t.titulo}`.slice(0, 80), 14, y)
        doc.text(t.urgencia, 170, y)
        y += 6
      }
    }
    doc.save(`dashboard_${new Date().toISOString().slice(0, 10)}.pdf`)
  } catch (err) {
    uiStore.showToast('error', 'Não foi possível gerar o PDF.')
  }
}

onMounted(loadDashboard)
onBeforeUnmount(destroyCharts)
</script>
