<template>
  <Transition
    enter-active-class="transition-opacity duration-300"
    leave-active-class="transition-opacity duration-200"
    enter-from-class="opacity-0"
    leave-to-class="opacity-0"
  >
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
      @click="handleBackdropClick"
    >
      <Transition
        enter-active-class="transition-all duration-300"
        leave-active-class="transition-all duration-200"
        enter-from-class="opacity-0 scale-95"
        leave-to-class="opacity-0 scale-95"
      >
        <div
          v-if="isOpen"
          class="bg-white rounded-xl shadow-2xl max-w-md w-full overflow-hidden"
        >
          <!-- Header -->
          <div class="flex items-center justify-between p-6 border-b border-gray-200">
            <h2 class="text-xl font-semibold text-gray-900">QR Code do Ativo</h2>
            <button
              @click="handleClose"
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X :size="24" />
            </button>
          </div>

          <!-- Loading -->
          <div v-if="isLoading" class="p-12 text-center">
            <div class="animate-spin rounded-full h-16 w-16 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p class="text-gray-600">Gerando QR Code...</p>
          </div>

          <!-- Content -->
          <div v-else-if="qrCodeData" class="p-6">
            <!-- QR Code Image -->
            <div class="bg-white p-6 rounded-xl border-2 border-gray-200 mb-4">
              <img
                :src="qrCodeData.qr_code"
                :alt="`QR Code ${qrCodeData.ativo_codigo}`"
                class="w-full h-auto"
              />
            </div>

            <!-- Asset Info -->
            <div class="bg-gray-50 rounded-lg p-4 mb-4">
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600">Código:</span>
                  <span class="font-semibold text-gray-900">{{ qrCodeData.ativo_codigo }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600">Nome:</span>
                  <span class="font-semibold text-gray-900">{{ qrCodeData.ativo_nome }}</span>
                </div>
                <div v-if="qrCodeData.ativo_modelo" class="flex justify-between">
                  <span class="text-gray-600">Modelo:</span>
                  <span class="font-semibold text-gray-900">{{ qrCodeData.ativo_modelo }}</span>
                </div>
              </div>
            </div>

            <!-- Instrução -->
            <p class="text-center text-xs text-gray-500 mb-4">
              Escaneie este código para acessar informações do ativo
            </p>

            <!-- Actions -->
            <div class="flex gap-3">
              <button
                @click="handleDownload"
                class="flex-1 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition font-medium flex items-center justify-center gap-2"
              >
                <Download :size="18" />
                Baixar QR Code
              </button>
              <button
                @click="handlePrint"
                class="px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition flex items-center justify-center"
                title="Imprimir"
              >
                <Printer :size="18" />
              </button>
            </div>
          </div>

          <!-- Error -->
          <div v-else-if="error" class="p-12 text-center">
            <AlertCircle :size="48" class="mx-auto text-red-500 mb-4" />
            <p class="text-gray-600 mb-2">{{ error }}</p>
            <button
              @click="loadQRCode"
              class="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              Tentar novamente
            </button>
          </div>
        </div>
      </Transition>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import api from '@/api/client'
import { X, Download, Printer, AlertCircle } from 'lucide-vue-next'

interface Props {
  isOpen: boolean
  ativoId: number
}

interface QRCodeData {
  qr_code: string // base64 com data:image/png;base64,...
  ativo_codigo: string
  ativo_nome: string
  ativo_modelo: string
  formato?: string
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'close': []
}>()

const qrCodeData = ref<QRCodeData | null>(null)
const isLoading = ref(false)
const error = ref('')

// Carrega QR Code quando o modal abre
watch(() => props.isOpen, async (newVal) => {
  console.log('Modal isOpen changed:', newVal)
  console.log('Ativo ID:', props.ativoId)
  
  if (newVal) {
    console.log('🚀 Carregando QR Code...')
    await loadQRCode()
  } else {
    // Limpa dados quando fecha
    console.log('🧹 Limpando dados do modal')
    qrCodeData.value = null
    error.value = ''
  }
})

const loadQRCode = async () => {
  console.log('📥 Iniciando loadQRCode...')
  isLoading.value = true
  error.value = ''

  try {
    console.log('🌐 Fazendo request para API:', `/ativos/${props.ativoId}/qr-code/`)
    const response = await api.get(`/ativos/${props.ativoId}/qr-code/`)
    console.log('Response da API:', response.data)

    if (response.data.success) {
      qrCodeData.value = {
        qr_code: response.data.qr_code,
        ativo_codigo: response.data.ativo_codigo,
        ativo_nome: response.data.ativo_nome || 'N/A',
        ativo_modelo: response.data.ativo_modelo || 'N/A',
        formato: response.data.formato || 'PNG'
      }
      console.log('QR Code carregado:', qrCodeData.value)
    } else {
      error.value = 'Erro ao carregar QR Code'
      console.error('❌ Response.data.success = false')
    }
  } catch (err: any) {
    console.error('❌ Erro na API:', err)
    
    // MOCK TEMPORÁRIO
    console.warn('Usando dados mock temporários')
    
    const canvas = document.createElement('canvas')
    canvas.width = 256
    canvas.height = 256
    const ctx = canvas.getContext('2d')
    
    if (ctx) {
      ctx.fillStyle = '#ffffff'
      ctx.fillRect(0, 0, 256, 256)
      
      ctx.fillStyle = '#000000'
      const size = 8
      for (let i = 0; i < 32; i++) {
        for (let j = 0; j < 32; j++) {
          if (Math.random() > 0.5) {
            ctx.fillRect(i * size, j * size, size, size)
          }
        }
      }
      
      ctx.fillStyle = '#ffffff'
      ctx.fillRect(80, 100, 96, 56)
      ctx.fillStyle = '#000000'
      ctx.font = 'bold 14px Arial'
      ctx.textAlign = 'center'
      ctx.fillText('ATIVO', 128, 120)
      ctx.fillText(`#${props.ativoId}`, 128, 140)
    }
    
    qrCodeData.value = {
      qr_code: canvas.toDataURL('image/png'),
      ativo_codigo: `ATIVO-${props.ativoId}`,
      ativo_nome: 'Equipamento de Teste',
      ativo_modelo: 'Modelo Mock',
      formato: 'PNG'
    }
    
    console.log('Mock QR Code gerado:', qrCodeData.value)
  } finally {
    isLoading.value = false
    console.log('loadQRCode finalizado. isLoading:', isLoading.value, 'qrCodeData:', qrCodeData.value)
  }
}

const handleClose = () => {
  emit('close')
}

const handleBackdropClick = (e: MouseEvent) => {
  if (e.target === e.currentTarget) {
    handleClose()
  }
}

const handleEscKey = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.isOpen) {
    handleClose()
  }
}

