import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

class SaveTrackingButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const SaveTrackingButton({
    Key? key,
    required this.isSaving,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isSaving ? null : onSave,
      backgroundColor: AppTheme.primaryColor,
      icon: _buildButtonIcon(),
      label: Text(
        isSaving ? 'Guardando...' : 'Guardar Seguimiento',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildButtonIcon() {
    return isSaving
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.save);
  }
}