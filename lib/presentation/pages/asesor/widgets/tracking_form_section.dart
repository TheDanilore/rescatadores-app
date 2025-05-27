import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';

class TrackingFormSection extends StatelessWidget {
  final List<TrackingQuestion> questions;
  final Map<String, TextEditingController> questionControllers;
  final VoidCallback? onReload;

  const TrackingFormSection({
    super.key,
    required this.questions,
    required this.questionControllers,
    this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: questions.isEmpty
            ? _buildEmptyQuestionsView(context)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: questions
                    .map((question) => _buildQuestionField(context, question))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyQuestionsView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No hay preguntas configuradas',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (onReload != null)
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              onPressed: onReload,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionField(BuildContext context, TrackingQuestion question) {
    final controller = questionControllers[question.id];
    if (controller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionHeader(context, question),
          const SizedBox(height: AppTheme.spacingS),
          TextFormField(
            controller: controller,
            decoration: _buildInputDecoration(context, question),
            maxLines: question.maxLines,
            minLines: question.maxLines,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              fontSize: 16, 
              color: Colors.black87, 
              height: 1.5
            ),
            validator: question.isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Este campo es obligatorio';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(BuildContext context, TrackingQuestion question) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${question.number}. ${question.title}${question.isRequired ? ' *' : ''}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildQuestionTooltip(context, question),
      ],
    );
  }

  Widget _buildQuestionTooltip(BuildContext context, TrackingQuestion question) {
    return Tooltip(
      message: question.hint,
      triggerMode: TooltipTriggerMode.tap,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Icon(
        Icons.info_outline,
        color: AppTheme.primaryColor.withOpacity(0.6),
        size: 20,
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, TrackingQuestion question) {
    return InputDecoration(
      hintText: question.hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 14,
        height: 1.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
    );
  }
}