import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

class AlumnoHeader extends StatelessWidget {
  final Map<String, dynamic> alumnoData;

  const AlumnoHeader({
    Key? key, 
    required this.alumnoData
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 16),
            _buildAlumnoInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
      radius: 40,
      child: Text(
        alumnoData['name']?.isNotEmpty == true
            ? alumnoData['name'].substring(0, 1).toUpperCase()
            : '?',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildAlumnoInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alumnoData['name'] ?? 'Sin nombre',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.group,
            text: alumnoData['groups']?.isNotEmpty == true 
              ? 'Grupo: ${alumnoData['groups'][0]}' 
              : 'Sin grupo',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            icon: Icons.star_border,
            text: 'Estado: ${alumnoData['status'] ?? 'Sin estado'}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String text
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.secondaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}