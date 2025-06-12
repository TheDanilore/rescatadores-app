import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';

/// Widget para mostrar una tarjeta de pregunta de seguimiento
class QuestionCard extends StatelessWidget {
  final TrackingQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const QuestionCard({
    Key? key,
    required this.question,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key(question.id),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        side: BorderSide(
          color: question.isActive ? Colors.transparent : Colors.red.shade200,
          width: question.isActive ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${question.number}. ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      question.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            question.isActive
                                ? AppTheme.textPrimaryColor
                                : Colors.grey,
                      ),
                    ),
                  ),
                  if (!question.isActive)
                    _buildStatusBadge('Inactiva', Colors.red),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Instrucción: ${question.hint}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  if (question.isRequired)
                    _buildStatusBadge('Obligatorio', Colors.blue),
                  const Spacer(),
                  _buildActionButton(
                    icon: Icons.edit,
                    color: Colors.blue,
                    tooltip: 'Editar',
                    onPressed: onEdit,
                  ),
                  _buildActionButton(
                    icon:
                        question.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                    color: question.isActive ? Colors.orange : Colors.green,
                    tooltip: question.isActive ? 'Desactivar' : 'Activar',
                    onPressed: onToggleStatus,
                  ),
                  _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.red,
                    tooltip: 'Eliminar',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );
  }
}

/// Widget para mostrar un mensaje cuando no hay preguntas
class EmptyQuestionsView extends StatelessWidget {
  final String type;
  final VoidCallback onAddPressed;

  const EmptyQuestionsView({
    Key? key,
    required this.type,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(
              24.0,
            ), // Valor directo en lugar de AppTheme.spacingL
            decoration: BoxDecoration(
              color: const Color(0xFFE6F3FF), // Color azul muy claro explícito
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: const Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: Color(0xFF64B5F6), // Azul claro explícito
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            'No hay preguntas para ${type == 'grupo' ? 'grupos' : 'personas'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242), // Gris oscuro explícito
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Agrega preguntas para personalizar el seguimiento',
            style: TextStyle(
              color: Color(0xFF757575), // Gris medio explícito
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add),
            label: const Text('Agregar pregunta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF1E90FF,
              ), // Color primario explícito
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

/// Formulario para crear o editar preguntas
class QuestionForm extends StatefulWidget {
  final TrackingQuestion? question;
  final String type;
  final ValueChanged<Map<String, dynamic>> onSave;
  final VoidCallback onCancel;

  const QuestionForm({
    Key? key,
    this.question,
    required this.type,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _hintController;
  late final TextEditingController _maxLinesController;
  late bool _isRequired;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.question != null;
    _numberController = TextEditingController(
      text: isEditing ? widget.question!.number : '',
    );
    _titleController = TextEditingController(
      text: isEditing ? widget.question!.title : '',
    );
    _hintController = TextEditingController(
      text: isEditing ? widget.question!.hint : '',
    );
    _maxLinesController = TextEditingController(
      text: isEditing ? widget.question!.maxLines.toString() : '3',
    );
    _isRequired = isEditing ? widget.question!.isRequired : false;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _hintController.dispose();
    _maxLinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeIndicator(),
          const SizedBox(height: AppTheme.spacingM),
          _buildNumberField(),
          const SizedBox(height: AppTheme.spacingM),
          _buildTitleField(),
          const SizedBox(height: AppTheme.spacingM),
          _buildHintField(),
          const SizedBox(height: AppTheme.spacingM),
          _buildMaxLinesField(),
          const SizedBox(height: AppTheme.spacingM),
          _buildRequiredCheckbox(),
          const SizedBox(height: AppTheme.spacingL),
          _buildFormActions(isEditing),
        ],
      ),
    );
  }

  Widget _buildTypeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.type == 'grupo' ? Icons.group : Icons.person,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Text(
            'Tipo: ${widget.type == 'grupo' ? 'Grupo' : 'Individual'}',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      controller: _numberController,
      decoration: const InputDecoration(
        labelText: 'Número',
        hintText: 'Ej: 1, 2, 3.1, etc.',
        prefixIcon: Icon(Icons.format_list_numbered),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un número';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Título',
        hintText: 'Título de la pregunta',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un título';
        }
        return null;
      },
    );
  }

  Widget _buildHintField() {
    return TextFormField(
      controller: _hintController,
      decoration: const InputDecoration(
        labelText: 'Instrucción o ayuda',
        hintText: 'Texto de ayuda para responder la pregunta',
        prefixIcon: Icon(Icons.help_outline),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un texto de ayuda';
        }
        return null;
      },
    );
  }

  Widget _buildMaxLinesField() {
    return TextFormField(
      controller: _maxLinesController,
      decoration: const InputDecoration(
        labelText: 'Líneas de texto (altura)',
        hintText: 'Número de líneas para el campo de texto',
        prefixIcon: Icon(Icons.height),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa el número de líneas';
        }
        final parsedValue = int.tryParse(value);
        if (parsedValue == null || parsedValue < 1) {
          return 'El valor debe ser un número mayor a 0';
        }
        return null;
      },
    );
  }

  Widget _buildRequiredCheckbox() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        onTap: () {
          setState(() {
            _isRequired = !_isRequired;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
          child: Row(
            children: [
              Checkbox(
                value: _isRequired,
                onChanged: (value) {
                  setState(() {
                    _isRequired = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingS),
              const Text(
                'Campo obligatorio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: AppTheme.spacingS),
              const Tooltip(
                message:
                    'Si se marca, el usuario deberá completar este campo obligatoriamente',
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormActions(bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: widget.onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: AppTheme.spacingM),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isEditing ? Icons.save : Icons.add),
              const SizedBox(width: AppTheme.spacingS),
              Text(isEditing ? 'Guardar cambios' : 'Crear pregunta'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'number': _numberController.text,
        'title': _titleController.text,
        'hint': _hintController.text,
        'maxLines': int.tryParse(_maxLinesController.text) ?? 3,
        'isRequired': _isRequired,
      });
    }
  }
}

/// Diálogo de confirmación para eliminar preguntas
class DeleteConfirmationDialog extends StatelessWidget {
  final String questionTitle;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteConfirmationDialog({
    Key? key,
    required this.questionTitle,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(Icons.delete, color: Colors.red.shade800),
          ),
          const SizedBox(width: AppTheme.spacingM),
          const Text('Eliminar Pregunta'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Estás seguro de eliminar la siguiente pregunta?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '"$questionTitle"',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            'Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: onConfirm,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
