import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';

/// Muestra un diálogo con los detalles de un seguimiento
Future<void> showSeguimientoDetailsDialog({
  required BuildContext context,
  required Map<String, dynamic> seguimiento,
  required String tipo,
  required VoidCallback onExport,
}) async {
  // Obtener los títulos de las preguntas desde Firestore, ordenados
  Map<String, String> questionTitles = {};
  try {
    final questionsSnapshot =
        await FirebaseFirestore.instance
            .collection('tracking_questions_rescatadores_app')
            .where('type', isEqualTo: tipo == 'individual' ? 'alumno' : 'grupo')
            .where('isActive', isEqualTo: true)
            .orderBy('number')
            .get();

    for (var doc in questionsSnapshot.docs) {
      questionTitles[doc.id] = doc.data()['title'] ?? 'Pregunta sin título';
    }
  } catch (e) {
    print('Error al cargar títulos de preguntas: $e');
  }

  // Extraer preguntas y respuestas del seguimiento, ordenadas por número de pregunta
  Map<String, dynamic> data = seguimiento['data'] ?? {};
  List<MapEntry<String, dynamic>> questionsData =
      data.entries.where((entry) => entry.key.startsWith('question_')).toList();

  // Crear un mapa auxiliar con el orden real de cada pregunta
  Map<String, int> questionOrderMap = {};
  try {
    final questionsSnapshot =
        await FirebaseFirestore.instance
            .collection('tracking_questions_rescatadores_app')
            .where('type', isEqualTo: tipo == 'individual' ? 'alumno' : 'grupo')
            .where('isActive', isEqualTo: true)
            .orderBy('order') // <- Usa este campo para el orden
            .get();

    for (var doc in questionsSnapshot.docs) {
      final data = doc.data();
      final id = doc.id;
final title = data['title']?.toString() ?? 'Pregunta sin título';
      final order = data['order'] ?? 999; // valor por defecto si no hay

      questionTitles[id] = title;
      questionOrderMap[id] = order;
    }
  } catch (e) {
    print('Error al cargar títulos de preguntas: $e');
  }

  // Ordenar las preguntas según el campo `order`
  questionsData.sort((a, b) {
    String aId = a.key.replaceAll('question_', '');
    String bId = b.key.replaceAll('question_', '');

    int aOrder = questionOrderMap[aId] ?? 999;
    int bOrder = questionOrderMap[bId] ?? 999;

    return aOrder.compareTo(bOrder);
  });

  String title =
      tipo == 'individual'
          ? seguimiento['alumnoName']
          : seguimiento['groupName'];

  return showDialog(
    context: context,
    builder:
        (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      tipo == 'individual' ? Icons.person : Icons.group,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            seguimiento['semana'] ?? 'Semana sin fecha',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      questionsData.isEmpty
                          ? Center(
                            child: Text(
                              'No hay respuestas registradas',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                          : ListView.builder(
                            itemCount: questionsData.length,
                            itemBuilder: (context, index) {
                              final entry = questionsData[index];
                              final questionId = entry.key.replaceAll(
                                'question_',
                                '',
                              );

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        questionTitles[questionId] ??
                                            'Pregunta ${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          entry.value?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onExport,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
  );
}
