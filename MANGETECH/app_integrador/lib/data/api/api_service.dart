import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/chamado.dart';
import '../../models/ativo.dart';

class ApiService {
  // ========== CONFIGURAÇÃO DA API ==========
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const Duration timeout = Duration(seconds: 30);

  // ========== HEADERS ==========

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  Future<Map<String, String>> _getHeadersMultipart({bool includeAuth = true}) async {
    final headers = <String, String>{};

    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ========== TRATAMENTO DE ERROS ==========

  dynamic _handleResponse(http.Response response) {
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return json.decode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 400) {
      final error = json.decode(utf8.decode(response.bodyBytes));
      throw Exception(_formatErrorMessage(error));
    } else if (response.statusCode == 401) {
      throw Exception('Não autorizado. Faça login novamente.');
    } else if (response.statusCode == 403) {
      throw Exception('Acesso negado.');
    } else if (response.statusCode == 404) {
      throw Exception('Recurso não encontrado.');
    } else if (response.statusCode == 500) {
      throw Exception('Erro no servidor. Tente novamente mais tarde.');
    } else {
      throw Exception('Erro: ${response.statusCode}');
    }
  }

  String _formatErrorMessage(dynamic error) {
    if (error is Map) {
      if (error.containsKey('message')) return error['message'];
      if (error.containsKey('error')) return error['error'];
      if (error.containsKey('errors')) {
        final errors = error['errors'];
        if (errors is Map) return errors.values.first.toString();
        return errors.toString();
      }

      final errorMessages = <String>[];
      error.forEach((key, value) {
        if (value is List) {
          errorMessages.add('$key: ${value.join(", ")}');
        } else {
          errorMessages.add('$key: $value');
        }
      });
      return errorMessages.join('\n');
    }
    return error.toString();
  }

  // ========== AUTENTICAÇÃO ==========

