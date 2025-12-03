  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import '../../models/chamado.dart';
  import '../theme/app_theme.dart';
  import 'image_gallery.dart';

  class TimelineItem extends StatelessWidget {
    final ChamadoStatusHistory history;
    final bool isLast;

    const TimelineItem({
      Key? key,
      required this.history,
      required this.isLast,
    }) : super(key: key);

    Color _getStatusColor() {
      switch (history.status.toUpperCase()) {
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

    @override
    Widget build(BuildContext context) {
      final dateFormat = DateFormat('dd/MM/yyyy • HH:mm');

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        history.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      history.descricao,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (history.fotos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ImageGallery(images: history.fotos),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            _getInitials(history.usuario),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          history.usuario,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(history.timestamp),
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
            ),
          ],
        ),
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