import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

/// Pantalla que muestra un indicador de carga
class LoadingScreen extends StatelessWidget {
  final String message;

  const LoadingScreen({
    Key? key, 
    this.message = 'Cargando...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}