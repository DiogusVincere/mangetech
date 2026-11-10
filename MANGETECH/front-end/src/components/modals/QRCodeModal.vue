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
import { onUnmounted, ref, watch } from 'vue'
import { X, Download, Printer, AlertCircle } from 'lucide-vue-next'
import { assetsApi, extractError } from '@/api'

interface Props {
  isOpen: boolean
  ativoId: number
}

interface QRCodeData {
  qr_code: string // data:image/png;base64,...
  ativo_codigo: string
  ativo_nome: string
  ativo_modelo: string
  ativo_ambiente: string
}

const props = defineProps<Props>()
const emit = defineEmits<{ close: [] }>()

const qrCodeData = ref<QRCodeData | null>(null)
const isLoading = ref(false)
const error = ref('')

const loadQRCode = async () => {
  if (!props.ativoId) return
  isLoading.value = true
  error.value = ''
  try {
    const data = await assetsApi.getQRCode(props.ativoId)
    qrCodeData.value = {
      qr_code: data.qr_code,
      ativo_codigo: data.ativo_codigo,
      ativo_nome: data.ativo_nome || '',
      ativo_modelo: data.ativo_modelo || '',
      ativo_ambiente: data.ativo_ambiente || '',
    }
  } catch (err) {
    qrCodeData.value = null
    error.value = extractError(err, 'Não foi possível gerar o QR code.')
  } finally {
    isLoading.value = false
  }
}

// Carrega quando abre (e quando o id chega depois, como logo após cadastrar).
watch(
  () => [props.isOpen, props.ativoId] as const,
  ([aberto, id]) => {
    if (aberto && id) {
      loadQRCode()
      window.addEventListener('keydown', handleEscKey)
    } else if (!aberto) {
      qrCodeData.value = null
      error.value = ''
      window.removeEventListener('keydown', handleEscKey)
    }
  },
  { immediate: true }
)

onUnmounted(() => window.removeEventListener('keydown', handleEscKey))

function handleClose() {
  emit('close')
}

function handleBackdropClick(e: MouseEvent) {
  if (e.target === e.currentTarget) handleClose()
}

function handleEscKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && props.isOpen) handleClose()
}

const handleDownload = () => {
  if (!qrCodeData.value) return
  const link = document.createElement('a')
  link.href = qrCodeData.value.qr_code
  link.download = `qrcode-${qrCodeData.value.ativo_codigo}.png`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}

const escapeHtml = (texto: string) =>
  texto.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c] as string)

// Etiqueta para imprimir e colar no equipamento.
const handlePrint = () => {
  const qr = qrCodeData.value
  if (!qr) return
  const janela = window.open('', '_blank', 'width=480,height=640')
  if (!janela) {
    error.value = 'O navegador bloqueou a janela de impressão. Libere pop-ups para este site.'
    return
  }
  const codigo = escapeHtml(qr.ativo_codigo)
  const linhas = [qr.ativo_nome, qr.ativo_modelo, qr.ativo_ambiente].filter(Boolean).map(escapeHtml)
  janela.document.write(`<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><title>QR ${codigo}</title>
<style>
  body{font-family:Arial,sans-serif;display:flex;justify-content:center;padding:24px;margin:0}
  .etiqueta{border:2px solid #000;border-radius:8px;padding:20px;text-align:center;width:320px}
  img{width:100%;height:auto}
  .info{font-size:13px;color:#333;margin-top:8px;line-height:1.5}
  .marca{font-size:11px;color:#777;margin-top:10px}
  @media print{body{padding:0}}
</style></head><body>
<div class="etiqueta">
  <img id="qr" src="${qr.qr_code}" alt="QR code ${codigo}">
  <div class="info">${linhas.join('<br>')}</div>
  <div class="marca">MangeTech · escaneie para abrir o ativo</div>
</div>
<script>document.getElementById('qr').onload=function(){window.focus();window.print();}<\/script>
</body></html>`)
  janela.document.close()
}
</script>