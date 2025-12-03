import 'package:app_integrador/data/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get error => _error;

  // ========== INICIALIZAÇÃO ==========
  
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _isAuthenticated = true;
      
      // Carregar dados do usuário
      await loadUserProfile();
      
      notifyListeners();
    }
  }

  // ========== CADASTRO ==========
  
  Future<bool> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.register(
        nome: nome,
        email: email,
        senha: senha,
      );
      
      if (response['success'] == true) {
        _isAuthenticated = true;
        _userName = response['user']['first_name'] ?? nome;
        _userEmail = email;
        _userId = response['user']['id'].toString();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Erro ao criar conta';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao criar conta: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== LOGIN ==========
  
  Future<bool> login({
    required String email,
    required String senha,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(
        email: email,
        senha: senha,
      );
      
      if (response['success'] == true) {
        _isAuthenticated = true;
        
        // Extrair dados do usuário
        final user = response['user'];
        _userId = user['id'].toString();
        _userName = user['first_name'] ?? user['username'];
        _userEmail = user['email'];
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Email ou senha incorretos';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao fazer login: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== LOGOUT ==========
  
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      _isAuthenticated = false;
      _userId = null;
      _userName = null;
      _userEmail = null;
      _error = null;
      notifyListeners();
    }
  }

  // ========== RECUPERAR SENHA ==========
  
  Future<bool> recuperarSenha({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiService.recuperarSenha(email: email);
      
      _isLoading = false;
      notifyListeners();
      
      return response['success'] == true;
    } catch (e) {
      _error = 'Erro ao recuperar senha: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ========== CARREGAR PERFIL DO USUÁRIO ==========
  
  Future<void> loadUserProfile() async {
    try {
      final profile = await _apiService.getUserProfile();
      
      if (profile.isNotEmpty) {
        _userId = profile['id'].toString();
        _userName = profile['first_name'] ?? profile['username'];
        _userEmail = profile['email'];
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar perfil: $e');
    }
  }

  // ========== LIMPAR ERROS ==========
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ========== OBTER INICIAIS DO USUÁRIO ==========
  
  String getInitials() {
    if (_userName != null && _userName!.isNotEmpty) {
      final parts = _userName!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      if (parts[0].length >= 2) {
        return parts[0].substring(0, 2).toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}