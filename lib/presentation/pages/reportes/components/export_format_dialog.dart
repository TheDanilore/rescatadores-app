import 'package:flutter/material.dart';

/// Muestra un diálogo para seleccionar el formato de exportación
Future<String?> showExportFormatDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Seleccionar formato'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('CSV'),
            onTap: () {
              Navigator.pop(context, 'csv');
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Excel'),
            onTap: () {
              Navigator.pop(context, 'excel');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.picture_as_pdf),
          //   title: const Text('PDF'),
          //   onTap: () {
          //     Navigator.pop(context, 'pdf');
          //   },
          // ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}