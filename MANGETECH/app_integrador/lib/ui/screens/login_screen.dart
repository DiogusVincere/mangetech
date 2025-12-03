import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/api/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isTestingConnection = true;
  bool? _isConnected;
  String _connectionMessage = 'Verificando conexão com o servidor...';

  @override
  void initState() {
    super.initState();
    _testConnectionOnInit();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnectionOnInit() async {
    setState(() {
      _isTestingConnection = true;
      _connectionMessage = 'Verificando conexão com o servidor...';
    });

    try {
      final isConnected = await _apiService.testConnection();
      
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _isConnected = isConnected;
          _connectionMessage = isConnected
              ? 'Conectado ao servidor ✓'
              : 'Erro ao conectar com o servidor';
        });

        if (!isConnected) {
          _showConnectionErrorDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _isConnected = false;
          _connectionMessage = 'Erro de conexão';
        });
        _showConnectionErrorDialog();
      }
    }
  }

  void _showConnectionErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            const Text('Erro de Conexão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Não foi possível conectar ao servidor Django.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Servidor: ${ApiService.baseUrl}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verifique se:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildCheckItem('Django está rodando'),
            _buildCheckItem('Comando: python manage.py runserver 0.0.0.0:8000'),
            _buildCheckItem('IP está correto no código'),
            _buildCheckItem('Firewall liberado na porta 8000'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _testConnectionOnInit();
            },
            child: const Text('Tentar Novamente'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Permitir continuar mesmo sem conexão (para desenvolvimento)
            },
            child: const Text('Continuar Assim Mesmo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        email: _emailController.text.trim(),
        senha: _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          _mostrarMensagem(
            authProvider.error ?? 'Erro ao fazer login',
            isError: true,
          );
        }
      }
    }
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Icon
                    const Icon(
                      Icons.assessment_outlined,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 24),

                    // Título
                    const Text(
                      'Entrar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acesse sua conta para gerenciar chamados',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Status de Conexão
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isTestingConnection
                            ? Colors.blue[50]
                            : _isConnected == true
                                ? Colors.green[50]
                                : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isTestingConnection
                              ? Colors.blue[200]!
                              : _isConnected == true
                                  ? Colors.green[200]!
                                  : Colors.red[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isTestingConnection)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              _isConnected == true
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 16,
                              color: _isConnected == true
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _connectionMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isTestingConnection
                                    ? Colors.blue[700]
                                    : _isConnected == true
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (!_isTestingConnection && _isConnected != true)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _testConnectionOnInit,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'seu@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enabled: !_isTestingConnection,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu email';
                        }
                        if (!value.contains('@')) {
                          return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Senha
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      enabled: !_isTestingConnection,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Link Esqueci a senha
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isTestingConnection
                            ? null
                            : () {
                                Navigator.of(context).pushNamed('/esqueci-senha');
                              },
                        child: const Text('Esqueci a senha'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Entrar
                    ElevatedButton(
                      onPressed:
                          _isLoading || _isTestingConnection ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 16),

                    // Link Criar conta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem uma conta?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _isTestingConnection
                              ? null
                              : () {
                                  Navigator.of(context).pushNamed('/cadastro');
                                },
                          child: const Text(
                            'Criar conta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Informação de Debug (apenas desenvolvimento)
                    if (!_isTestingConnection && _isConnected != true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  'Informações de Debug',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'URL: ${ApiService.baseUrl}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}