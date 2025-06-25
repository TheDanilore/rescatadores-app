import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

class GroupHeader extends StatelessWidget {
  final String grupoNombre;
  final int alumnosCount;

  const GroupHeader({
    Key? key,
    required this.grupoNombre,
    required this.alumnosCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              radius: 30,
              child: Text(
                grupoNombre.isNotEmpty ? grupoNombre.substring(0, 1) : '?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grupoNombre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '$alumnosCount personas',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
