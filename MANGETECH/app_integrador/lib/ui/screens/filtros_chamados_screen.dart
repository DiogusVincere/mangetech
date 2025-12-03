import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FiltrosChamadosScreen extends StatefulWidget {
  final Map<String, dynamic> filtrosAtuais;

  const FiltrosChamadosScreen({
    Key? key,
    this.filtrosAtuais = const {},
  }) : super(key: key);

  @override
  State<FiltrosChamadosScreen> createState() => _FiltrosChamadosScreenState();
}

class _FiltrosChamadosScreenState extends State<FiltrosChamadosScreen> {
  // Filtros selecionados
  List<String> _statusSelecionados = [];
  List<String> _urgenciasSelecionadas = [];
  String? _ambienteSelecionado;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _meusChamados = false;
  String _ordenarPor = 'data_criacao';
  String _ordem = 'desc';

  // Opções
  final List<String> _statusOptions = [
    'ABERTO',
    'AGUARDANDO RESP',
    'EM ANDAMENTO',
    'REALIZADO',
    'CONCLUÍDO',
    'CANCELADO',
  ];

  final List<String> _urgenciaOptions = [
    'Crítico',
    'Alta',
    'Média',
    'Baixa',
  ];

  final List<Map<String, String>> _ordenacaoOptions = [
    {'value': 'data_criacao', 'label': 'Data de Criação'},
    {'value': 'data_atualizacao', 'label': 'Última Atualização'},
    {'value': 'urgencia', 'label': 'Urgência'},
    {'value': 'status', 'label': 'Status'},
    {'value': 'data_sugerida', 'label': 'Data Sugerida'},
  ];

  @override
  void initState() {
    super.initState();
    _carregarFiltrosAtuais();
  }

  void _carregarFiltrosAtuais() {
    setState(() {
      if (widget.filtrosAtuais['status'] != null) {
        if (widget.filtrosAtuais['status'] is List) {
          _statusSelecionados = List<String>.from(widget.filtrosAtuais['status']);
        } else {
          _statusSelecionados = [widget.filtrosAtuais['status'].toString()];
        }
      }

      if (widget.filtrosAtuais['urgencia'] != null) {
        if (widget.filtrosAtuais['urgencia'] is List) {
          _urgenciasSelecionadas = List<String>.from(widget.filtrosAtuais['urgencia']);
        } else {
          _urgenciasSelecionadas = [widget.filtrosAtuais['urgencia'].toString()];
        }
      }

      _ambienteSelecionado = widget.filtrosAtuais['ambiente']?.toString();
      _meusChamados = widget.filtrosAtuais['meus_chamados'] == true;
      _ordenarPor = widget.filtrosAtuais['ordering']?.toString() ?? 'data_criacao';
      
      if (_ordenarPor.startsWith('-')) {
        _ordem = 'desc';
        _ordenarPor = _ordenarPor.substring(1);
      } else {
        _ordem = 'asc';
      }
    });
  }

  Map<String, dynamic> _construirFiltros() {
    final filtros = <String, dynamic>{};

    if (_statusSelecionados.isNotEmpty) {
      filtros['status'] = _statusSelecionados.join(',');
    }

    if (_urgenciasSelecionadas.isNotEmpty) {
      filtros['urgencia'] = _urgenciasSelecionadas.join(',');
    }

    if (_ambienteSelecionado != null && _ambienteSelecionado!.isNotEmpty) {
      filtros['ambiente'] = _ambienteSelecionado;
    }

    if (_dataInicio != null) {
      filtros['data_inicio'] = DateFormat('yyyy-MM-dd').format(_dataInicio!);
    }

    if (_dataFim != null) {
      filtros['data_fim'] = DateFormat('yyyy-MM-dd').format(_dataFim!);
    }

    if (_meusChamados) {
      filtros['meus_chamados'] = 'true';
    }

    // Ordenação
    final ordenacao = _ordem == 'desc' ? '-$_ordenarPor' : _ordenarPor;
    filtros['ordering'] = ordenacao;

    return filtros;
  }

  void _limparFiltros() {
    setState(() {
      _statusSelecionados.clear();
      _urgenciasSelecionadas.clear();
      _ambienteSelecionado = null;
      _dataInicio = null;
      _dataFim = null;
      _meusChamados = false;
      _ordenarPor = 'data_criacao';
      _ordem = 'desc';
    });
  }

  void _aplicarFiltros() {
    Navigator.of(context).pop(_construirFiltros());
  }

  Future<void> _selecionarData(bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio 
          ? (_dataInicio ?? DateTime.now())
          : (_dataFim ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Filtros'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _limparFiltros,
            child: const Text('Limpar'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meus Chamados
          Card(
            child: SwitchListTile(
              title: const Text('Meus Chamados'),
              subtitle: const Text('Apenas chamados que criei ou sou responsável'),
              value: _meusChamados,
              onChanged: (value) {
                setState(() => _meusChamados = value);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Status
          _buildSectionCard(
            title: 'Status',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusOptions.map((status) {
                final isSelected = _statusSelecionados.contains(status);
                return FilterChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _statusSelecionados.add(status);
                      } else {
                        _statusSelecionados.remove(status);
                      }
                    });
                  },
                  selectedColor: _getStatusColor(status),
                  backgroundColor: _getStatusColor(status).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : _getStatusColor(status),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Urgência
          _buildSectionCard(
            title: 'Urgência',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _urgenciaOptions.map((urgencia) {
                final isSelected = _urgenciasSelecionadas.contains(urgencia);
                return FilterChip(
                  label: Text(urgencia),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _urgenciasSelecionadas.add(urgencia);
                      } else {
                        _urgenciasSelecionadas.remove(urgencia);
                      }
                    });
                  },
                  selectedColor: _getUrgenciaColor(urgencia),
                  backgroundColor: _getUrgenciaColor(urgencia).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : _getUrgenciaColor(urgencia),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Período
          _buildSectionCard(
            title: 'Período',
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data Início'),
                  subtitle: Text(
                    _dataInicio != null
                        ? DateFormat('dd/MM/yyyy').format(_dataInicio!)
                        : 'Selecione uma data',
                  ),
                  trailing: _dataInicio != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _dataInicio = null);
                          },
                        )
                      : null,
                  onTap: () => _selecionarData(true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data Fim'),
                  subtitle: Text(
                    _dataFim != null
                        ? DateFormat('dd/MM/yyyy').format(_dataFim!)
                        : 'Selecione uma data',
                  ),
                  trailing: _dataFim != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _dataFim = null);
                          },
                        )
                      : null,
                  onTap: () => _selecionarData(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ordenação
          _buildSectionCard(
            title: 'Ordenar Por',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _ordenarPor,
                  decoration: const InputDecoration(
                    labelText: 'Campo',
                    border: OutlineInputBorder(),
                  ),
                  items: _ordenacaoOptions.map((option) {
                    return DropdownMenuItem(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _ordenarPor = value!);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'asc',
                      label: Text('Crescente'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'desc',
                      label: Text('Decrescente'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_ordem},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _ordem = newSelection.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _aplicarFiltros,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ABERTO':
        return Colors.blue;
      case 'AGUARDANDO RESP':
        return Colors.amber;
      case 'EM ANDAMENTO':
        return Colors.orange;
      case 'REALIZADO':
        return Colors.lightGreen;
      case 'CONCLUÍDO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgenciaColor(String urgencia) {
    switch (urgencia.toLowerCase()) {
      case 'crítico':
        return Colors.red;
      case 'alta':
        return Colors.orange;
      case 'média':
        return Colors.yellow[700]!;
      case 'baixa':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}