import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/chamado_provider.dart';
import '../../models/chamado.dart';
import '../theme/app_theme.dart';

class EditarChamadoScreen extends StatefulWidget {
  final Chamado chamado;

  const EditarChamadoScreen({
    Key? key,
    required this.chamado,
  }) : super(key: key);

  @override
  State<EditarChamadoScreen> createState() => _EditarChamadoScreenState();
}

class _EditarChamadoScreenState extends State<EditarChamadoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _ativoController;
  late TextEditingController _ambienteController;
  late TextEditingController _descricaoController;
  
  late String _urgencia;
  late String _status;
  DateTime? _dataSugerida;
  bool _isLoading = false;

  // Opções conforme Django
  final List<String> _urgenciaOptions = ['Baixa', 'Média', 'Alta', 'Crítico'];
  final List<String> _statusOptions = [
    'ABERTO',
    'AGUARDANDO RESP',
    'EM ANDAMENTO',
    'REALIZADO',
    'CONCLUÍDO',
    'CANCELADO',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializa com os dados atuais do chamado
    _tituloController = TextEditingController(text: widget.chamado.titulo);
    _ativoController = TextEditingController(text: widget.chamado.ativo);
    _ambienteController = TextEditingController(text: widget.chamado.ambiente);
    _descricaoController = TextEditingController(text: widget.chamado.descricao);
    _urgencia = widget.chamado.prioridade;
    _status = widget.chamado.status;
    _dataSugerida = widget.chamado.dataSugerida;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _ativoController.dispose();
    _ambienteController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSugerida ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: _dataSugerida != null 
            ? TimeOfDay.fromDateTime(_dataSugerida!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _dataSugerida = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      // Mostrar diálogo de confirmação se mudar o status
      if (_status != widget.chamado.status) {
        final confirmed = await _showConfirmStatusChange();
        if (!confirmed) return;
      }

      setState(() => _isLoading = true);

      try {
        final chamadoProvider = Provider.of<ChamadoProvider>(context, listen: false);
        
        // Formatar data para Django (ISO 8601)
        String? dataSugeridaFormatada;
        if (_dataSugerida != null) {
          dataSugeridaFormatada = _dataSugerida!.toIso8601String();
        }

        // Atualizar chamado via API
        // TODO: Implementar método de atualização no provider
        // Por enquanto, vamos apenas mudar o status se necessário
        
        if (_status != widget.chamado.status) {
          final success = await chamadoProvider.mudarStatus(
            chamadoId: widget.chamado.id,
            novoStatus: _status,
            descricao: 'Status alterado via edição do chamado',
          );
          
          if (!success) {
            throw Exception('Erro ao atualizar status');
          }
        }

        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Chamado atualizado com sucesso!', isError: false);
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.of(context).pop(true); // Retorna true para indicar sucesso
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Erro ao atualizar chamado: $e', isError: true);
        }
      }
    }
  }

  Future<bool> _showConfirmStatusChange() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar mudança de status'),
        content: Text(
          'Você está alterando o status de "${widget.chamado.status}" para "$_status".\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Editar Chamado'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card informativo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ID do Chamado: ${widget.chamado.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: Icon(Icons.title),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O título é obrigatório';
                  }
                  if (value.length < 5) {
                    return 'O título deve ter pelo menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ativo
              TextFormField(
                controller: _ativoController,
                decoration: const InputDecoration(
                  labelText: 'Ativo/Equipamento *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O ativo é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ambiente
              TextFormField(
                controller: _ambienteController,
                decoration: const InputDecoration(
                  labelText: 'Ambiente/Localização',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A descrição é obrigatória';
                  }
                  if (value.length < 15) {
                    return 'A descrição deve ter pelo menos 15 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Status
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: Icon(Icons.sync_alt),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Data sugerida
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.grey[700]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data sugerida de resolução',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dataSugerida != null
                                  ? '${_dataSugerida!.day.toString().padLeft(2, '0')}/${_dataSugerida!.month.toString().padLeft(2, '0')}/${_dataSugerida!.year} às ${_dataSugerida!.hour.toString().padLeft(2, '0')}:${_dataSugerida!.minute.toString().padLeft(2, '0')}'
                                  : 'Nenhuma data definida',
                              style: TextStyle(
                                fontSize: 13,
                                color: _dataSugerida != null 
                                    ? Colors.black87 
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nível de urgência
              const Text(
                'Nível de urgência *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _urgenciaOptions.map((option) {
                  final isSelected = _urgencia == option;
                  Color chipColor;
                  
                  switch (option) {
                    case 'Crítico':
                      chipColor = Colors.red;
                      break;
                    case 'Alta':
                      chipColor = Colors.orange;
                      break;
                    case 'Média':
                      chipColor = Colors.yellow[700]!;
                      break;
                    case 'Baixa':
                      chipColor = Colors.blue;
                      break;
                    default:
                      chipColor = Colors.grey;
                  }
                  
                  return ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _urgencia = option);
                      }
                    },
                    selectedColor: chipColor,
                    backgroundColor: chipColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : chipColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    avatar: isSelected 
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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
                          : const Text('Salvar Alterações'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}