import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rescatadores_app/config/theme.dart';

class WeekNavigator extends StatelessWidget {
  final DateTime selectedWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const WeekNavigator({
    Key? key,
    required this.selectedWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
  }) : super(key: key);

  String _getWeekLabel() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    DateTime endOfWeek = selectedWeekStart.add(const Duration(days: 6));
    return 'Semana del ${formatter.format(selectedWeekStart)} al ${formatter.format(endOfWeek)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingS,
          horizontal: AppTheme.spacingM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la semana',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: onPreviousWeek,
                  tooltip: 'Semana anterior',
                ),
                Expanded(
                  child: Text(
                    _getWeekLabel(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: onNextWeek,
                  tooltip: 'Semana siguiente',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}