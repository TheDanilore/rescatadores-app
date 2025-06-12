import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/domain/models/tracking_question.dart';
import 'package:rescatadores_app/domain/services/tracking_questions_service.dart';

// Importar widgets personalizados
import 'package:rescatadores_app/presentation/pages/asesor/widgets/group_header.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/week_navigator.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/students_section.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/tracking_form_section.dart';
import 'package:rescatadores_app/presentation/pages/asesor/widgets/save_tracking_button.dart';
import 'package:rescatadores_app/presentation/pages/asesor/alumno_tracking_form.dart';

class GrupoTrackingForm extends StatefulWidget {
  final String groupId;
  final String? weekId;

  const GrupoTrackingForm({super.key, required this.groupId, this.weekId});

  @override
  State<GrupoTrackingForm> createState() => _GrupoTrackingFormState();
}

class _GrupoTrackingFormState extends State<GrupoTrackingForm> {
  // Servicios y controladores
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TrackingQuestionsService _questionsService = TrackingQuestionsService();

  // Estado de la pantalla
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Datos del grupo y seguimiento
  String _grupoNombre = '';
  List<Map<String, dynamic>> _alumnosGrupo = [];
  List<TrackingQuestion> _questions = [];
  Map<String, TextEditingController> _questionControllers = {};

  // Información de usuario y autenticación
  String? _userId;
  String? _userRole;
  List<String>? _userGroups;
  late String _currentWeekId;