  Future<Map<String, dynamic>> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register/'),
            headers: await _getHeaders(includeAuth: false),
            body: json.encode({
              'nome': nome,
              'email': email,
              'senha': senha,
            }),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      if (data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } catch (e) {
      throw Exception('Erro ao registrar: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: await _getHeaders(includeAuth: false),
            body: json.encode({
              'email': email,
              'senha': senha,
            }),
          )
          .timeout(timeout);

      final data = _handleResponse(response);

      if (data['success'] == true && data['token'] != null) {
        await _saveToken(data['token']);
      }
      return data;
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/auth/logout/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);
    } finally {
      await _removeToken();
    }
  }

  Future<Map<String, dynamic>> recuperarSenha({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/recuperar-senha/'),
            headers: await _getHeaders(includeAuth: false),
            body: json.encode({'email': email}),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao recuperar senha: $e');
    }
  }

  // ========== CHAMADOS COM FILTROS AVANÇADOS ==========

  Future<List<Chamado>> getChamados({
    String? status,
    String? urgencia,
    String? search,
    String? ambiente,
    String? solicitante,
    String? responsavel,
    String? dataInicio,
    String? dataFim,
    bool? meusChamados,
    String? ordering,
    Map<String, dynamic>? filtrosAdicionais,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/chamados/');

      final queryParams = <String, String>{};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (urgencia != null && urgencia.isNotEmpty) queryParams['urgencia'] = urgencia;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ambiente != null && ambiente.isNotEmpty) queryParams['ambiente'] = ambiente;
      if (solicitante != null) queryParams['solicitante'] = solicitante;
      if (responsavel != null) queryParams['responsavel'] = responsavel;
      if (dataInicio != null) queryParams['data_inicio'] = dataInicio;
      if (dataFim != null) queryParams['data_fim'] = dataFim;
      if (meusChamados == true) queryParams['meus_chamados'] = 'true';
      if (ordering != null) queryParams['ordering'] = ordering;

      if (filtrosAdicionais != null) {
        filtrosAdicionais.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            queryParams[key] = value.toString();
          }
        });
      }

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('Buscando chamados: $uri');

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(timeout);

      final data = _handleResponse(response);
      final results = data['results'] ?? data;

      print('Retornados ${(results as List).length} chamados');

      return (results as List).map((json) => Chamado.fromJson(json)).toList();
    } catch (e) {
      print('❌ Erro ao carregar chamados: $e');
      throw Exception('Erro ao carregar chamados: $e');
    }
  }

  Future<Map<String, dynamic>> getEstatisticasFiltradas({
    Map<String, dynamic>? filtros,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/chamados/estatisticas_filtradas/');

      if (filtros != null && filtros.isNotEmpty) {
        final queryParams = <String, String>{};
        filtros.forEach((key, value) {
          if (value != null && value.toString().isNotEmpty) {
            queryParams[key] = value.toString();
          }
        });
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }

  Future<Chamado> getChamadoById(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/chamados/$id/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return Chamado.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao carregar chamado: $e');
    }
  }

  Future<Chamado> createChamado({
    required String titulo,
    required String descricao,
    required String ativo,
    required String ambiente,
    required String urgencia,
    String? dataSugerida,
    List<int>? responsaveis,
    List<File>? anexos,
  }) async {
    try {
      final body = {
        'titulo': titulo,
        'descricao': descricao,
        'ativo': ativo,
        'ambiente': ambiente,
        'urgencia': urgencia,
        'status': 'ABERTO',
        if (dataSugerida != null) 'data_sugerida': dataSugerida,
        if (responsaveis != null && responsaveis.isNotEmpty)
          'responsaveis': responsaveis,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/chamados/'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      final chamado = Chamado.fromJson(data);

      if (anexos != null && anexos.isNotEmpty) {
        for (var file in anexos) {
          await _uploadAnexo(chamado.id, file);
        }
      }

      return chamado;
    } catch (e) {
      throw Exception('Erro ao criar chamado: $e');
    }
  }

  Future<Chamado> updateChamado({
    required String id,
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
      final body = <String, dynamic>{};
      if (titulo != null) body['titulo'] = titulo;
      if (descricao != null) body['descricao'] = descricao;
      if (ativo != null) body['ativo'] = ativo;
      if (ambiente != null) body['ambiente'] = ambiente;
      if (urgencia != null) body['urgencia'] = urgencia;
      if (status != null) body['status'] = status;
      if (dataSugerida != null) body['data_sugerida'] = dataSugerida;
      if (responsaveis != null) body['responsaveis'] = responsaveis;

      final response = await http
          .patch(
            Uri.parse('$baseUrl/chamados/$id/'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return Chamado.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao atualizar chamado: $e');
    }
  }

  Future<void> mudarStatus({
    required String chamadoId,
    required String novoStatus,
    required String descricao,
    List<File>? fotos,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/chamados/$chamadoId/mudar_status/'),
      );

      final headers = await _getHeadersMultipart();
      request.headers.addAll(headers);

      request.fields['status'] = novoStatus;
      request.fields['descricao'] = descricao;

      if (fotos != null) {
        for (var foto in fotos) {
          request.files.add(
            await http.MultipartFile.fromPath('fotos', foto.path),
          );
        }
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao mudar status: $e');
    }
  }

  Future<void> adicionarComentario({
    required String chamadoId,
    required String texto,
    List<File>? anexos,
  }) async {
    try {
      if (anexos == null || anexos.isEmpty) {
        final response = await http
            .post(
              Uri.parse('$baseUrl/chamados/$chamadoId/adicionar_comentario/'),
              headers: await _getHeaders(),
              body: json.encode({'texto': texto}),
            )
            .timeout(timeout);

        _handleResponse(response);
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/chamados/$chamadoId/adicionar_comentario/'),
      );

      final headers = await _getHeadersMultipart();
      request.headers.addAll(headers);

      request.fields['texto'] = texto;

      for (var anexo in anexos) {
        request.files.add(
          await http.MultipartFile.fromPath('anexos', anexo.path),
        );
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao adicionar comentário: $e');
    }
  }

  Future<void> _uploadAnexo(String chamadoId, File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/chamados/$chamadoId/adicionar_anexo/'),
      );

      final headers = await _getHeadersMultipart();
      request.headers.addAll(headers);

      request.files.add(
        await http.MultipartFile.fromPath('arquivo', file.path),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao fazer upload de anexo: $e');
    }
  }

  Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/chamados/estatisticas/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }

  // ========== ATIVOS ==========

  Future<List<Ativo>> getAtivos({String? search}) async {
    try {
      var uri = Uri.parse('$baseUrl/ativos/');

      if (search != null && search.isNotEmpty) {
        uri = uri.replace(queryParameters: {'search': search});
      }

      print('GET $uri');

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(timeout);

      print('Status: ${response.statusCode}');

      final data = _handleResponse(response);

      List<dynamic> ativosList = [];

      if (data is List) {
        ativosList = data;
      } else if (data is Map) {
        if (data.containsKey('results')) {
          ativosList = data['results'] as List;
        } else if (data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is List) {
            ativosList = dataContent;
          } else if (dataContent is Map && dataContent.containsKey('results')) {
            ativosList = dataContent['results'] as List;
          }
        } else {
          ativosList = [data];
        }
      }

      print('Total de ativos: ${ativosList.length}');

      if (ativosList.isEmpty) {
        print('Lista vazia retornada');
        return [];
      }

      final ativos = <Ativo>[];

      for (var i = 0; i < ativosList.length; i++) {
        try {
          final ativoMap = Map<String, dynamic>.from(ativosList[i] as Map);
          final ativo = Ativo.fromJson(ativoMap);
          ativos.add(ativo);
        } catch (e) {
          print('❌ Erro ao converter ativo [$i]: $e');
        }
      }

      print('Ativos convertidos: ${ativos.length}');
      return ativos;
    } catch (e) {
      print('❌ Erro ao carregar ativos: $e');
      throw Exception('Erro ao carregar ativos: $e');
    }
  }

  /// 🆕 Retorna ativos como List<Map<String, dynamic>> para uso em dropdowns
  Future<List<Map<String, dynamic>>> getAtivosMap({String? search}) async {
    try {
      var uri = Uri.parse('$baseUrl/ativos/');

      if (search != null && search.isNotEmpty) {
        uri = uri.replace(queryParameters: {'search': search});
      }

      print('GET $uri (getAtivosMap)');

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(timeout);

      print('Status: ${response.statusCode}');

      final data = _handleResponse(response);

      List<dynamic> ativosList = [];

      if (data is List) {
        ativosList = data;
      } else if (data is Map) {
        if (data.containsKey('results')) {
          ativosList = data['results'] as List;
        } else if (data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is List) {
            ativosList = dataContent;
          } else if (dataContent is Map && dataContent.containsKey('results')) {
            ativosList = dataContent['results'] as List;
          }
        }
      }

      print('Total de ativos: ${ativosList.length}');

      if (ativosList.isEmpty) {
        print('Lista vazia retornada');
        return [];
      }

      final ativos = <Map<String, dynamic>>[];

      for (var i = 0; i < ativosList.length; i++) {
        try {
          final ativoMap = Map<String, dynamic>.from(ativosList[i] as Map);
          
          if (ativoMap['id'] != null && 
              ativoMap['codigo'] != null && 
              ativoMap['nome'] != null) {
            ativos.add(ativoMap);
          }
        } catch (e) {
          print('❌ Erro ao processar ativo [$i]: $e');
        }
      }

      print('Ativos válidos: ${ativos.length}');
      
      if (ativos.isNotEmpty) {
        print('Exemplo: ${ativos.first}');
      }

      return ativos;
    } catch (e) {
      print('❌ Erro ao carregar ativos (Map): $e');
      return [];
    }
  }

  Future<Ativo> getAtivoByQRCode(String codigo) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/ativos/?search=$codigo'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      final results = data['results'] ?? data;

      if (results is List && results.isNotEmpty) {
        final ativoMap = Map<String, dynamic>.from(results[0] as Map);

        if (ativoMap['id'] is String) {
          ativoMap['id'] = int.tryParse(ativoMap['id']) ?? 0;
        }
        if (ativoMap['total_chamados'] is String) {
          ativoMap['total_chamados'] = int.tryParse(ativoMap['total_chamados']) ?? 0;
        }
        if (ativoMap['chamados_abertos'] is String) {
          ativoMap['chamados_abertos'] = int.tryParse(ativoMap['chamados_abertos']) ?? 0;
        }

        return Ativo.fromJson(ativoMap);
      } else {
        throw Exception('Ativo não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar ativo: $e');
    }
  }

  Future<Ativo> createAtivo({
    required String codigo,
    required String nome,
    required String modelo,
    required String ambiente,
    required String status,
    String? fabricante,
    String? numeroSerie,
    String? fornecedor,
  }) async {
    try {
      final body = {
        'codigo': codigo,
        'nome': nome,
        'modelo': modelo,
        'ambiente': ambiente,
        'status': status,
        if (fabricante != null && fabricante.isNotEmpty) 'fabricante': fabricante,
        if (numeroSerie != null && numeroSerie.isNotEmpty) 'numero_serie': numeroSerie,
        if (fornecedor != null && fornecedor.isNotEmpty) 'fornecedor': fornecedor,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/ativos/'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return Ativo.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao criar ativo: $e');
    }
  }

  Future<Ativo> updateAtivo({
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
      final body = <String, dynamic>{};
      if (codigo != null) body['codigo'] = codigo;
      if (nome != null) body['nome'] = nome;
      if (modelo != null) body['modelo'] = modelo;
      if (ambiente != null) body['ambiente'] = ambiente;
      if (status != null) body['status'] = status;
      if (fabricante != null) body['fabricante'] = fabricante;
      if (numeroSerie != null) body['numero_serie'] = numeroSerie;
      if (fornecedor != null) body['fornecedor'] = fornecedor;

      final response = await http
          .patch(
            Uri.parse('$baseUrl/ativos/$id/'),
            headers: await _getHeaders(),
            body: json.encode(body),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return Ativo.fromJson(data);
    } catch (e) {
      throw Exception('Erro ao atualizar ativo: $e');
    }
  }

  // ========== DASHBOARD GERENCIAL ==========

  Future<Map<String, dynamic>> getDashboardGerencial() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard/gerencial/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return data['data'] ?? data;
    } catch (e) {
      throw Exception('Erro ao carregar dashboard: $e');
    }
  }

  // ========== USUÁRIOS ==========

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/usuarios/me/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);
      return data['user'] ?? {};
    } catch (e) {
      throw Exception('Erro ao carregar perfil: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers({String? search}) async {
    try {
      print('Buscando usuários...');

      var uri = Uri.parse('$baseUrl/usuarios/');

      if (search != null && search.isNotEmpty) {
        uri = uri.replace(queryParameters: {'search': search});
      }

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(timeout);

      print('Resposta: ${response.statusCode}');

      final data = _handleResponse(response);

      List<dynamic> usersList = [];

      if (data is List) {
        usersList = data;
      } else if (data is Map) {
        if (data.containsKey('results')) {
          usersList = data['results'] as List;
        } else if (data.containsKey('data')) {
          final dataContent = data['data'];
          if (dataContent is List) {
            usersList = dataContent;
          } else if (dataContent is Map && dataContent.containsKey('results')) {
            usersList = dataContent['results'] as List;
          }
        }
      }

      print('Total usuários: ${usersList.length}');

      if (usersList.isEmpty) {
        return [];
      }

      return usersList
          .map((user) => Map<String, dynamic>.from(user as Map))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar usuários: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/usuarios/$userId/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);

      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }

      return data;
    } catch (e) {
      print('❌ Erro ao buscar usuário: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/usuarios/$userId/estatisticas/'),
            headers: await _getHeaders(),
          )
          .timeout(timeout);

      final data = _handleResponse(response);

      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }

      return data;
    } catch (e) {
      print('❌ Erro ao buscar estatísticas: $e');
      rethrow;
    }
  }

  // ========== TESTE DE CONEXÃO ==========

  Future<bool> testConnection() async {
    try {
      print('Testando conexão: $baseUrl');
      
      final response = await http
          .get(Uri.parse('$baseUrl/chamados/'))
          .timeout(const Duration(seconds: 5));

      print('Status: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      print('❌ Erro ao testar conexão: $e');
      return false;
    }
  }
}