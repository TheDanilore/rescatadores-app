import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget para mostrar un seguimiento en una tarjeta
class SeguimientoCard extends StatelessWidget {
  final Map<String, dynamic> seguimiento;
  final bool isIndividual;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final bool isSelected;
  final ValueChanged<bool?> onSelected;

  const SeguimientoCard({
    super.key,
    required this.seguimiento,
    required this.isIndividual,
    required this.onTap,
    required this.onExport,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    String title =
        isIndividual ? seguimiento['alumnoName'] : seguimiento['groupName'];

    String subtitle = seguimiento['semana'] ?? 'Semana sin fecha';

    if (isIndividual &&
        seguimiento['groupName'] != null &&
        seguimiento['groupName'].isNotEmpty) {
      subtitle += ' • ${seguimiento['groupName']}';
    }

    String fechaText = 'Sin fecha';
    if (seguimiento['timestamp'] != null) {
      fechaText = DateFormat(
        'dd/MM/yyyy',
      ).format((seguimiento['timestamp'] as Timestamp).toDate());
    }

    return Card(
      key: Key(seguimiento['id']),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Checkbox(value: isSelected, onChanged: onSelected),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIndividual ? Icons.person : Icons.group,
                          color: const Color(0xFF1E90FF),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: $fechaText',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.visibility,
                    color: Colors.blue,
                    tooltip: 'Ver detalles',
                    onPressed: onTap,
                  ),
                  _buildActionButton(
                    icon: Icons.download,
                    color: const Color(0xFF1E90FF),
                    tooltip: 'Exportar',
                    onPressed: onExport,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }
}
