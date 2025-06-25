import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

class AlumnoHeader extends StatelessWidget {
  final Map<String, dynamic> alumnoData;

  const AlumnoHeader({Key? key, required this.alumnoData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 992;
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 992;
  }

  Widget _buildAlumnoInfo(BuildContext context) {
    final bool isDesktop = _isDesktop(context);
    final bool isTablet = _isTablet(context);
    final bool isSmallScreen = !isDesktop && !isTablet;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alumnoData['name'] ?? 'Sin nombre',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (!isSmallScreen) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.group,
                    text:
                        alumnoData['groups']?.isNotEmpty == true
                            ? 'Grupo: ${alumnoData['groups'][0]}'
                            : 'Sin grupo',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.date_range_outlined,
                    text:
                        'Fecha de Rescate: ${alumnoData['redemptionDate'] ?? ''}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.question_mark,
                    text:
                        'Motivo por el que iba a abortar: ${alumnoData['reasonAbortion'] ?? ''}',
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    icon: Icons.date_range_outlined,
                    text:
                        'Fecha probable de parto: ${alumnoData['childDateBirth'] ?? ''}',
                  ),
                ),
              ],
            ),
          ],
          if (isSmallScreen) ...[
            _buildInfoRow(
                    icon: Icons.group,
                    text:
                        alumnoData['groups']?.isNotEmpty == true
                            ? 'Grupo: ${alumnoData['groups'][0]}'
                            : 'Sin grupo',
                  ),
            _buildInfoRow(
              icon: Icons.date_range_outlined,
              text: 'Fecha de Rescate: ${alumnoData['redemptionDate'] ?? ''}',
            ),
            _buildInfoRow(
              icon: Icons.date_range_outlined,
              text:
                  'Fecha probable de parto: ${alumnoData['childDateBirth'] ?? ''}',
            ),
            _buildInfoRow(
              icon: Icons.question_mark,
              text:
                  'Motivo por el que iba a abortar: ${alumnoData['reasonAbortion'] ?? ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            softWrap: true,
          ),
        ),
      ],
    ),
  );
}


  // Widget _buildInfoRow({required IconData icon, required String text}) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 16, color: AppTheme.secondaryColor),
  //       const SizedBox(width: 8),
  //       Text(text, style: const TextStyle(fontSize: 14)),
  //     ],
  //   );
  // }
}
