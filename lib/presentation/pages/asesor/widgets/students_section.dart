import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/presentation/pages/asesor/alumno_tracking_form.dart';

class StudentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> alumnosGrupo;
  final VoidCallback onShowAllStudents;

  const StudentsSection({
    super.key,
    required this.alumnosGrupo,
    required this.onShowAllStudents,
  });

  @override
  Widget build(BuildContext context) {
    final displayedAlumnos = alumnosGrupo.take(5).toList();
    final hasMoreAlumnos = alumnosGrupo.length > 5;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppTheme.spacingS),
            _buildStudentsList(context, displayedAlumnos, hasMoreAlumnos),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.people, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Discípulos del grupo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
        const Spacer(),
        Text(
          '${alumnosGrupo.length} total',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStudentsList(
    BuildContext context, 
    List<Map<String, dynamic>> displayedAlumnos, 
    bool hasMoreAlumnos,
  ) {
    if (alumnosGrupo.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No hay discípulos en este grupo',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: displayedAlumnos.length + (hasMoreAlumnos ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (hasMoreAlumnos && index == displayedAlumnos.length) {
          return _buildShowMoreButton(context);
        }
        return _buildStudentItem(context, displayedAlumnos[index]);
      },
    );
  }

  Widget _buildShowMoreButton(BuildContext context) {
    return ListTile(
      title: Center(
        child: TextButton.icon(
          icon: const Icon(Icons.expand_more),
          label: const Text('Ver todos los discípulos'),
          onPressed: onShowAllStudents,
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildStudentItem(BuildContext context, Map<String, dynamic> alumno) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlumnoTrackingScreen(alumnoId: alumno['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  alumno['name']?.substring(0, 1) ?? '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno['name'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estado: ${alumno['status'] ?? 'Sin estado'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}