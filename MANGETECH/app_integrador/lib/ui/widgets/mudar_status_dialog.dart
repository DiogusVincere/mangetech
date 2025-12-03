import 'package:flutter/material.dart';
import '../../models/chamado.dart';

class MudarStatusDialog extends StatefulWidget {
  final Chamado chamado;

  const MudarStatusDialog({Key? key, required this.chamado}) : super(key: key);

  @override
  State<MudarStatusDialog> createState() => _MudarStatusDialogState();
}

class _MudarStatusDialogState extends State<MudarStatusDialog> {
  String? _selectedStatus;
  final _descricaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _statusOptions = [
    'ABERTO',
    'AGUARDANDO RESP',
    'EM ANDAMENTO',
    'REALIZADO',
    'CONCLUÍDO',
    'CANCELADO',
  ];

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mudar status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Novo status',
                  prefixIcon: Icon(Icons.sync_alt),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione um status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição *',
                  hintText: 'Descreva a mudança de status',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A descrição é obrigatória';
                  }
                  if (value.length < 10) {
                    return 'A descrição deve ter pelo menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Adicionar fotos (opcional)'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status alterado com sucesso!'),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}