import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rescatadores_app/config/theme.dart';

/// Muestra un diálogo para filtrar los reportes
Future<Map<String, dynamic>?> showFilterDialog({
  required BuildContext context,
  required String selectedReportType,
  required DateTime startDate,
  required DateTime endDate,
  required List<String> selectedGroups,
  required List<Map<String, dynamic>> groupsList,
  required bool isAdministrador,
}) async {
  String tempSelectedReportType = selectedReportType;
  DateTime tempStartDate = startDate;
  DateTime tempEndDate = endDate;
  List<String> tempSelectedGroups = List.from(selectedGroups);

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filtrar seguimientos'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Rango de fechas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null && picked != tempStartDate) {
                              setState(() {
                                tempStartDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Desde',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(tempStartDate),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.primaryColor,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null && picked != tempEndDate) {
                              setState(() {
                                tempEndDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Hasta',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(tempEndDate),
                                ),
                                const Icon(Icons.calendar_today, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isAdministrador && groupsList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Grupos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Seleccionar todos'),
                              Checkbox(
                                value: tempSelectedGroups.length == groupsList.length,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      tempSelectedGroups = groupsList
                                          .map((group) => group['id'] as String)
                                          .toList();
                                    } else {
                                      tempSelectedGroups = [];
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          const Divider(),
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: groupsList.length,
                              itemBuilder: (context, index) {
                                final group = groupsList[index];
                                final groupId = group['id'] as String;
                                final isSelected = tempSelectedGroups.contains(groupId);
                                
                                return CheckboxListTile(
                                  title: Text(group['name']),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        if (!tempSelectedGroups.contains(groupId)) {
                                          tempSelectedGroups.add(groupId);
                                        }
                                      } else {
                                        tempSelectedGroups.remove(groupId);
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  activeColor: AppTheme.primaryColor,
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validar que hay al menos un grupo seleccionado
                  if (isAdministrador && tempSelectedGroups.isEmpty && groupsList.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona al menos un grupo'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  // Validar que la fecha de inicio no sea posterior a la fecha de fin
                  if (tempStartDate.isAfter(tempEndDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La fecha de inicio no puede ser posterior a la fecha de fin'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'selectedReportType': tempSelectedReportType,
                    'startDate': tempStartDate,
                    'endDate': tempEndDate,
                    'selectedGroups': tempSelectedGroups,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      );
    },
  );
}