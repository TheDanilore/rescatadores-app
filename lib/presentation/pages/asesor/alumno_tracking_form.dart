import 'package:rescatadores_app/presentation/pages/asesor/widgets/alumno_header.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';
import 'package:rescatadores_app/domain/services/tracking_questions_service.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/week_navigator.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/tracking_form_section.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/save_tracking_button.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/alumno_details_modal.dart';

class AlumnoTrackingScreen extends StatefulWidget {
  final String alumnoId;
  final String? weekId;

  const AlumnoTrackingScreen({super.key, required this.alumnoId, this.weekId});

  @override
  State<AlumnoTrackingScreen> createState() => _AlumnoTrackingScreenState();
}

class _AlumnoTrackingScreenState extends State<AlumnoTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TrackingQuestionsService _questionsService = TrackingQuestionsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TrackingQuestion> _questions = [];
  Map<String, TextEditingController> _questionControllers = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';

  Map<String, dynamic> _alumnoData = {};
  late String _currentWeekId;

  DateTime _selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _loadAlumnoData();
      await _loadQuestions();

      if (widget.weekId != null) {
        await _loadExistingWeekTracking();
      } else {
        await _loadSelectedWeekTracking();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadExistingWeekTracking() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Obtener el seguimiento existente de Firestore
      DocumentSnapshot trackingSnapshot =
          await _firestore.collection('seguimientos_rescatadores_app').doc(widget.weekId).get();

      if (trackingSnapshot.exists) {
        Map<String, dynamic> data =
            trackingSnapshot.data() as Map<String, dynamic>;

        // Actualizar campos del formulario con los datos existentes
        _updateFormFields(data);

        // Establecer la semana seleccionada según los datos existentes
        Timestamp fechaInicio = data['fechaInicio'];
        _selectedWeekStart = fechaInicio.toDate();
      } else {
        // Manejar el caso cuando no se encuentra el seguimiento existente
        _showErrorSnackbar('No se encontró el seguimiento para esta semana');
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      _questions = await _questionsService
          .getQuestionsByType('alumno')
          .then((questions) => questions.where((q) => q.isActive).toList());

      // Inicializar controladores para preguntas activas
      _questionControllers.clear();
      for (var question in _questions) {
        _questionControllers[question.id] = TextEditingController();
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadAlumnoData() async {
    if (!mounted) return;

    try {
      DocumentSnapshot alumnoSnapshot =
          await _firestore.collection('users_rescatadores_app').doc(widget.alumnoId).get();

      if (!mounted) return;

      if (alumnoSnapshot.exists) {
        setState(() {
          _alumnoData = alumnoSnapshot.data() as Map<String, dynamic>;
          _alumnoData['id'] = widget.alumnoId;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró información del Persona'),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos del Persona: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _handleError(dynamic error) {
    setState(() {
      _hasError = true;
      _errorMessage = error.toString();
      _isLoading = false;
    });
    _showErrorSnackbar(error.toString());
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Corregir el error de múltiples returns
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seguimiento de ${_alumnoData['name'] ?? 'Persona'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: 'Detalles del Persona',
            onPressed:
                () => AlumnoDetailsModal.show(
                  context,
                  _alumnoData,
                  alumnoId: widget.alumnoId, // Pasar el ID explícitamente
                ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Seguimientos',
            onPressed: _showPreviousWeeks,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AlumnoHeader(alumnoData: _alumnoData),
                    const SizedBox(height: 16),
                    WeekNavigator(
                      selectedWeekStart: _selectedWeekStart,
                      onPreviousWeek: () => _changeWeek(-1),
                      onNextWeek: () => _changeWeek(1),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  TrackingFormSection(
                    questions: _questions,
                    questionControllers: _questionControllers,
                    onReload: _loadQuestions, // Añadir método de recarga
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SaveTrackingButton(
        isSaving: _isSaving,
        onSave: _saveForm,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Cargando información del Persona...',
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

  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.red),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              Text(
                'Ocurrió un error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateRequiredQuestions() {
    for (var question in _questions) {
      if (question.isRequired) {
        final controller = _questionControllers[question.id];
        if (controller == null || controller.text.trim().isEmpty) {
          _showErrorSnackbar(
            'Por favor complete la pregunta requerida: ${question.title}',
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _saveForm() async {
    // Verificar si al menos una pregunta tiene respuesta
    bool hasAnswer = _questionControllers.values.any(
      (controller) => controller.text.trim().isNotEmpty,
    );

    if (!hasAnswer) {
      _showErrorSnackbar(
        'Por favor responde al menos una pregunta antes de guardar',
      );
      return;
    }

    if (!_validateRequiredQuestions()) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Por favor completa todos los campos requeridos');
      return;
    }

    setState(() => _isSaving = true);

    try {
      DateTime weekEnd = _selectedWeekStart.add(const Duration(days: 6));

      // Preparar datos de seguimiento
      Map<String, dynamic> trackingData = {
        'alumnoId': widget.alumnoId,
        'tipo': 'individual',
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid,
        'fechaInicio': Timestamp.fromDate(_selectedWeekStart),
        'fechaFin': Timestamp.fromDate(weekEnd),
        'year': _selectedWeekStart.year,
        'weekNumber': _getWeekNumber(_selectedWeekStart),
        'semana': _getWeekLabel(),
      };

      // Agregar datos de cada pregunta
      for (var question in _questions) {
        final fieldId = 'question_${question.id}';
        trackingData[fieldId] = _questionControllers[question.id]?.text ?? '';
      }

      // Guardar en Firestore
      await _firestore
          .collection('seguimientos_rescatadores_app')
          .doc(_currentWeekId)
          .set(trackingData, SetOptions(merge: true));

      _showSuccessSnackbar('Seguimiento guardado correctamente');
    } catch (e) {
      _showErrorSnackbar('Error al guardar seguimiento: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _loadSelectedWeekTracking() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Generar ID para la semana seleccionada
      _currentWeekId = _generateWeekId(_selectedWeekStart);

      // Verificar si ya existe un seguimiento para esta semana
      DocumentSnapshot existingTrackingSnapshot =
          await _firestore.collection('seguimientos_rescatadores_app').doc(_currentWeekId).get();

      // Limpiar campos
      _clearFormFields();

      if (existingTrackingSnapshot.exists) {
        Map<String, dynamic> data =
            existingTrackingSnapshot.data() as Map<String, dynamic>;
        _updateFormFields(data);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateFormFields(Map<String, dynamic> data) {
    // Limpiar controladores
    _clearFormFields();

    // Actualizar valores desde Firestore
    for (var question in _questions) {
      final fieldId = 'question_${question.id}';
      if (data.containsKey(fieldId)) {
        _questionControllers[question.id]?.text = data[fieldId] ?? '';
      }
    }
  }

  void _clearFormFields() {
    for (var controller in _questionControllers.values) {
      controller.clear();
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _selectedWeekStart = _selectedWeekStart.add(Duration(days: 7 * offset));
    });

    _loadSelectedWeekTracking();
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat('D').format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  String _getWeekLabel() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    DateTime endOfWeek = _selectedWeekStart.add(const Duration(days: 6));
    return 'Semana del ${formatter.format(_selectedWeekStart)} al ${formatter.format(endOfWeek)}';
  }

  String _generateWeekId([DateTime? date]) {
    DateTime weekStart = date ?? _selectedWeekStart;
    int year = weekStart.year;
    int weekNumber = _getWeekNumber(weekStart);
    return 'alumno_${widget.alumnoId}_${year}_week$weekNumber';
  }

  Future<void> _showPreviousWeeks() async {
    try {
      QuerySnapshot previousTracking =
          await _firestore
              .collection('seguimientos_rescatadores_app')
              .where('alumnoId', isEqualTo: widget.alumnoId)
              .where('tipo', isEqualTo: 'individual')
              .orderBy('timestamp', descending: true)
              .get();

      if (previousTracking.docs.isEmpty) {
        _showErrorSnackbar('No hay seguimientos previos');
        return;
      }

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Seguimientos Anteriores'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: previousTracking.docs.length,
                  itemBuilder: (context, index) {
                    var tracking = previousTracking.docs[index];
                    return ListTile(
                      title: Text(tracking['semana'] ?? 'Semana sin fecha'),
                      subtitle: Text(
                        'Última actualización: ${_formatTimestamp(tracking['timestamp'])}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AlumnoTrackingScreen(
                                  alumnoId: widget.alumnoId,
                                  weekId: tracking.id,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
      );
    } catch (e) {
      print('Error al cargar seguimientos anteriores: $e');
      _showErrorSnackbar('Error al cargar seguimientos anteriores: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Fecha desconocida';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else {
      return 'Fecha desconocida';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  @override
  void dispose() {
    // Limpiar controladores
    for (var controller in _questionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
