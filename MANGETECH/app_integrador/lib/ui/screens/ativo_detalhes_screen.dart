// lib/screens/ativos/ativo_detalhes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/providers/ativo_provider.dart';
import '../../data/providers/chamado_provider.dart';
import '../../models/ativo.dart';
import '../../models/chamado.dart';
import '../theme/app_theme.dart';
import 'editar_ativo_screen.dart';

class AtivoDetalhesScreen extends StatefulWidget {
  final int ativoId;

  const AtivoDetalhesScreen({Key? key, required this.ativoId}) : super(key: key);

  @override
  State<AtivoDetalhesScreen> createState() => _AtivoDetalhesScreenState();
}

class _AtivoDetalhesScreenState extends State<AtivoDetalhesScreen> {
  Ativo? _ativo;
  List<Chamado> _chamadosRelacionados = [];
  bool _isLoading = true;
  bool _isLoadingChamados = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAtivoDetails();
  }

  Future<void> _loadAtivoDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ativoProvider = Provider.of<AtivoProvider>(context, listen: false);
      
      // Buscar ativo específico
      final ativo = ativoProvider.getAtivoById(widget.ativoId);
      
      if (ativo == null) {
        // Se não encontrou localmente, recarrega todos
        await ativoProvider.fetchAtivos();
        final ativoRecarregado = ativoProvider.getAtivoById(widget.ativoId);
        
        if (ativoRecarregado == null) {
          throw Exception('Ativo não encontrado');
        }
        
        setState(() {
          _ativo = ativoRecarregado;
        });
      } else {
        setState(() {
          _ativo = ativo;
        });
      }

      // Carregar chamados relacionados
      await _loadChamadosRelacionados();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChamadosRelacionados() async {
    if (_ativo == null) return;

    setState(() {
      _isLoadingChamados = true;
    });

    try {
      final chamadoProvider = Provider.of<ChamadoProvider>(context, listen: false);
      
      // Buscar chamados que contém o código do ativo
      await chamadoProvider.fetchChamados(search: _ativo!.codigo);
      
      // Filtrar apenas os que realmente são deste ativo
      _chamadosRelacionados = chamadoProvider.chamados
          .where((c) => c.ativo.contains(_ativo!.codigo))
          .toList();
      
      setState(() {
        _isLoadingChamados = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar chamados: $e');
      setState(() {
        _isLoadingChamados = false;
      });
    }
  }

  Future<void> _navigateToEditarAtivo() async {
    if (_ativo == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarAtivoScreen(ativo: _ativo!),
      ),
    );

    if (result == true && mounted) {
      _loadAtivoDetails();
    }
  }

  void _showQRCode() {
    if (_ativo == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: _ativo!.codigo,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _ativo!.codigo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _ativo!.nome,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Detalhes do Ativo'),
        elevation: 0,
        actions: [
          if (_ativo != null) ...[
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: _showQRCode,
              tooltip: 'Ver QR Code',
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _navigateToEditarAtivo,
              tooltip: 'Editar',
            ),
          ],
          const SizedBox(width: 8),
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
            Text('Carregando detalhes...'),
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
                'Erro ao carregar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAtivoDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_ativo == null) {
      return const Center(child: Text('Ativo não encontrado'));
    }

    return RefreshIndicator(
      onRefresh: _loadAtivoDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildChamadosCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: _ativo!.codigo,
                size: 120,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _ativo!.codigo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _ativo!.nome,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            _buildStatusChip(_ativo!.status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Técnicas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Modelo', _ativo!.modelo),
            if (_ativo!.fabricante != null && _ativo!.fabricante!.isNotEmpty)
              _buildInfoRow('Fabricante', _ativo!.fabricante!),
            if (_ativo!.numeroSerie != null && _ativo!.numeroSerie!.isNotEmpty)
              _buildInfoRow('Nº Série', _ativo!.numeroSerie!),
            if (_ativo!.fornecedor != null && _ativo!.fornecedor!.isNotEmpty)
              _buildInfoRow('Fornecedor', _ativo!.fornecedor!),
            _buildInfoRow('Ambiente', '📍 ${_ativo!.ambiente}'),
            const Divider(height: 24),
            _buildInfoRow(
              'Cadastrado em',
              '📅 ${_formatDate(_ativo!.dataCadastro)}',
            ),
            _buildInfoRow(
              'Atualizado em',
              '🕒 ${_formatDate(_ativo!.dataAtualizacao)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Estatísticas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Chamados',
                    _ativo!.totalChamados.toString(),
                    Colors.blue,
                    Icons.assessment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'Chamados Abertos',
                    _ativo!.chamadosAbertos.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChamadosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chamados Relacionados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingChamados)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_chamadosRelacionados.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum chamado relacionado',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _chamadosRelacionados.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chamado = _chamadosRelacionados[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    title: Text(
                      '#${chamado.id} - ${chamado.titulo}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(_formatDate(chamado.dataCriacao)),
                        const SizedBox(height: 8),
                        _buildStatusChip(chamado.status),
                      ],
                    ),
                    onTap: () {
                      // Navegar para detalhes do chamado
                      Navigator.pushNamed(
                        context,
                        '/chamado-detalhes',
                        arguments: chamado.id,
                      );
                    },
                  );
                },
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
      case 'ABERTO':
        color = Colors.blue;
        break;
      case 'EM ANDAMENTO':
        color = Colors.purple;
        break;
      case 'CONCLUÍDO':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}