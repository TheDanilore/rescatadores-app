import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

/// Widget que muestra un mensaje cuando no hay datos
class EmptyState extends StatelessWidget {
  final String message;
  final VoidCallback onActionPressed;
  final String actionLabel;
  final IconData icon;

  const EmptyState({
    super.key,
    required this.message,
    required this.onActionPressed,
    this.actionLabel = 'Cambiar filtros',
    this.icon = Icons.search_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FF),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'No hay seguimientos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF757575),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            onPressed: onActionPressed,
            icon: const Icon(Icons.filter_alt),
            label: Text(actionLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}