  // Gestión de semanas
  DateTime _selectedWeekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );
  int _currentWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      await _getUserData();
      await _loadGroupData();
      await _loadQuestions();

      // Cargar seguimiento existente o crear nuevo
      if (widget.weekId != null) {
        await _loadExistingWeekTracking();
      } else {
        await _loadSelectedWeekTracking();
      }
    } catch (e) {
      _handleError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Obtiene los datos del usuario actual y verifica sus permisos
  Future<void> _getUserData() async {
    if (!mounted) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Redirigir a inicio de sesión si no hay usuario autenticado
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _userId = currentUser.uid;
    try {
      // Obtener documento del usuario
      DocumentSnapshot userDoc =
          await _firestore.collection('users_rescatadores_app').doc(_userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userRole = userData['role'];
        _userGroups = List<String>.from(userData['groups'] ?? []);

        // Verificar permisos de acceso al grupo
        _checkGroupAccess();
      }
    } catch (e) {
      // Mostrar error si no se pueden cargar los datos del usuario
      _showErrorSnackbar('Error al cargar datos del usuario: $e');
    }
  }

  void _checkGroupAccess() {
    if (_userRole != 'administrador' &&
        !_userGroups!.contains(widget.groupId)) {
      _showErrorSnackbar('No tienes permisos para acceder a este grupo');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  SliverToBoxAdapter _buildMainContentSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupHeader(
              grupoNombre: _grupoNombre,
              alumnosCount: _alumnosGrupo.length,
            ),
            const SizedBox(height: AppTheme.spacingS),
            StudentsSection(
              alumnosGrupo: _alumnosGrupo,
              onShowAllStudents: _showAllAlumnos,
            ),
            const SizedBox(height: AppTheme.spacingS),
            WeekNavigator(
              selectedWeekStart: _selectedWeekStart,
              onPreviousWeek: () => _changeWeek(-1),
              onNextWeek: () => _changeWeek(1),
            ),
            const SizedBox(height: AppTheme.spacingS),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildFormSection() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          TrackingFormSection(
            questions: _questions,
            questionControllers: _questionControllers,
            onReload: _loadQuestions,
          ),
        ]),
      ),
    );
  }

  void _showAllAlumnos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (_, controller) => Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    children: [
                      Text(
                        'Todas las personas (${_alumnosGrupo.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: _alumnosGrupo.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder:
                              (context, index) => _buildAnimatedAlumnoItem(
                                context,
                                _alumnosGrupo[index],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildAnimatedAlumnoItem(
    BuildContext context,
    Map<String, dynamic> alumno,
  ) {
    // Verificar que el alumno tenga un ID
    if (!alumno.containsKey('id')) {
      print('ADVERTENCIA: Persona sin ID en _buildAnimatedAlumnoItem');
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AlumnoTrackingScreen(alumnoId: alumno['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  alumno['name']?.substring(0, 1) ?? '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alumno['name'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estado: ${alumno['status'] ?? 'Sin estado'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPreviousWeeks() async {
    try {
      QuerySnapshot previousTracking =
          await _firestore
              .collection('seguimientos_rescatadores_app')
              .where('groupId', isEqualTo: widget.groupId)
              .where('tipo', isEqualTo: 'grupal')
              .orderBy('timestamp', descending: true)
              .get();

      if (previousTracking.docs.isEmpty) {
        _showErrorSnackbar('No hay seguimientos previos');
        return;
      }

      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
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
                        Navigator.pop(dialogContext);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => GrupoTrackingForm(
                                  groupId: widget.groupId,
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
                  onPressed: () => Navigator.pop(dialogContext),
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

  Future<void> _loadQuestions() async {
    try {
      _questions = await _questionsService
          .getQuestionsByType('grupo')
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

  Future<void> _loadGroupData() async {
    try {
      // Primero, obtener los datos del asesor actual
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users_rescatadores_app').doc(_userId).get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;

        // Verificar si el grupo actual está en los grupos del asesor
        List<String> userGroups = List<String>.from(userData['groups'] ?? []);

        if (!userGroups.contains(widget.groupId)) {
          throw Exception('No tienes acceso a este grupo');
        }

        // Cargar información del grupo desde la colección de grupos
        DocumentSnapshot groupSnapshot =
            await _firestore.collection('groups').doc(widget.groupId).get();

        if (groupSnapshot.exists) {
          Map<String, dynamic> groupData =
              groupSnapshot.data() as Map<String, dynamic>;

          // Usar el nombre del grupo de la colección de grupos
          _grupoNombre = groupData['name'] ?? 'Grupo ${widget.groupId}';
        } else {
          // Si no existe el documento del grupo, usar el ID
          _grupoNombre = 'Grupo ${widget.groupId}';
        }

        // Cargar alumnos del grupo
        QuerySnapshot alumnosSnapshot =
            await _firestore
                .collection('users_rescatadores_app')
                .where('role', isEqualTo: 'alumno')
                .where('groups', arrayContains: widget.groupId)
                .get();

        _alumnosGrupo =
            alumnosSnapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': doc.get('name') ?? 'Sin nombre',
                    'status': doc.get('status') ?? 'Sin estado',
                  },
                )
                .toList();
      } else {
        throw Exception('Usuario no encontrado');
      }
    } catch (e) {
      _handleError(e);
    }
  }

  // Métodos de carga de seguimiento
  Future<void> _loadExistingWeekTracking() async {
    try {
      _currentWeekId = widget.weekId!;
      DocumentSnapshot trackingSnapshot =
          await _firestore.collection('seguimientos').doc(_currentWeekId).get();

      if (trackingSnapshot.exists) {
        Map<String, dynamic> data =
            trackingSnapshot.data() as Map<String, dynamic>;

        // Extraer fecha de la semana
        if (data['fechaInicio'] != null && data['fechaInicio'] is Timestamp) {
          _selectedWeekStart = (data['fechaInicio'] as Timestamp).toDate();
        }

        _updateFormFields(data);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _loadSelectedWeekTracking() async {
    try {
      _currentWeekId = _generateWeekId(_selectedWeekStart);
      DocumentSnapshot existingTrackingSnapshot =
          await _firestore.collection('seguimientos_rescatadores_app').doc(_currentWeekId).get();

      _clearFormFields();

      if (existingTrackingSnapshot.exists) {
        Map<String, dynamic> data =
            existingTrackingSnapshot.data() as Map<String, dynamic>;
        _updateFormFields(data);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _updateFormFields(Map<String, dynamic> data) {
    // Limpiar controladores
    for (var controller in _questionControllers.values) {
      controller.clear();
    }

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

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Por favor completa todos los campos requeridos');
      return;
    }

    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      DateTime weekEnd = _selectedWeekStart.add(const Duration(days: 6));

      // Preparar datos de seguimiento
      Map<String, dynamic> trackingData = {
        'groupId': widget.groupId,
        'tipo': 'grupal',
        'timestamp': FieldValue.serverTimestamp(),
        'fechaInicio': Timestamp.fromDate(_selectedWeekStart),
        'fechaFin': Timestamp.fromDate(weekEnd),
        'semana': _getWeekLabel(),
        'year': _selectedWeekStart.year,
        'weekNumber': _calculateWeekNumber(),
        'createdBy': _userId,
        'updatedBy': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Agregar respuestas de preguntas
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
      _handleError(e);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validateForm() {
    // Validar preguntas requeridas
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

  // Métodos auxiliares
  String _generateWeekId(DateTime weekStart) {
    int year = weekStart.year;
    int weekNumber = _calculateWeekNumber();
    return 'grupo_${widget.groupId}_${year}_week$weekNumber';
  }

  int _calculateWeekNumber() {
    return ((_selectedWeekStart
                    .difference(DateTime(_selectedWeekStart.year, 1, 1))
                    .inDays) /
                7)
            .floor() +
        1;
  }

  String _getWeekLabel() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    DateTime endOfWeek = _selectedWeekStart.add(const Duration(days: 6));
    return 'Semana del ${formatter.format(_selectedWeekStart)} al ${formatter.format(endOfWeek)}';
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentWeekOffset += offset;
      _selectedWeekStart = DateTime.now()
          .subtract(Duration(days: DateTime.now().weekday - 1))
          .add(Duration(days: 7 * _currentWeekOffset));
    });
    _loadSelectedWeekTracking();
  }

  // Métodos de manejo de errores y notificaciones
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

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    // Limpiar controladores
    for (var controller in _questionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // Mostrar pantalla de error si hay un problema
    if (_hasError) {
      return _buildErrorScreen();
    }

    // Pantalla principal de seguimiento
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Seguimiento de $_grupoNombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de seguimientos',
            onPressed: _showPreviousWeeks,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [_buildMainContentSection(), _buildFormSection()],
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
              'Cargando información del grupo...',
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
          padding: const EdgeInsets.all(16.0),
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
}
