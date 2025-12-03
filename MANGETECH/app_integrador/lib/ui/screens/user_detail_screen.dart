import 'package:flutter/material.dart';
import '../../data/api/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  bool _statsLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await _apiService.getUserById(widget.userId);
      
      if (mounted) {
        setState(() {
          _user = userData;
          _isLoading = false;
        });
        
        // Carregar estatísticas em paralelo
        _loadUserStats();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserStats() async {
    setState(() => _statsLoading = true);

    try {
      final statsData = await _apiService.getUserStatistics(widget.userId);
      
      if (mounted) {
        setState(() {
          _stats = statsData;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {
            'total_chamados': 0,
            'chamados_solicitados': 0,
            'chamados_responsavel': 0,
            'chamados_ativos': 0,
            'por_status': [],
            'por_urgencia': [],
          };
          _statsLoading = false;
        });
      }
    }
  }

  String _getFullName() {
    if (_user == null) return '';
    final firstName = _user!['first_name'] ?? '';
    final lastName = _user!['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? _user!['username'] : fullName;
  }

  String _getInitials() {
    if (_user == null) return 'U';
    final firstName = _user!['first_name'] ?? '';
    final lastName = _user!['last_name'] ?? '';
    
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (firstName.isNotEmpty) {
      return firstName.substring(0, firstName.length > 1 ? 2 : 1).toUpperCase();
    }
    final username = _user!['username'] ?? 'U';
    return username.substring(0, username.length > 1 ? 2 : 1).toUpperCase();
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('aberto')) return Colors.blue;
    if (statusLower.contains('andamento')) return Colors.orange;
    if (statusLower.contains('concluido') || statusLower.contains('concluído')) return Colors.green;
    if (statusLower.contains('cancelado')) return Colors.red;
    return Colors.grey;
  }

  Color _getPriorityColor(String priority) {
    final priorityLower = priority.toLowerCase();
    if (priorityLower.contains('crítico') || priorityLower.contains('critico')) return Colors.red;
    if (priorityLower.contains('alta')) return Colors.orange;
    if (priorityLower.contains('média') || priorityLower.contains('media')) return Colors.yellow[700]!;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detalhes do Usuário'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando usuário...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erro ao carregar usuário',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('Usuário não encontrado'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFullName(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user!['email'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUserTypeBadge(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Estatísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estatísticas de Chamados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.bar_chart, color: Colors.grey[400]),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildStatsContent(),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Informações Pessoais
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações Pessoais',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nome Completo', _getFullName()),
                    _buildInfoRow('Username', _user!['username'] ?? '', mono: true),
                    _buildInfoRow('Email', _user!['email'] ?? ''),
                    _buildInfoRow('ID do Usuário', '#${_user!['id']}', mono: true),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Ações Rápidas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ações Rápidas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'Enviar Email',
                      Icons.email,
                      Colors.blue,
                      () {},
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      'Alterar Permissões',
                      Icons.shield,
                      Colors.grey,
                      () {},
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      'Resetar Senha',
                      Icons.key,
                      Colors.grey,
                      () {},
                    ),
                    const SizedBox(height: 8),
                    _buildActionButton(
                      'Desativar Conta',
                      Icons.block,
                      Colors.red,
                      () {},
                      outlined: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserTypeBadge() {
    if (_user!['is_superuser'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars, size: 14, color: Colors.red[800]),
            const SizedBox(width: 4),
            Text(
              'Super Admin',
              style: TextStyle(
                color: Colors.red[800],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_user!['is_staff'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield, size: 14, color: Colors.purple[800]),
            const SizedBox(width: 4),
            Text(
              'Administrador',
              style: TextStyle(
                color: Colors.purple[800],
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person, size: 14, color: Colors.blue[800]),
          const SizedBox(width: 4),
          Text(
            'Usuário',
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    if (_statsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_stats == null || _stats!['total_chamados'] == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text(
                'Nenhum chamado registrado',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Total',
                _stats!['total_chamados'].toString(),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Solicitados',
                _stats!['chamados_solicitados'].toString(),
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Responsável',
                _stats!['chamados_responsavel'].toString(),
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Ativos',
                _stats!['chamados_ativos'].toString(),
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18, color: color),
              label: Text(label, style: TextStyle(color: color)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: color),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: outlined ? Colors.white : color,
                foregroundColor: outlined ? color : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
    );
  }
}