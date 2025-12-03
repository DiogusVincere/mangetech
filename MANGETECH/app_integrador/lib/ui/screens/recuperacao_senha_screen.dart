import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';

class RecuperacaoSenhaScreen extends StatefulWidget {
  const RecuperacaoSenhaScreen({Key? key}) : super(key: key);

  @override
  State<RecuperacaoSenhaScreen> createState() => _RecuperacaoSenhaScreenState();
}

class _RecuperacaoSenhaScreenState extends State<RecuperacaoSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNovaSenha = true;
  bool _obscureConfirmarSenha = true;

  // Estados de fluxo
  int _etapa = 1; // 1: Email, 2: Token, 3: Nova Senha
  String? _emailVerificado;
  int _tentativasRestantes = 5;
  int _tempoRestante = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _solicitarRecuperacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.recuperarSenha(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          setState(() {
            _etapa = 2;
            _emailVerificado = _emailController.text.trim();
            _tempoRestante = 900; // 15 minutos em segundos
          });

          _iniciarContagem();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Código enviado! Verifique seu email (pode estar em SPAM)',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _mostrarErro(
            authProvider.error ?? 'Erro ao solicitar recuperação',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro: ${e.toString()}');
      }
    }
  }

  Future<void> _verificarToken() async {
    if (_tokenController.text.isEmpty) {
      _mostrarErro('Digite o código');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Aqui você precisa chamar a API para verificar o token
      // Por enquanto, vou simular
      final success = await _verificarTokenAPI();

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          setState(() => _etapa = 3);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código verificado! Crie sua nova senha'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _tentativasRestantes--;
            if (_tentativasRestantes <= 0) {
              _etapa = 1;
              _limparFormulario();
            }
          });

          _mostrarErro(
            _tentativasRestantes > 0
                ? 'Código inválido. $_tentativasRestantes tentativa(s) restante(s)'
                : 'Máximo de tentativas atingido. Solicite um novo código.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro: ${e.toString()}');
      }
    }
  }

  Future<void> _resetarSenha() async {
    if (!_formKey.currentState!.validate()) return;

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      _mostrarErro('Senhas não conferem');
      return;
    }

    if (_novaSenhaController.text.length < 6) {
      _mostrarErro('Senha deve ter no mínimo 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Chamar API para resetar senha
      final success = await _resetarSenhaAPI();

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha resetada com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } else {
          _mostrarErro('Erro ao resetar senha. Tente novamente.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErro('Erro: ${e.toString()}');
      }
    }
  }

  Future<bool> _verificarTokenAPI() async {
    // TODO: Implementar chamada à API
    // Por enquanto, validação básica
    return _tokenController.text.length == 6;
  }

  Future<bool> _resetarSenhaAPI() async {
    // TODO: Implementar chamada à API
    return true;
  }

  void _iniciarContagem() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _tempoRestante--;
        });
        
        if (_tempoRestante <= 0) {
          setState(() => _etapa = 1);
          _limparFormulario();
          return false;
        }
      }
      
      return true;
    });
  }

  void _limparFormulario() {
    _emailController.clear();
    _tokenController.clear();
    _novaSenhaController.clear();
    _confirmarSenhaController.clear();
    _emailVerificado = null;
    _tentativasRestantes = 5;
    _tempoRestante = 0;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatarTempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
        elevation: 0,
      ),
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
                    // Etapa 1: Email
                    if (_etapa == 1) ...[
                      const Icon(
                        Icons.email_outlined,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Recuperar Senha',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Digite seu email para receber um código de verificação',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'seu@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email é obrigatório';
                          }
                          if (!value.contains('@')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _solicitarRecuperacao,
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
                            : const Text('Enviar Código'),
                      ),
                    ],

                    // Etapa 2: Token
                    if (_etapa == 2) ...[
                      const Icon(
                        Icons.security_outlined,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Verificar Código',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Código enviado para $_emailVerificado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Timer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _tempoRestante < 300
                              ? Colors.red[50]
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tempoRestante < 300
                                ? Colors.red[200]!
                                : Colors.blue[200]!,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: _tempoRestante < 300
                                  ? Colors.red[700]
                                  : Colors.blue[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Válido por: ${_formatarTempo(_tempoRestante)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _tempoRestante < 300
                                    ? Colors.red[700]
                                    : Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Código de 6 dígitos',
                          prefixIcon: Icon(Icons.lock_outlined),
                          hintText: '000000',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !_isLoading,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          letterSpacing: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tentativas restantes: $_tentativasRestantes',
                        style: TextStyle(
                          fontSize: 12,
                          color: _tentativasRestantes <= 2
                              ? Colors.red
                              : Colors.grey[600],
                          fontWeight: _tentativasRestantes <= 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verificarToken,
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
                            : const Text('Verificar Código'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _etapa = 1;
                            _limparFormulario();
                          });
                        },
                        child: const Text('Voltar'),
                      ),
                    ],

                    // Etapa 3: Nova Senha
                    if (_etapa == 3) ...[
                      const Icon(
                        Icons.vpn_key_outlined,
                        size: 64,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Nova Senha',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Digite uma nova senha segura',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _novaSenhaController,
                        decoration: InputDecoration(
                          labelText: 'Nova Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNovaSenha
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscureNovaSenha = !_obscureNovaSenha,
                              );
                            },
                          ),
                        ),
                        obscureText: _obscureNovaSenha,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Senha é obrigatória';
                          }
                          if (value.length < 6) {
                            return 'Senha deve ter no mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmarSenhaController,
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmarSenha
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    _obscureConfirmarSenha =
                                        !_obscureConfirmarSenha,
                              );
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmarSenha,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirmação é obrigatória';
                          }
                          if (value != _novaSenhaController.text) {
                            return 'Senhas não conferem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _resetarSenha,
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
                            : const Text('Resetar Senha'),
                      ),
                    ],

                    // Link para login
                    if (_etapa == 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lembrou a senha?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                            child: const Text('Voltar ao login'),
                          ),
                        ],
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