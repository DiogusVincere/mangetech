// src/stores/assets.ts - COMPLETA E ATUALIZADA
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { assetsApi } from '@/api'
import type { Asset } from '@/types'

export const useAssetsStore = defineStore('assets', () => {
  const assets = ref<Asset[]>([])
  const currentAsset = ref<Asset | null>(null)
  const loading = ref(false)
  const totalAssets = ref(0)

  // ===== BUSCAR TODOS OS ATIVOS =====
  async function fetchAssets(filters?: any) {
    loading.value = true
    try {
      const data = await assetsApi.getAll(filters)
      assets.value = Array.isArray(data) ? data : (data.results || [])
      totalAssets.value = assets.value.length
      return assets.value
    } catch (error) {
      console.error('Erro ao buscar ativos:', error)
      assets.value = []
      throw error
    } finally {
      loading.value = false
    }
  }

  // ===== BUSCAR ATIVO ESPECÍFICO =====
  async function fetchAsset(id: number | string) {
    loading.value = true
    try {
      const data = await assetsApi.getById(id)
      currentAsset.value = data
      return data
    } catch (error) {
      console.error('Erro ao buscar ativo:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // ===== CRIAR NOVO ATIVO =====
  async function createAsset(assetData: any) {
    loading.value = true
    try {
      const newAsset = await assetsApi.create(assetData)
      assets.value.unshift(newAsset)
      totalAssets.value++
      return newAsset
    } catch (error) {
      console.error('Erro ao criar ativo:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // ===== ATUALIZAR ATIVO =====
  async function updateAsset(id: number | string, assetData: any) {
    loading.value = true
    try {
      const updatedAsset = await assetsApi.update(id, assetData)
      
      // Atualizar na lista se existir
      const index = assets.value.findIndex(a => a.id === id)
      if (index !== -1) {
        assets.value[index] = updatedAsset
      }
      
      // Atualizar currentAsset se for o mesmo
      if (currentAsset.value?.id === id) {
        currentAsset.value = updatedAsset
      }
      
      return updatedAsset
    } catch (error) {
      console.error('Erro ao atualizar ativo:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  // ===== DELETAR ATIVO ===== ADICIONAR
  async function deleteAsset(id: number | string) {
    try {
      await assetsApi.delete(id)
      
      // Remover da lista
      assets.value = assets.value.filter(a => a.id !== id)
      totalAssets.value--
      
      // Limpar currentAsset se for o mesmo
      if (currentAsset.value?.id === id) {
        currentAsset.value = null
      }
    } catch (error) {
      console.error('Erro ao deletar ativo:', error)
      throw error
    }
  }

  // ===== BUSCAR CHAMADOS DO ATIVO ===== ADICIONAR
  async function getAssetTasks(id: number | string) {
    try {
      const response = await assetsApi.getTasks(id)
      return response
    } catch (error) {
      console.error('Erro ao buscar chamados do ativo:', error)
      throw error
    }
  }

  // ===== GERAR QR CODE DO ATIVO ===== ADICIONAR
  async function getAssetQRCode(id: number | string) {
    try {
      const response = await assetsApi.getQRCode(id)
      return response
    } catch (error) {
      console.error('Erro ao gerar QR Code:', error)
      throw error
    }
  }

  // ===== ADICIONAR HISTÓRICO AO ATIVO ===== ADICIONAR
  async function addAssetHistory(id: number | string, tipo: string, descricao: string) {
    try {
      const response = await assetsApi.addHistory(id, tipo, descricao)
      
      // Recarregar o ativo para atualizar o histórico
      if (currentAsset.value?.id === id) {
        await fetchAsset(id)
      }
      
      return response
    } catch (error) {
      console.error('Erro ao adicionar histórico:', error)
      throw error
    }
  }

  // ===== LIMPAR ATIVO ATUAL =====
  function clearCurrentAsset() {
    currentAsset.value = null
  }

  return {
    // State
    assets,
    currentAsset,
    loading,
    totalAssets,
    
    // Actions
    fetchAssets,
    fetchAsset,
    createAsset,
    updateAsset,
    deleteAsset,           
    getAssetTasks,         
    getAssetQRCode,        
    addAssetHistory,       
    clearCurrentAsset
  }
})