import 'package:app_integrador/ui/screens/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/chamado_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../widgets/chamado_card.dart';
import 'criar_chamado_screen.dart';
import 'gestao_ativos_screen.dart';
import 'chamado_detalhe_screen.dart';
import 'filtros_chamados_screen.dart';
import 'dashboardgerencial_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChamados();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChamados() async {
    try {
      await Provider.of<ChamadoProvider>(context, listen: false).fetchChamados();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar chamados: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToDetail(String chamadoId) {
    final provider = Provider.of<ChamadoProvider>(context, listen: false);
    final chamado = provider.getChamadoById(chamadoId);
    
    if (chamado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chamado não encontrado'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChamadoDetailScreen(chamadoId: chamadoId),
      ),
    );
  }

  Future<void> _navigateToCriarChamado() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CriarChamadoScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadChamados();
    }
  }

  // Navegar para Dashboard Gerencial
  void _navigateToDashboardGerencial() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DashboardGerencialScreen(),
      ),
    );
  }

  Future<void> _abrirFiltros() async {
    final provider = Provider.of<ChamadoProvider>(context, listen: false);
    
    final filtros = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => FiltrosChamadosScreen(
          filtrosAtuais: provider.filtrosAtivos,
        ),
      ),
    );

    if (filtros != null && mounted) {
      await provider.aplicarFiltros(filtros);
    }
  }

  Future<void> _limparFiltros() async {
    final provider = Provider.of<ChamadoProvider>(context, listen: false);
    await provider.limparFiltros();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filtros limpos'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Sair',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chamadoProvider = Provider.of<ChamadoProvider>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
         
          // Botão Usuários
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Usuários',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UsersScreen(),
                ),
              );
            },
          ),
          
          // Botão de filtros com badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _abrirFiltros,
                tooltip: 'Filtros',
              ),
              if (chamadoProvider.hasFiltrosAtivos)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${chamadoProvider.totalFiltrosAtivos}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ChamadoSearchDelegate(),
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Gestão de Ativos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const GestaoAtivosScreen(),
                ),
              );
            },
          ),
          
          const SizedBox(width: 8),
          
          // Menu do usuário
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  authProvider.getInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'perfil') {
                Navigator.of(context).pushNamed('/perfil');
              } else if (value == 'dashboard_gerencial') {
                _navigateToDashboardGerencial();
              } else if (value == 'sair') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'perfil',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName ?? 'Usuário',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (authProvider.userEmail != null)
                          Text(
                            authProvider.userEmail!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sair',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Sair', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Banner compacto de acesso ao Dashboard Gerencial
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              elevation: 1,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _navigateToDashboardGerencial,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard Gerencial',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Visualize KPIs, gráficos e indicadores',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Chip de filtros ativos
          if (chamadoProvider.hasFiltrosAtivos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${chamadoProvider.totalFiltrosAtivos} filtro(s) ativo(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _limparFiltros,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
          
          // Lista de chamados
          Expanded(
            child: Consumer<ChamadoProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando chamados...'),
                      ],
                    ),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadChamados,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.chamados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum chamado encontrado',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.hasFiltrosAtivos
                                ? 'Tente ajustar os filtros'
                                : 'Crie seu primeiro chamado',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          if (provider.hasFiltrosAtivos)
                            OutlinedButton.icon(
                              onPressed: _limparFiltros,
                              icon: const Icon(Icons.clear),
                              label: const Text('Limpar Filtros'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _navigateToCriarChamado,
                              icon: const Icon(Icons.add),
                              label: const Text('Criar Chamado'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadChamados,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.chamados.length,
                    itemBuilder: (context, index) {
                      final chamado = provider.chamados[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ChamadoCard(
                          chamado: chamado,
                          onTap: () => _navigateToDetail(chamado.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCriarChamado,
        icon: const Icon(Icons.add),
        label: const Text('Criar Chamado'),
      ),
    );
  }
}

// Search Delegate
class _ChamadoSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final provider = Provider.of<ChamadoProvider>(context, listen: false);
    provider.fetchChamados(search: query);
    
    return Consumer<ChamadoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.chamados.length,
          itemBuilder: (context, index) {
            final chamado = provider.chamados[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ChamadoCard(
                chamado: chamado,
                onTap: () {
                  close(context, '');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChamadoDetailScreen(chamadoId: chamado.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Digite para buscar chamados...'),
    );
  }
}