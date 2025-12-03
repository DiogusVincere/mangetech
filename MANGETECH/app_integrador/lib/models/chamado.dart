class Chamado {
  final String id; 
  final String titulo;
  final String descricao;
  final String status;
  final String prioridade; // urgencia no backend
  final String ambiente;
  final String ativo;
  final String solicitante;
  final String? solicitanteEmail;
  final List<String> responsaveis;
  final List<ResponsavelDetalhes> responsaveisDetalhes;
  final DateTime dataCriacao;
  final DateTime? dataSugerida;
  final DateTime dataAtualizacao;
  final List<ChamadoAnexo> anexos;
  final List<ChamadoStatusHistory> historico;
  final List<Comentario> comentarios;

  Chamado({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.status,
    required this.prioridade,
    required this.ambiente,
    required this.ativo,
    required this.solicitante,
    this.solicitanteEmail,
    this.responsaveis = const [],
    this.responsaveisDetalhes = const [],
    required this.dataCriacao,
    this.dataSugerida,
    required this.dataAtualizacao,
    this.anexos = const [],
    this.historico = const [],
    this.comentarios = const [],
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id']?.toString() ?? '', 
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      status: json['status'] ?? '',
      prioridade: json['urgencia'] ?? json['prioridade'] ?? '',
      ambiente: json['ambiente'] ?? '',
      ativo: json['ativo'] ?? '',
      solicitante: json['solicitante_nome'] ?? json['solicitante'] ?? '',
      solicitanteEmail: json['solicitante_email'],
      responsaveis: (json['responsaveis_nomes'] as List?)?.cast<String>() ?? [],
      responsaveisDetalhes: (json['responsaveis_detalhes'] as List?)
          ?.map((r) => ResponsavelDetalhes.fromJson(r))
          .toList() ?? [],
      dataCriacao: _parseDate(json['data_criacao']),
      dataSugerida: json['data_sugerida'] != null 
          ? _parseDate(json['data_sugerida']) 
          : null,
      dataAtualizacao: _parseDate(json['data_atualizacao']),
      anexos: (json['anexos_detalhes'] as List?)
          ?.map((a) => ChamadoAnexo.fromJson(a))
          .toList() ?? [],
      historico: (json['historico'] as List?)
          ?.map((h) => ChamadoStatusHistory.fromJson(h))
          .toList() ?? [],
      comentarios: (json['comentarios'] as List?)
          ?.map((c) => Comentario.fromJson(c))
          .toList() ?? [],
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'status': status,
      'urgencia': prioridade,
      'ambiente': ambiente,
      'ativo': ativo,
      'data_sugerida': dataSugerida?.toIso8601String(),
    };
  }

  Chamado copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? status,
    String? prioridade,
    String? ambiente,
    String? ativo,
    String? solicitante,
    List<String>? responsaveis,
    List<ResponsavelDetalhes>? responsaveisDetalhes,
    DateTime? dataCriacao,
    DateTime? dataSugerida,
    List<ChamadoAnexo>? anexos,
    List<ChamadoStatusHistory>? historico,
    List<Comentario>? comentarios,
  }) {
    return Chamado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
      prioridade: prioridade ?? this.prioridade,
      ambiente: ambiente ?? this.ambiente,
      ativo: ativo ?? this.ativo,
      solicitante: solicitante ?? this.solicitante,
      solicitanteEmail: this.solicitanteEmail,
      responsaveis: responsaveis ?? this.responsaveis,
      responsaveisDetalhes: responsaveisDetalhes ?? this.responsaveisDetalhes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataSugerida: dataSugerida ?? this.dataSugerida,
      dataAtualizacao: this.dataAtualizacao,
      anexos: anexos ?? this.anexos,
      historico: historico ?? this.historico,
      comentarios: comentarios ?? this.comentarios,
    );
  }
}

class ResponsavelDetalhes {
  final int id;
  final String username;
  final String email;
  final String nome;

  ResponsavelDetalhes({
    required this.id,
    required this.username,
    required this.email,
    required this.nome,
  });

  factory ResponsavelDetalhes.fromJson(Map<String, dynamic> json) {
    return ResponsavelDetalhes(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'] ?? json['username'] ?? '',
    );
  }
}

class ChamadoStatusHistory {
  final int id;
  final String status;
  final String descricao;
  final String usuario;
  final DateTime timestamp;
  final List<String> fotos;

  ChamadoStatusHistory({
    required this.id,
    required this.status,
    required this.descricao,
    required this.usuario,
    required this.timestamp,
    this.fotos = const [],
  });

  factory ChamadoStatusHistory.fromJson(Map<String, dynamic> json) {
    return ChamadoStatusHistory(
      id: json['id'] ?? 0,
      status: json['status'] ?? '',
      descricao: json['descricao'] ?? '',
      usuario: json['usuario_nome'] ?? json['usuario'] ?? 'Sistema',
      timestamp: DateTime.parse(json['timestamp'] ?? json['data_criacao']),
      fotos: (json['fotos'] as List?)
          ?.map((f) => f['url']?.toString() ?? '')
          .toList() ?? [],
    );
  }
}

class ChamadoAnexo {
  final int id;
  final String url;
  final String nomeOriginal;
  final DateTime dataUpload;

  ChamadoAnexo({
    required this.id,
    required this.url,
    required this.nomeOriginal,
    required this.dataUpload,
  });

  factory ChamadoAnexo.fromJson(Map<String, dynamic> json) {
    return ChamadoAnexo(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      nomeOriginal: json['nome_original'] ?? '',
      dataUpload: DateTime.parse(json['data_upload']),
    );
  }
}

class Comentario {
  final int id;
  final String usuario;
  final String texto;
  final DateTime timestamp;

  Comentario({
    required this.id,
    required this.usuario,
    required this.texto,
    required this.timestamp,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'] ?? 0,
      usuario: json['usuario_nome'] ?? json['autor'] ?? 'Anônimo',
      texto: json['texto'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? json['data_criacao']),
    );
  }
}