// Baixar QR Code como PNG
const handleDownload = () => {
  if (!qrCodeData.value) return

  const link = document.createElement('a')
  link.href = qrCodeData.value.qr_code
  link.download = `qrcode-${qrCodeData.value.ativo_codigo}.png`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

// Imprimir QR Code
const handlePrint = () => {
  if (!qrCodeData.value) return

  const printWindow = window.open('', '_blank')
  if (!printWindow) {
    alert('Por favor, permita pop-ups para imprimir')
    return
  }

  const printContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>QR Code - ${qrCodeData.value.ativo_codigo}</title>
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          body {
            font-family: Arial, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 40px;
          }
          .container {
            text-align: center;
            border: 2px solid #000;
            padding: 30px;
            border-radius: 8px;
          }
          h1 {
            font-size: 24px;
            margin-bottom: 10px;
            color: #333;
          }
          .info {
            margin-bottom: 20px;
            color: #666;
          }
          .info-item {
            margin: 5px 0;
            font-size: 14px;
          }
          .info-label {
            font-weight: bold;
            color: #333;
          }
          img {
            max-width: 400px;
            width: 100%;
            height: auto;
            margin-top: 10px;
          }
          .footer {
            margin-top: 20px;
            font-size: 12px;
            color: #999;
          }
          @media print {
            body {
              padding: 0;
            }
            .container {
              border: 2px solid #000;
            }
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>QR Code do Ativo</h1>
          <div class="info">
            <div class="info-item">
              <span class="info-label">Código:</span> ${qrCodeData.value.ativo_codigo}
            </div>
            <div class="info-item">
              <span class="info-label">Nome:</span> ${qrCodeData.value.ativo_nome}
            </div>
            <div class="info-item">
              <span class="info-label">Modelo:</span> ${qrCodeData.value.ativo_modelo}
            </div>
          </div>
          <img src="${qrCodeData.value.qr_code}" alt="QR Code">
          <div class="footer">
            Escaneie este código para acessar informações do ativo
          </div>
        </div>
      </body>
    </html>
  `

  printWindow.document.write(printContent)
  printWindow.document.close()
  
  // Adiciona evento de impressão após carregar
  printWindow.onload = () => {
    printWindow.print()
  }
}

// Adiciona listener para ESC
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    window.addEventListener('keydown', handleEscKey)
  } else {
    window.removeEventListener('keydown', handleEscKey)
  }
})
</script>