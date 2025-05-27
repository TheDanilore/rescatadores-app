import 'package:flutter/material.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';
import 'package:rescatadores_app/domain/services/tracking_questions_service.dart';
import 'package:rescatadores_app/presentation/widgets/tracking_question_widgets.dart';

class TrackingQuestionsScreen extends StatefulWidget {
  const TrackingQuestionsScreen({super.key});

  @override
  State<TrackingQuestionsScreen> createState() =>
      _TrackingQuestionsScreenState();
}

class _TrackingQuestionsScreenState extends State<TrackingQuestionsScreen>
    with SingleTickerProviderStateMixin {
  final TrackingQuestionsService _questionsService = TrackingQuestionsService();

  late TabController _tabController;
  List<TrackingQuestion> _allQuestions = [];
  List<TrackingQuestion> _groupQuestions = [];
  List<TrackingQuestion> _studentQuestions = [];

  bool _isLoading = true;
  bool _isDragging = false;

  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Primero verificar y crear preguntas predeterminadas si no existen
      await _questionsService.createDefaultQuestionsIfNeeded();

      // Luego cargar todas las preguntas
      _allQuestions = await _questionsService.getAllQuestions();

      // Filtrar preguntas por tipo
      _groupQuestions =
          _allQuestions.where((q) => q.type == 'grupo').toList()
            ..sort((a, b) => a.order.compareTo(b.order));
      _studentQuestions =
          _allQuestions.where((q) => q.type == 'alumno').toList()
            ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al cargar preguntas: $e';
        });
      }
      _showErrorSnackbar('Error al cargar preguntas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar las preguntas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar nuevamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E90FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight), // Altura estándar
        child: AppBar(
          backgroundColor: const Color(0xFF1E90FF),
          elevation: 0,
          automaticallyImplyLeading: false, // Quita el botón de retroceso
          flexibleSpace: SafeArea(
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'Preguntas para Grupos', icon: Icon(Icons.group)),
                Tab(text: 'Preguntas para Discípulos', icon: Icon(Icons.person)),
              ],
            ),
          ),
          actions: [
            if (!_isLoading && !_hasError)
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.add_circle, size: 30),
                  tooltip: 'Agregar pregunta',
                  onPressed: () => _showQuestionDialog(
                    null,
                    _tabController.index == 0 ? 'grupo' : 'alumno',
                  ),
                ),
              ),
          ],
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingIndicator()
              : _hasError
              ? _buildErrorView()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestionsTab(_groupQuestions, 'grupo'),
                  _buildQuestionsTab(_studentQuestions, 'alumno'),
                ],
              ),
    );
  }

  void _showErrorSnackbar(String message) {
    // Intenta extraer el mensaje de error más detallado
    String errorDetail = message;
    if (message.contains('Exception:')) {
      errorDetail = message.split('Exception:').last.trim();
    } else if (message.contains('Error:')) {
      errorDetail = message.split('Error:').last.trim();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    errorDetail,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _createQuestion(TrackingQuestion question) async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final questionId = await _questionsService.createQuestion(question);

      if (questionId != null) {
        await _loadQuestions();
        if (mounted) {
          _showSuccessSnackbar('Pregunta creada correctamente');
        }
      } else {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage =
                'No se pudo crear la pregunta. Verifica los permisos de Firestore.';
          });
          _showErrorSnackbar('Error al crear la pregunta: No se recibió ID');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error al crear la pregunta: $e';
        });
        _showErrorSnackbar('Error al crear pregunta: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF1E90FF),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando preguntas...',
            style: TextStyle(
              color: const Color(0xFF1E90FF),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab(List<TrackingQuestion> questions, String type) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child:
          questions.isEmpty
              ? EmptyQuestionsView(
                  type: type,
                  onAddPressed: () => _showQuestionDialog(null, type),
                )
              : _buildQuestionsList(questions, type),
    );
  }

  Widget _buildQuestionsList(List<TrackingQuestion> questions, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Icon(
                type == 'grupo' ? Icons.group : Icons.person,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Preguntas disponibles (${questions.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadQuestions,
            color: const Color(0xFF1E90FF),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ReorderableListView.builder(
                onReorder:
                    (oldIndex, newIndex) =>
                        _reorderQuestions(oldIndex, newIndex, questions, type),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return QuestionCard(
                    key: Key(question.id),
                    question: question,
                    onEdit: () => _showQuestionDialog(question, question.type),
                    onToggleStatus: () => _toggleQuestionStatus(question),
                    onDelete: () => _confirmDeleteQuestion(question),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showQuestionDialog(
    TrackingQuestion? existingQuestion,
    String type,
  ) async {
    final isEditing = existingQuestion != null;

    // Determinar el orden para una nueva pregunta
    int newOrder = 0;
    if (!isEditing) {
      final relevantQuestions =
          type == 'grupo' ? _groupQuestions : _studentQuestions;
      if (relevantQuestions.isNotEmpty) {
        newOrder =
            relevantQuestions
                .map((q) => q.order)
                .reduce((a, b) => a > b ? a : b) +
            1;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar Pregunta' : 'Nueva Pregunta',
                    style: const TextStyle(
                      color: Color(0xFF1E90FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: QuestionForm(
                        question: existingQuestion,
                        type: type,
                        onCancel: () => Navigator.of(context).pop(),
                        onSave: (formData) {
                          Navigator.of(context).pop();

                          if (isEditing) {
                            final updatedQuestion = existingQuestion.copyWith(
                              number: formData['number'],
                              title: formData['title'],
                              hint: formData['hint'],
                              maxLines: formData['maxLines'],
                              isRequired: formData['isRequired'],
                            );

                            _updateQuestion(updatedQuestion);
                          } else {
                            // Crear nueva pregunta
                            final newQuestion = TrackingQuestion(
                              id: 'temp_id', // Se reemplazará al guardar
                              number: formData['number'],
                              title: formData['title'],
                              hint: formData['hint'],
                              maxLines: formData['maxLines'],
                              isRequired: formData['isRequired'],
                              order: newOrder,
                              type: type,
                            );

                            _createQuestion(newQuestion);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _confirmDeleteQuestion(TrackingQuestion question) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        questionTitle: question.title,
        onConfirm: () {
          Navigator.of(context).pop();
          _deleteQuestion(question);
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _updateQuestion(TrackingQuestion question) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _questionsService.updateQuestion(question);

      if (success) {
        await _loadQuestions();
        if (mounted) {
          _showSuccessSnackbar('Pregunta actualizada correctamente');
        }
      } else {
        if (mounted) {
          _showErrorSnackbar('Error al actualizar la pregunta');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleQuestionStatus(TrackingQuestion question) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final updatedQuestion = question.copyWith(isActive: !question.isActive);
      final success = await _questionsService.updateQuestion(updatedQuestion);

      if (success) {
        await _loadQuestions();
        if (mounted) {
          _showSuccessSnackbar(
            question.isActive ? 'Pregunta desactivada' : 'Pregunta activada',
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackbar('Error al cambiar el estado de la pregunta');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion(TrackingQuestion question) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _questionsService.deleteQuestion(question.id);

      if (success) {
        await _loadQuestions();
        if (mounted) {
          _showSuccessSnackbar('Pregunta eliminada correctamente');
        }
      } else {
        if (mounted) {
          _showErrorSnackbar('Error al eliminar la pregunta');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _reorderQuestions(
    int oldIndex,
    int newIndex,
    List<TrackingQuestion> questions,
    String type,
  ) {
    setState(() {
      _isDragging = true;

      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      final item = questions.removeAt(oldIndex);
      questions.insert(newIndex, item);

      // Actualizar el orden de todas las preguntas
      for (var i = 0; i < questions.length; i++) {
        questions[i] = questions[i].copyWith(order: i);
      }

      // Actualizar las listas según el tipo
      if (type == 'grupo') {
        _groupQuestions = List.from(questions);
      } else {
        _studentQuestions = List.from(questions);
      }

      _isDragging = false;
    });

    // Mostrar un indicador de progreso mientras se guarda
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardando nuevo orden...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Guardar el nuevo orden en Firestore
    _questionsService
        .reorderQuestions(questions)
        .then((_) {
          if (mounted) {
            _showSuccessSnackbar('Orden actualizado correctamente');
          }
        })
        .catchError((e) {
          if (mounted) {
            _showErrorSnackbar('Error al guardar el nuevo orden: $e');
          }
        });
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}