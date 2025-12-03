// lib/models/ativo.dart
class Ativo {
  final int id;
  final String codigo;
  final String nome;
  final String modelo;
  final String? fabricante;
  final String? numeroSerie;
  final String? fornecedor;
  final String ambiente;
  final String status;
  final DateTime dataCadastro;
  final DateTime dataAtualizacao;
  final List<AtivoHistorico> historicoMovimentacoes;
  final int totalChamados;
  final int chamadosAbertos;
  final UltimoChamado? ultimoChamado;

  Ativo({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.modelo,
    this.fabricante,
    this.numeroSerie,
    this.fornecedor,
    required this.ambiente,
    required this.status,
    required this.dataCadastro,
    required this.dataAtualizacao,
    this.historicoMovimentacoes = const [],
    this.totalChamados = 0,
    this.chamadosAbertos = 0,
    this.ultimoChamado,
  });

  
  factory Ativo.fromJson(Map<String, dynamic> json) {
    return Ativo(
      id: _parseInt(json['id']),
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      modelo: json['modelo']?.toString() ?? '',
      fabricante: json['fabricante']?.toString(),
      numeroSerie: json['numero_serie']?.toString(),
      fornecedor: json['fornecedor']?.toString(),
      ambiente: json['ambiente']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      dataCadastro: _parseDateTime(json['data_cadastro']),
      dataAtualizacao: _parseDateTime(json['data_atualizacao']),
      historicoMovimentacoes: _parseHistorico(json['historico_movimentacoes']),
      totalChamados: _parseInt(json['total_chamados']),
      chamadosAbertos: _parseInt(json['chamados_abertos']),
      ultimoChamado: json['ultimo_chamado'] != null
          ? UltimoChamado.fromJson(json['ultimo_chamado'])
          : null,
    );
  }

  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  
  static List<AtivoHistorico> _parseHistorico(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];
    
    try {
      return value
          .map((h) => AtivoHistorico.fromJson(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erro ao converter histórico: $e');
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nome': nome,
      'modelo': modelo,
      'fabricante': fabricante,
      'numero_serie': numeroSerie,
      'fornecedor': fornecedor,
      'ambiente': ambiente,
      'status': status,
    };
  }
}

class AtivoHistorico {
  final int id;
  final String tipo;
  final String descricao;
  final String? usuarioNome;
  final DateTime dataCriacao;

  AtivoHistorico({
    required this.id,
    required this.tipo,
    required this.descricao,
    this.usuarioNome,
    required this.dataCriacao,
  });

  factory AtivoHistorico.fromJson(Map<String, dynamic> json) {
    return AtivoHistorico(
      id: Ativo._parseInt(json['id']),
      tipo: json['tipo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      usuarioNome: json['usuario_nome']?.toString(),
      dataCriacao: Ativo._parseDateTime(json['data_criacao']),
    );
  }
}

class UltimoChamado {
  final String id; 
  final String titulo;
  final String status;
  final String data;

  UltimoChamado({
    required this.id,
    required this.titulo,
    required this.status,
    required this.data,
  });

  factory UltimoChamado.fromJson(Map<String, dynamic> json) {
    return UltimoChamado(
      id: json['id']?.toString() ?? '0',
      titulo: json['titulo']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      data: json['data']?.toString() ?? '',
    );
  }
}