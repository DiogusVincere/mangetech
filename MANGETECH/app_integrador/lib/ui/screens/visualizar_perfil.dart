import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/api/api_service.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() {
    debugPrint('🟢 PerfilScreen: createState() chamado');
    return _PerfilScreenState();
  }
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _estatisticas;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 PerfilScreen: initState() chamado');
    _loadProfileData();
  }

  @override
  void dispose() {
    debugPrint('🔴 PerfilScreen: dispose() chamado');
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    debugPrint('📥 _loadProfileData: Iniciando');
    
    if (!mounted) {
      debugPrint('_loadProfileData: Widget NÃO montado');
      return;
    }
    
    setState(() {
      debugPrint('📝 setState: loading=true');
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🌐 Chamando API...');
      final results = await Future.wait([
        _apiService.getUserProfile(),
        _apiService.getEstatisticas(),
      ]);

      debugPrint('API retornou dados');

      if (!mounted) {
        debugPrint('Widget desmontado após API');
        return;
      }

      setState(() {
        debugPrint('📝 setState: salvando dados');
        _profileData = results[0] as Map<String, dynamic>?;
        _estatisticas = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERRO: $e');
      
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditarPerfilDialog() {
    debugPrint('✏️ Abrindo dialog editar');
    
    final nomeController = TextEditingController(
      text: _profileData?['first_name']?.toString() ?? '',
    );
    final usuarioController = TextEditingController(
      text: _profileData?['username']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: _profileData?['email']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuário',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('❌ Cancelar pressionado');
              Navigator.pop(ctx);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('Salvar pressionado - mounted=$mounted');
              
              if (mounted) {
                debugPrint('📝 Chamando setState');
                setState(() {
                  if (_profileData != null) {
                    _profileData!['first_name'] = nomeController.text.trim();
                    _profileData!['username'] = usuarioController.text.trim();
                    _profileData!['email'] = emailController.text.trim();
                  }
                });
              }
              Navigator.pop(ctx);
              _showSnackBar('Perfil atualizado!');
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ).then((_) {
      nomeController.dispose();
      usuarioController.dispose();
      emailController.dispose();
    });
  }

  void _showNotificacoesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _NotificacoesDialog(),
    );
  }

  void _showAlterarSenhaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AlterarSenhaDialog(
        onSuccess: () => _showSnackBar('Senha alterada!'),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Logout'),
        content: const Text('Deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 build() chamado');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditarPerfilDialog,
          ),
        ],
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
            Text('Carregando...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(authProvider),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStatisticsCard(),
          const SizedBox(height: 16),
          _buildSettingsCard(),
          const SizedBox(height: 16),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                ),
              ),
              child: Center(
                child: Text(
                  authProvider.getInitials(),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(authProvider.userName ?? 'Usuário', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (authProvider.userEmail != null)
              Text(authProvider.userEmail!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informações Pessoais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Nome', _profileData?['first_name']?.toString() ?? 'N/A'),
            _buildInfoRow(Icons.email_outlined, 'Email', _profileData?['email']?.toString() ?? 'N/A'),
            _buildInfoRow(Icons.badge_outlined, 'Usuário', _profileData?['username']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    int total = 0, abertos = 0, andamento = 0, concluidos = 0;
    
    final porStatus = _estatisticas?['por_status'];
    if (porStatus is List) {
      for (var item in porStatus) {
        if (item == null) continue;
        final status = item['status']?.toString().toUpperCase() ?? '';
        final t = int.tryParse(item['total']?.toString() ?? '0') ?? 0;
        total += t;
        if (status == 'ABERTO') abertos = t;
        if (status.contains('ANDAMENTO')) andamento = t;
        if (status.contains('CONCLU')) concluidos = t;
      }
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estatísticas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Total', total.toString(), Icons.assessment, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Abertos', abertos.toString(), Icons.inbox, Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Andamento', andamento.toString(), Icons.hourglass_empty, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Concluídos', concluidos.toString(), Icons.check_circle, Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Configurações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined, color: AppTheme.primaryColor),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showNotificacoesDialog,
          ),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            title: const Text('Alterar Senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAlterarSenhaDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: _handleLogout,
      icon: const Icon(Icons.logout),
      label: const Text('Sair da Conta'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _NotificacoesDialog extends StatefulWidget {
  const _NotificacoesDialog();

  @override
  State<_NotificacoesDialog> createState() => _NotificacoesDialogState();
}

class _NotificacoesDialogState extends State<_NotificacoesDialog> {
  bool _chamados = true;
  bool _comentarios = true;
  bool _status = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notificações'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Novos Chamados'),
            value: _chamados,
            onChanged: (v) => setState(() => _chamados = v),
          ),
          SwitchListTile(
            title: const Text('Comentários'),
            value: _comentarios,
            onChanged: (v) => setState(() => _comentarios = v),
          ),
          SwitchListTile(
            title: const Text('Mudanças de Status'),
            value: _status,
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Preferências salvas!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _AlterarSenhaDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _AlterarSenhaDialog({required this.onSuccess});

  @override
  State<_AlterarSenhaDialog> createState() => _AlterarSenhaDialogState();
}

class _AlterarSenhaDialogState extends State<_AlterarSenhaDialog> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirma = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _obscure3 = true;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirma.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar Senha'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _atual,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: 'Senha Atual',
                suffixIcon: IconButton(
                  icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nova,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: 'Nova Senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirma,
              obscureText: _obscure3,
              decoration: InputDecoration(
                labelText: 'Confirmar Senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscure3 ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure3 = !_obscure3),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSuccess();
          },
          child: const Text('Alterar'),
        ),
      ],
    );
  }
}