import 'package:app_integrador/ui/screens/ativo_detalhes_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/providers/ativo_provider.dart';
import '../../models/ativo.dart';
import '../theme/app_theme.dart';
import 'adicionar_ativo_screen.dart';
import 'editar_ativo_screen.dart';

class GestaoAtivosScreen extends StatefulWidget {
  const GestaoAtivosScreen({Key? key}) : super(key: key);

  @override
  State<GestaoAtivosScreen> createState() => _GestaoAtivosScreenState();
}

class _GestaoAtivosScreenState extends State<GestaoAtivosScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAtivos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAtivoDetalhes(Ativo ativo) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AtivoDetalhesScreen(ativoId: ativo.id),
    ),
  );
}

  Future<void> _loadAtivos() async {
    try {
      final provider = Provider.of<AtivoProvider>(context, listen: false);
      await provider.fetchAtivos();
    } catch (e) {
      print('❌ Erro ao carregar ativos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar ativos: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }

  List<Ativo> _getFilteredAtivos(List<Ativo> ativos) {
    var filtered = ativos;

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((a) => a.status == _selectedStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.nome.toLowerCase().contains(query) ||
            a.codigo.toLowerCase().contains(query) ||
            a.modelo.toLowerCase().contains(query) ||
            (a.fabricante?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }

  Future<void> _navigateToEditarAtivo(Ativo ativo) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarAtivoScreen(ativo: ativo),
      ),
    );

    if (result == true && mounted) {
      _loadAtivos();
    }
  }

  Future<void> _navigateToAdicionarAtivo() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdicionarAtivoScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadAtivos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Gestão de Ativos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear QR Code',
            onPressed: _showQRScanner,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loadAtivos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStats(),
          Expanded(child: _buildAssetList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdicionarAtivo,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Ativo'),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por código, nome ou modelo...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Filtrar por Status',
              prefixIcon: const Icon(Icons.filter_list),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos os status')),
              DropdownMenuItem(value: 'Ativo', child: Text('Ativo')),
              DropdownMenuItem(value: 'Inativo', child: Text('Inativo')),
              DropdownMenuItem(value: 'Manutenção', child: Text('Manutenção')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Consumer<AtivoProvider>(
      builder: (context, provider, child) {
        if (provider.ativos.isEmpty) return const SizedBox.shrink();

        final stats = provider.getStatusStats();
        final totalChamados = provider.getTotalChamados();
        final chamadosAbertos = provider.getChamadosAbertos();

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Ativos',
                  provider.ativos.length.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (stats['Ativo'] ?? 0).toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Manutenção',
                  (stats['Manutenção'] ?? 0).toString(),
                  Icons.build,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Chamados',
                  chamadosAbertos.toString(),
                  Icons.support_agent,
                  Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetList() {
    return Consumer<AtivoProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando ativos...'),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                    onPressed: _loadAtivos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredAtivos = _getFilteredAtivos(provider.ativos);

        if (filteredAtivos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum ativo encontrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty || _selectedStatus != null
                        ? 'Tente ajustar os filtros de busca'
                        : 'Nenhum ativo cadastrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadAtivos,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAtivos.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAssetCard(filteredAtivos[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssetCard(Ativo ativo) {
    return Card(
      child: InkWell(
        onTap: () => _navigateToAtivoDetalhes(ativo), 
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: ativo.codigo,
                  size: 60,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.codigo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ativo.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ativo.modelo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildChip(ativo.ambiente, Colors.blue),
                        _buildStatusChip(ativo.status),
                        if (ativo.chamadosAbertos > 0)
                          _buildChip('${ativo.chamadosAbertos} chamado(s)',
                              Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'editar') {
                    _navigateToEditarAtivo(ativo);
                  } else if (value == 'detalhes') {
                    _showAssetDetails(ativo);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 12),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'detalhes',
                    child: Row(
                      children: [
                        Icon(Icons.info_outlined, size: 18),
                        SizedBox(width: 12),
                        Text('Detalhes'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Ativo':
        color = Colors.green;
        break;
      case 'Inativo':
        color = Colors.red;
        break;
      case 'Manutenção':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return _buildChip(status, color);
  }

  void _showQRScanner() {
    final MobileScannerController cameraController = MobileScannerController();
    final TextEditingController manualInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scanner QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    cameraController.dispose();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        cameraController.dispose();
                        Navigator.pop(context);
                        _buscarAtivoPorQR(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Posicione o QR code dentro da área destacada'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: manualInputController,
                    decoration: InputDecoration(
                      hintText: 'Ou digite o código',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (manualInputController.text.isNotEmpty) {
                      cameraController.dispose();
                      Navigator.pop(context);
                      _buscarAtivoPorQR(manualInputController.text);
                    }
                  },
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      cameraController.dispose();
      manualInputController.dispose();
    });
  }

  Future<void> _buscarAtivoPorQR(String codigo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = Provider.of<AtivoProvider>(context, listen: false);
      final ativo = await provider.fetchAtivoByQRCode(codigo);

      if (mounted) {
        Navigator.pop(context);

        if (ativo != null) {
          _showAssetDetails(ativo);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ativo não encontrado: $codigo'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar ativo: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAssetDetails(Ativo ativo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalhes do Ativo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToEditarAtivo(ativo);
                      },
                      tooltip: 'Editar ativo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(data: ativo.codigo, size: 200),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informações Técnicas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Código/Tag', ativo.codigo),
            _buildInfoRow('Nome', ativo.nome),
            _buildInfoRow('Modelo', ativo.modelo),
            if (ativo.fabricante != null)
              _buildInfoRow('Fabricante', ativo.fabricante!),
            if (ativo.numeroSerie != null)
              _buildInfoRow('Nº Série', ativo.numeroSerie!),
            if (ativo.fornecedor != null)
              _buildInfoRow('Fornecedor', ativo.fornecedor!),
            _buildInfoRow('Ambiente', ativo.ambiente),
            _buildInfoRow('Status', ativo.status),
            const SizedBox(height: 24),
            const Text(
              'Chamados Relacionados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTicketStat('Total',
                            ativo.totalChamados.toString(), Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTicketStat('Em Aberto',
                            ativo.chamadosAbertos.toString(), Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
