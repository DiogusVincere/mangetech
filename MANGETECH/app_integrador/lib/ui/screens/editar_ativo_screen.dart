import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/ativo_provider.dart';
import '../../models/ativo.dart';
import '../theme/app_theme.dart';

class EditarAtivoScreen extends StatefulWidget {
  final Ativo ativo;

  const EditarAtivoScreen({
    Key? key,
    required this.ativo,
  }) : super(key: key);

  @override
  State<EditarAtivoScreen> createState() => _EditarAtivoScreenState();
}

class _EditarAtivoScreenState extends State<EditarAtivoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codigoController;
  late TextEditingController _nomeController;
  late TextEditingController _modeloController;
  late TextEditingController _fabricanteController;
  late TextEditingController _numeroSerieController;
  late TextEditingController _fornecedorController;
  late TextEditingController _ambienteController;

  late String _status;
  bool _isLoading = false;

  final List<String> _statusOptions = ['Ativo', 'Inativo', 'Manutenção'];

  @override
  void initState() {
    super.initState();
    // Inicializa com os dados atuais do ativo
    _codigoController = TextEditingController(text: widget.ativo.codigo);
    _nomeController = TextEditingController(text: widget.ativo.nome);
    _modeloController = TextEditingController(text: widget.ativo.modelo);
    _fabricanteController = TextEditingController(text: widget.ativo.fabricante ?? '');
    _numeroSerieController = TextEditingController(text: widget.ativo.numeroSerie ?? '');
    _fornecedorController = TextEditingController(text: widget.ativo.fornecedor ?? '');
    _ambienteController = TextEditingController(text: widget.ativo.ambiente);
    _status = widget.ativo.status;
  }

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

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final ativoProvider = Provider.of<AtivoProvider>(context, listen: false);

        final success = await ativoProvider.updateAtivo(
          id: widget.ativo.id,
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
          _showMessage('Ativo atualizado com sucesso!', isError: false);
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.of(context).pop(true);
        } else {
          _showMessage(
            ativoProvider.error ?? 'Erro ao atualizar ativo',
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
        title: const Text('Editar Ativo'),
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
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.orange[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Atualize os dados do ativo ${widget.ativo.codigo}',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Código (somente leitura)
                _buildTextField(
                  controller: _codigoController,
                  label: 'Código/Tag QR',
                  hint: 'Código do ativo',
                  icon: Icons.qr_code,
                  readOnly: true,
                  validator: (v) => null,
                ),
                const SizedBox(height: 16),

                // Nome
                _buildTextField(
                  controller: _nomeController,
                  label: 'Nome do Ativo *',
                  hint: 'Ex: Servidor Dell PowerEdge R740',
                  icon: Icons.inventory_2_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),

                // Modelo
                _buildTextField(
                  controller: _modeloController,
                  label: 'Modelo *',
                  hint: 'Ex: Dell PowerEdge R740',
                  icon: Icons.category_outlined,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o modelo' : null,
                ),
                const SizedBox(height: 16),

                // Fabricante
                _buildTextField(
                  controller: _fabricanteController,
                  label: 'Fabricante',
                  hint: 'Ex: Dell, HP, Cisco',
                  icon: Icons.factory_outlined,
                ),
                const SizedBox(height: 16),

                // Número de Série
                _buildTextField(
                  controller: _numeroSerieController,
                  label: 'Número de Série',
                  hint: 'Ex: SN123456789',
                  icon: Icons.confirmation_num_outlined,
                ),
                const SizedBox(height: 16),

                // Fornecedor
                _buildTextField(
                  controller: _fornecedorController,
                  label: 'Fornecedor',
                  hint: 'Ex: ABC Distribuidora',
                  icon: Icons.store_mall_directory_outlined,
                ),
                const SizedBox(height: 16),

                // Ambiente/Localização
                _buildTextField(
                  controller: _ambienteController,
                  label: 'Ambiente/Localização',
                  hint: 'Ex: Data Center, Escritório',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),

                // Status
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
                const SizedBox(height: 24),

                // Info de datas
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Cadastrado em',
                        _formatDate(widget.ativo.dataCadastro),
                      ),
                      _buildInfoRow(
                        'Última atualização',
                        _formatDate(widget.ativo.dataAtualizacao),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Botões
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
                        onPressed: _isLoading ? null : _handleSave,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Salvar Alterações'),
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
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
      ),
      validator: validator,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}