import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/providers/chamado_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/api/api_service.dart';
import '../theme/app_theme.dart';

class CriarChamadoScreen extends StatefulWidget {
  const CriarChamadoScreen({Key? key}) : super(key: key);

  @override
  State<CriarChamadoScreen> createState() => _CriarChamadoScreenState();
}

class _CriarChamadoScreenState extends State<CriarChamadoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _ativoController = TextEditingController();
  final _ambienteController = TextEditingController();
  final _descricaoController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  String _urgencia = 'Média';
  DateTime? _dataSugerida;
  final List<XFile> _anexos = [];
  bool _isLoading = false;
  
  // Ativos
  List<Map<String, dynamic>> _ativos = [];
  bool _isLoadingAtivos = true;
  String? _selectedAtivoId;
  bool _useManualInput = false;

  // Opções de urgência conforme Django
  final List<String> _urgenciaOptions = ['Baixa', 'Média', 'Alta', 'Crítico'];

  @override
  void initState() {
    super.initState();
    _loadAtivos();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _ativoController.dispose();
    _ambienteController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _loadAtivos() async {
    setState(() => _isLoadingAtivos = true);
    
    try {
      print('Iniciando carregamento de ativos...');
      
      final ativos = await _apiService.getAtivosMap();
      
      print('Ativos recebidos: ${ativos.length}');
      
      if (mounted) {
        setState(() {
          _ativos = ativos;
          _isLoadingAtivos = false;
          
          // Se não há ativos, usa input manual
          if (_ativos.isEmpty) {
            _useManualInput = true;
            print('Nenhum ativo disponível - modo manual ativado');
          } else {
            print('${_ativos.length} ativos disponíveis');
          }
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar ativos: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingAtivos = false;
          _useManualInput = true;
          _ativos = [];
        });
        
        _showMessage(
          'Não foi possível carregar os ativos. Digite manualmente.',
          isError: false,
        );
      }
    }
  }

  Future<void> _pickImages() async {
    if (_anexos.length >= 5) {
      _showMessage('Máximo de 5 arquivos permitidos', isError: true);
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        final remainingSlots = 5 - _anexos.length;
        _anexos.addAll(images.take(remainingSlots));
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  String _getAtivoValue() {
    if (_useManualInput) {
      return _ativoController.text.trim();
    } else if (_selectedAtivoId != null) {
      final ativo = _ativos.firstWhere(
        (a) => a['id'].toString() == _selectedAtivoId,
        orElse: () => {},
      );
      return ativo['codigo'] ?? '';
    }
    return '';
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final chamadoProvider = Provider.of<ChamadoProvider>(context, listen: false);
        
        // Formatar data para Django (ISO 8601)
        String? dataSugeridaFormatada;
        if (_dataSugerida != null) {
          dataSugeridaFormatada = _dataSugerida!.toIso8601String();
        }

        final ativoValue = _getAtivoValue();
        
        if (ativoValue.isEmpty) {
          _showMessage('Selecione ou digite um ativo', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        // Criar chamado
        final success = await chamadoProvider.createChamado(
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          ativo: ativoValue,
          ambiente: _ambienteController.text.trim().isEmpty 
              ? 'Não informado' 
              : _ambienteController.text.trim(),
          urgencia: _urgencia,
          dataSugerida: dataSugeridaFormatada,
          responsaveis: null,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          if (success) {
            _showMessage('Chamado criado com sucesso!', isError: false);
            
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          } else {
            final error = chamadoProvider.error ?? 'Erro ao criar chamado';
            _showMessage(error, isError: true);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('Erro ao criar chamado: $e', isError: true);
        }
      }
    }
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
        title: const Text('Criar Chamado'),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Preencha os dados para criar um novo chamado',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
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
                  hintText: 'Descreva brevemente o problema',
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

              // Ativo/Equipamento
              _buildAtivoField(),
              const SizedBox(height: 16),

              // Ambiente
              TextFormField(
                controller: _ambienteController,
                decoration: const InputDecoration(
                  labelText: 'Ambiente/Localização *',
                  hintText: 'Ex: Setor Financeiro - Sala 204',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O ambiente é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  hintText: 'Descreva o problema detalhadamente',
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
                                  : 'Nenhuma data selecionada (opcional)',
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
                      onPressed: _isLoading ? null : _handleSubmit,
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
                          : const Text('Criar Chamado'),
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

  Widget _buildAtivoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ativo/Equipamento *',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!_isLoadingAtivos && _ativos.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useManualInput = !_useManualInput;
                    _selectedAtivoId = null;
                    _ativoController.clear();
                  });
                },
                icon: Icon(
                  _useManualInput ? Icons.list : Icons.edit,
                  size: 16,
                ),
                label: Text(
                  _useManualInput ? 'Selecionar' : 'Digitar',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_isLoadingAtivos)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Carregando ativos...',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else if (_useManualInput || _ativos.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _ativoController,
                decoration: InputDecoration(
                  hintText: 'Digite o código ou nome do equipamento',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  suffixIcon: _ativos.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            _showMessage('Scanner em desenvolvimento', isError: false);
                          },
                        ),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O ativo é obrigatório';
                  }
                  return null;
                },
              ),
              if (_ativos.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nenhum ativo cadastrado. Digite manualmente.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedAtivoId,
                decoration: const InputDecoration(
                  hintText: 'Selecione um ativo',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                items: _ativos.map((ativo) {
                  return DropdownMenuItem<String>(
                    value: ativo['id'].toString(),
                    child: Text(
                      '${ativo['codigo']} - ${ativo['nome']} (${ativo['ambiente']})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAtivoId = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um ativo';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  '${_ativos.length} ativo(s) disponível(is)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}