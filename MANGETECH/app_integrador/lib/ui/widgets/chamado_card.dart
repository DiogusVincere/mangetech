import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/chamado.dart';
import '../theme/app_theme.dart';

class ChamadoCard extends StatelessWidget {
  final Chamado chamado;
  final VoidCallback onTap;

  const ChamadoCard({
    Key? key,
    required this.chamado,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (chamado.status.toUpperCase()) {
      case 'ABERTO':
        return AppTheme.statusAberto;
      case 'AGUARDANDO RESP':
      case 'AGUARDANDO RESPONSÁVEIS':
        return AppTheme.statusAguardando;
      case 'EM ANDAMENTO':
        return AppTheme.statusAndamento;
      case 'REALIZADO':
        return AppTheme.statusRealizado;
      case 'CONCLUÍDO':
        return AppTheme.statusConcluido;
      case 'CANCELADO':
        return AppTheme.statusCancelado;
      default:
        return Colors.grey;
    }
  }

  Color _getPrioridadeColor() {
    switch (chamado.prioridade.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      chamado.id,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chamado.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                chamado.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                chamado.descricao,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.inventory_2_outlined,
                    chamado.ativo,
                  ),
                  _buildInfoChip(
                    Icons.location_on_outlined,
                    chamado.ambiente,
                  ),
                  _buildPrioridadeChip(),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(chamado.dataCriacao),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  _buildResponsaveisAvatars(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPrioridadeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 14,
            color: _getPrioridadeColor(),
          ),
          const SizedBox(width: 4),
          Text(
            chamado.prioridade,
            style: TextStyle(
              fontSize: 12,
              color: _getPrioridadeColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsaveisAvatars() {
    if (chamado.responsaveis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < chamado.responsaveis.length.clamp(0, 3); i++)
          Padding(
            padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                _getInitials(chamado.responsaveis[i]),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (chamado.responsaveis.length > 3)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              child: Text(
                '+${chamado.responsaveis.length - 3}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }
}
