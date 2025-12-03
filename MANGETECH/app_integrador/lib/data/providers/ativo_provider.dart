import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../../models/ativo.dart';

class AtivoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Ativo> _ativos = [];
  bool _isLoading = false;
  String? _error;
  Ativo? _ativoSelecionado;

  List<Ativo> get ativos => _ativos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Ativo? get ativoSelecionado => _ativoSelecionado;

  // ========== CARREGAR ATIVOS ==========
  
  Future<void> fetchAtivos({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ativos = await _apiService.getAtivos(search: search);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar ativos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== BUSCAR ATIVO POR QR CODE ==========
  
  Future<Ativo?> fetchAtivoByQRCode(String codigo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ativo = await _apiService.getAtivoByQRCode(codigo);
      _ativoSelecionado = ativo;
      _isLoading = false;
      notifyListeners();
      return ativo;
    } catch (e) {
      _error = 'Ativo não encontrado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========== BUSCAR ATIVO POR ID ==========
  
  Ativo? getAtivoById(int id) {
    try {
      return _ativos.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== FILTROS LOCAIS ==========
  
  List<Ativo> filterByStatus(String status) {
    return _ativos.where((a) => a.status == status).toList();
  }

  List<Ativo> filterByAmbiente(String ambiente) {
    return _ativos.where((a) => a.ambiente == ambiente).toList();
  }

  List<Ativo> searchAtivos(String query) {
    if (query.isEmpty) return _ativos;
    
    final lowerQuery = query.toLowerCase();
    return _ativos.where((a) {
      return a.nome.toLowerCase().contains(lowerQuery) ||
             a.codigo.toLowerCase().contains(lowerQuery) ||
             a.modelo.toLowerCase().contains(lowerQuery) ||
             (a.fabricante?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ========== ESTATÍSTICAS ==========
  
  Map<String, int> getStatusStats() {
    final stats = <String, int>{
      'Ativo': 0,
      'Inativo': 0,
      'Manutenção': 0,
    };
    
    for (var ativo in _ativos) {
      stats[ativo.status] = (stats[ativo.status] ?? 0) + 1;
    }
    
    return stats;
  }

  int getTotalChamados() {
    return _ativos.fold(0, (sum, ativo) => sum + ativo.totalChamados);
  }

  int getChamadosAbertos() {
    return _ativos.fold(0, (sum, ativo) => sum + ativo.chamadosAbertos);
  }

  // ========== SELECIONAR ATIVO ==========
  
  void setAtivoSelecionado(Ativo? ativo) {
    _ativoSelecionado = ativo;
    notifyListeners();
  }

  // ========== LIMPAR ERROS ==========
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== LIMPAR SELEÇÃO ==========
  
  void clearSelection() {
    _ativoSelecionado = null;
    notifyListeners();
  }

  // ========== CRIAR ATIVO ==========
  
  Future<bool> createAtivo({
    required String codigo,
    required String nome,
    required String modelo,
    required String ambiente,
    required String status,
    String? fabricante,
    String? numeroSerie,
    String? fornecedor,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final novoAtivo = await _apiService.createAtivo(
        codigo: codigo,
        nome: nome,
        modelo: modelo,
        ambiente: ambiente,
        status: status,
        fabricante: fabricante,
        numeroSerie: numeroSerie,
        fornecedor: fornecedor,
      );
      
      _ativos.insert(0, novoAtivo);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao criar ativo: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== ATUALIZAR ATIVO ==========
  
  Future<bool> updateAtivo({
    required int id,
    String? codigo,
    String? nome,
    String? modelo,
    String? ambiente,
    String? status,
    String? fabricante,
    String? numeroSerie,
    String? fornecedor,
  }) async {
    try {
      final ativoAtualizado = await _apiService.updateAtivo(
        id: id,
        codigo: codigo,
        nome: nome,
        modelo: modelo,
        ambiente: ambiente,
        status: status,
        fabricante: fabricante,
        numeroSerie: numeroSerie,
        fornecedor: fornecedor,
      );
      
      final index = _ativos.indexWhere((a) => a.id == id);
      if (index != -1) {
        _ativos[index] = ativoAtualizado;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = 'Erro ao atualizar ativo: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}