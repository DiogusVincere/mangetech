import 'dart:io'; // ADICIONE ESTE IMPORT
import 'package:flutter/material.dart';
import '../../data/api/api_service.dart';
import '../../models/chamado.dart';

class ChamadoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Chamado> _chamados = [];
  bool _isLoading = false;
  String? _error;

  // NOVO: Filtros ativos
  Map<String, dynamic> _filtrosAtivos = {};
  Map<String, dynamic>? _estatisticasFiltradas;

  List<Chamado> get chamados => _chamados;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get filtrosAtivos => _filtrosAtivos;
  Map<String, dynamic>? get estatisticasFiltradas => _estatisticasFiltradas;

  // NOVO: Verificar se há filtros ativos
  bool get hasFiltrosAtivos => _filtrosAtivos.isNotEmpty;

  // NOVO: Contar filtros ativos
  int get totalFiltrosAtivos {
    int count = 0;
    if (_filtrosAtivos['status'] != null) count++;
    if (_filtrosAtivos['urgencia'] != null) count++;
    if (_filtrosAtivos['ambiente'] != null) count++;
    if (_filtrosAtivos['data_inicio'] != null) count++;
    if (_filtrosAtivos['data_fim'] != null) count++;
    if (_filtrosAtivos['meus_chamados'] == 'true') count++;
    return count;
  }

  // ========== CARREGAR CHAMADOS COM FILTROS ==========

  Future<void> fetchChamados({
    String? status,
    String? urgencia,
    String? search,
    Map<String, dynamic>? filtros,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Se filtros forem passados, salva como filtros ativos
      if (filtros != null) {
        _filtrosAtivos = filtros;
      } else {
        // Senão, usa os parâmetros individuais (para compatibilidade)
        _filtrosAtivos = {};
        if (status != null) _filtrosAtivos['status'] = status;
        if (urgencia != null) _filtrosAtivos['urgencia'] = urgencia;
        if (search != null) _filtrosAtivos['search'] = search;
      }

      _chamados = await _apiService.getChamados(
        status: _filtrosAtivos['status'],
        urgencia: _filtrosAtivos['urgencia'],
        search: _filtrosAtivos['search'],
        ambiente: _filtrosAtivos['ambiente'],
        solicitante: _filtrosAtivos['solicitante'],
        responsavel: _filtrosAtivos['responsavel'],
        dataInicio: _filtrosAtivos['data_inicio'],
        dataFim: _filtrosAtivos['data_fim'],
        meusChamados: _filtrosAtivos['meus_chamados'] == 'true',
        ordering: _filtrosAtivos['ordering'],
        filtrosAdicionais: _filtrosAtivos,
      );

      // Carregar estatísticas filtradas
      await _carregarEstatisticasFiltradas();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar chamados: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // NOVO: Carregar estatísticas com base nos filtros ativos
  Future<void> _carregarEstatisticasFiltradas() async {
    try {
      if (_filtrosAtivos.isNotEmpty) {
        _estatisticasFiltradas = await _apiService.getEstatisticasFiltradas(
          filtros: _filtrosAtivos,
        );
      }
    } catch (e) {
      print('Erro ao carregar estatísticas filtradas: $e');
    }
  }

  // NOVO: Aplicar filtros
  Future<void> aplicarFiltros(Map<String, dynamic> filtros) async {
    await fetchChamados(filtros: filtros);
  }

  // NOVO: Limpar filtros
  Future<void> limparFiltros() async {
    _filtrosAtivos = {};
    _estatisticasFiltradas = null;
    await fetchChamados();
  }

  // ========== BUSCAR CHAMADO POR ID ==========

  Chamado? getChamadoById(String id) {
    try {
      return _chamados.firstWhere((c) => c.id == id);
    } catch (e) {
      print('Chamado não encontrado: $id');
      return null;
    }
  }

  Future<Chamado?> fetchChamadoById(String id) async {
    try {
      final chamado = await _apiService.getChamadoById(id);

      final index = _chamados.indexWhere((c) => c.id == id);
      if (index != -1) {
        _chamados[index] = chamado;
        notifyListeners();
      }

      return chamado;
    } catch (e) {
      _error = 'Erro ao carregar chamado: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // ========== CRIAR CHAMADO ==========

  Future<bool> createChamado({
    required String titulo,
    required String descricao,
    required String ativo,
    required String ambiente,
    required String urgencia,
    String? dataSugerida,
    List<int>? responsaveis,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final novoChamado = await _apiService.createChamado(
        titulo: titulo,
        descricao: descricao,
        ativo: ativo,
        ambiente: ambiente,
        urgencia: urgencia,
        dataSugerida: dataSugerida,
        responsaveis: responsaveis,
      );

      _chamados.insert(0, novoChamado);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao criar chamado: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== ATUALIZAR CHAMADO ==========

  Future<bool> updateChamado({
    required String chamadoId,
    String? titulo,
    String? descricao,
    String? ativo,
    String? ambiente,
    String? urgencia,
    String? status,
    String? dataSugerida,
    List<int>? responsaveis,
  }) async {
    try {
      final chamadoAtualizado = await _apiService.updateChamado(
        id: chamadoId,
        titulo: titulo,
        descricao: descricao,
        ativo: ativo,
        ambiente: ambiente,
        urgencia: urgencia,
        status: status,
        dataSugerida: dataSugerida,
        responsaveis: responsaveis,
      );

      final index = _chamados.indexWhere((c) => c.id == chamadoId);
      if (index != -1) {
        _chamados[index] = chamadoAtualizado;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = 'Erro ao atualizar chamado: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ========== MUDAR STATUS ==========

  Future<bool> mudarStatus({
    required String chamadoId,
    required String novoStatus,
    required String descricao,
  }) async {
    try {
      await _apiService.mudarStatus(
        chamadoId: chamadoId,
        novoStatus: novoStatus,
        descricao: descricao,
      );

      await fetchChamadoById(chamadoId);

      return true;
    } catch (e) {
      _error = 'Erro ao mudar status: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ========== ADICIONAR COMENTÁRIO ==========

  // CORRIGIDO: Adicionar comentário com anexos
  Future<bool> adicionarComentario({
    required String chamadoId,
    required String texto,
    List<File>? anexos, // PARÂMETRO ADICIONADO
  }) async {
    try {
      print('📝 Adicionando comentário ao chamado $chamadoId');
      print('📎 Anexos: ${anexos?.length ?? 0}');

      await _apiService.adicionarComentario(
        chamadoId: chamadoId,
        texto: texto,
        anexos: anexos, // PASSANDO ANEXOS
      );

      print('Comentário adicionado, recarregando chamado...');

      await fetchChamadoById(chamadoId);

      return true;
    } catch (e) {
      print('Erro ao adicionar comentário: $e');
      _error = 'Erro ao adicionar comentário: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ========== ESTATÍSTICAS ==========

  Future<Map<String, dynamic>?> getEstatisticas() async {
    try {
      return await _apiService.getEstatisticas();
    } catch (e) {
      _error = 'Erro ao carregar estatísticas: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // ========== FILTROS LOCAIS ==========

  List<Chamado> filterByStatus(String status) {
    return _chamados
        .where((c) => c.status.toUpperCase() == status.toUpperCase())
        .toList();
  }

  List<Chamado> filterByUrgencia(String urgencia) {
    return _chamados.where((c) => c.prioridade == urgencia).toList();
  }

  List<Chamado> searchChamados(String query) {
    if (query.isEmpty) return _chamados;

    final lowerQuery = query.toLowerCase();
    return _chamados.where((c) {
      return c.titulo.toLowerCase().contains(lowerQuery) ||
          c.descricao.toLowerCase().contains(lowerQuery) ||
          c.id.toLowerCase().contains(lowerQuery) ||
          c.ativo.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // ========== LIMPAR ERROS ==========

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
