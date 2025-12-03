import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/ativo_provider.dart';

class AdicionarAtivoScreen extends StatefulWidget {
  const AdicionarAtivoScreen({Key? key}) : super(key: key);

  @override
  State<AdicionarAtivoScreen> createState() => _AdicionarAtivoScreenState();
}

class _AdicionarAtivoScreenState extends State<AdicionarAtivoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _modeloController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _fornecedorController = TextEditingController();
  final _ambienteController = TextEditingController();

  String _status = 'Ativo';
  bool _isLoading = false;

  final List<String> _statusOptions = ['Ativo', 'Inativo', 'Manutenção'];

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _modeloController.dispose();
    _fabricanteController.dispose();
    _numeroSerieController.dispose();
    _fornecedorController.dispose();
    _ambienteController.dispose();
    super.dispose();
  }

  /// Gera o próximo código automático
  String _generateNextCode() {
    final provider = Provider.of<AtivoProvider>(context, listen: false);
    final ativos = provider.ativos;

    if (ativos.isEmpty) return 'AST-001';

    int maxNumber = 0;
    for (var ativo in ativos) {
      final parts = ativo.codigo.split('-');
      if (parts.length == 2) {
        final number = int.tryParse(parts[1]);
        if (number != null && number > maxNumber) maxNumber = number;
      }
    }

    return 'AST-${(maxNumber + 1).toString().padLeft(3, '0')}';
  }

  void _suggestCode() {
    setState(() {
      _codigoController.text = _generateNextCode();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final ativoProvider = Provider.of<AtivoProvider>(context, listen: false);

      final success = await ativoProvider.createAtivo(
        codigo: _codigoController.text.trim(),
        nome: _nomeController.text.trim(),
        modelo: _modeloController.text.trim(),
        ambiente: _ambienteController.text.trim().isEmpty
            ? 'Não informado'
            : _ambienteController.text.trim(),
        status: _status,
        fabricante: _fabricanteController.text.trim().isEmpty
            ? null
            : _fabricanteController.text.trim(),
        numeroSerie: _numeroSerieController.text.trim().isEmpty
            ? null
            : _numeroSerieController.text.trim(),
        fornecedor: _fornecedorController.text.trim().isEmpty
            ? null
            : _fornecedorController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _showMessage('Ativo cadastrado com sucesso!', isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        _showMessage(
          ativoProvider.error ?? 'Erro ao cadastrar ativo',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Erro inesperado: $e', isError: true);
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Adicionar Ativo'),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preencha os dados abaixo para cadastrar um novo ativo.',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  controller: _codigoController,
                  label: 'Código/Tag QR *',
                  hint: 'Ex: AST-001',
                  icon: Icons.qr_code,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o código' : null,
                  suffix: TextButton.icon(
                    onPressed: _suggestCode,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Gerar'),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _nomeController,
                  label: 'Nome do Ativo *',
                  hint: 'Ex: Servidor Dell PowerEdge R740',
                  icon: Icons.inventory_2_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _modeloController,
                  label: 'Modelo *',
                  hint: 'Ex: Dell PowerEdge R740',
                  icon: Icons.category_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o modelo' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fabricanteController,
                  label: 'Fabricante',
                  hint: 'Ex: Dell, HP, Cisco',
                  icon: Icons.factory_outlined,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _numeroSerieController,
                  label: 'Número de Série',
                  hint: 'Ex: SN123456789',
                  icon: Icons.confirmation_num_outlined,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _fornecedorController,
                  label: 'Fornecedor',
                  hint: 'Ex: ABC Distribuidora',
                  icon: Icons.store_mall_directory_outlined,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _ambienteController,
                  label: 'Ambiente/Localização',
                  hint: 'Ex: Data Center, Escritório',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status *',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _statusOptions.map((option) {
                    final isSelected = _status == option;
                    Color color;
                    switch (option) {
                      case 'Ativo':
                        color = Colors.green;
                        break;
                      case 'Inativo':
                        color = Colors.red;
                        break;
                      default:
                        color = Colors.orange;
                    }
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _status = option);
                      },
                      selectedColor: color,
                      backgroundColor: color.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      avatar: isSelected
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Cadastrar Ativo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: validator,
    );
  }
}
