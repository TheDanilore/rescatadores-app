import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rescatadores_app/domain/services/export_service.dart';

/// Controlador para la pantalla de reportes que maneja la lógica de negocio
class ReportesController extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ExportService _exportService = ExportService();

  // Estado
  bool _isLoading = true;
  bool _isExporting = false;
  bool _hasError = false;
  bool _isLoadingFilters = false;
  String _errorMessage = '';
  bool _disposed =
      false; // Flag para verificar si el controlador ya fue desechado

  // Datos del usuario
  String? _userId;
  String? _userRole;
  List<String> _userGroups = [];

  // Filtros de búsqueda
  String _selectedReportType = 'todos';
  List<String> _selectedGroups = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Datos para mostrar
  List<Map<String, dynamic>> _groupsList = [];
  List<Map<String, dynamic>> _seguimientosGrupales = [];
  List<Map<String, dynamic>> _seguimientosIndividuales = [];

  // Cache para nombres de grupos
  final Map<String, String> _groupNamesCache = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  bool get hasError => _hasError;
  bool get isLoadingFilters => _isLoadingFilters;
  String get errorMessage => _errorMessage;
  String get selectedReportType => _selectedReportType;
  List<String> get selectedGroups => _selectedGroups;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<Map<String, dynamic>> get groupsList => _groupsList;
  List<Map<String, dynamic>> get seguimientosGrupales => _seguimientosGrupales;
  List<Map<String, dynamic>> get seguimientosIndividuales =>
      _seguimientosIndividuales;
  bool get isAdministrador => _userRole == 'administrador';

  ReportesController({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> initializeData() async {
    if (_disposed) return;

    setLoading(true);
    setError(false, '');

    try {
      await _getUserData();
      await _loadGroups();
      await loadSeguimientos();
    } catch (e) {
      if (!_disposed) {
        setError(true, 'Error al cargar datos: $e');
        print('Error al cargar datos: $e');
      }
    } finally {
      if (!_disposed) {
        setLoading(false);
      }
    }
  }

  Future<void> _getUserData() async {
    if (_disposed) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    _userId = currentUser.uid;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_userId).get();

      if (_disposed) return;

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _userRole = userData['role'];

        if (_userRole != 'administrador' && userData['groups'] != null) {
          _userGroups = List<String>.from(userData['groups']);
        }
      }
    } catch (e) {
      print('Error al obtener datos del usuario: $e');
      throw Exception('Error al obtener datos del usuario: $e');
    }
  }

  Future<void> _loadGroups() async {
    if (_disposed) return;

    _groupsList = [];

    try {
      if (_userRole == 'administrador') {
        // Administrador puede ver todos los grupos
        QuerySnapshot groupsQuery = await _firestore.collection('groups').get();

        if (_disposed) return;

        for (var doc in groupsQuery.docs) {
          _groupsList.add({
            'id': doc.id,
            'name': doc['name'] ?? 'Grupo sin nombre',
          });

          // Guardar en caché
          _groupNamesCache[doc.id] = doc['name'] ?? 'Grupo sin nombre';
        }
      } else {
        // Asesores solo ven sus grupos asignados
        for (String groupId in _userGroups) {
          if (_disposed) return;

          try {
            DocumentSnapshot groupDoc =
                await _firestore.collection('groups').doc(groupId).get();

            if (_disposed) return;

            if (groupDoc.exists) {
              String groupName = groupDoc['name'] ?? 'Grupo $groupId';
              _groupsList.add({'id': groupId, 'name': groupName});

              // Guardar en caché
              _groupNamesCache[groupId] = groupName;
            }
          } catch (e) {
            print('Error al cargar grupo $groupId: $e');
            // Continuar con el siguiente grupo
          }
        }
      }

      // Si no hay grupos seleccionados, seleccionar todos por defecto
      if (_selectedGroups.isEmpty && _groupsList.isNotEmpty) {
        _selectedGroups =
            _groupsList.map((group) => group['id'] as String).toList();
      }
    } catch (e) {
      print('Error al cargar grupos: $e');
      throw Exception('Error al cargar grupos: $e');
    }
  }

  Future<void> loadSeguimientos() async {
    if (_disposed) return;

    _seguimientosGrupales = [];
    _seguimientosIndividuales = [];

    // Convertir fechas a Timestamp
    Timestamp startTimestamp = Timestamp.fromDate(_startDate);
    Timestamp endTimestamp = Timestamp.fromDate(
      _endDate.add(const Duration(days: 1)),
    );

    // 1. Cargar seguimientos grupales
    try {
      Query seguimientosQuery = _firestore
          .collection('seguimientos')
          .where('tipo', isEqualTo: 'grupal')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThan: endTimestamp);

      if (_userRole != 'administrador') {
        // Filtrar por grupos del asesor
        if (_userGroups.isEmpty) {
          // No hay grupos asignados
          notifyListeners();
          return;
        }
        seguimientosQuery = seguimientosQuery.where(
          'groupId',
          whereIn: _userGroups,
        );
      } else if (_selectedGroups.isNotEmpty) {
        // Filtrar por grupos seleccionados (solo para administrador)
        seguimientosQuery = seguimientosQuery.where(
          'groupId',
          whereIn: _selectedGroups,
        );
      }

      QuerySnapshot seguimientosGrupalesQuery = await seguimientosQuery.get();

      if (_disposed) return;

      for (var doc in seguimientosGrupalesQuery.docs) {
        if (_disposed) return;

        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String groupId = data['groupId'] ?? '';

        // Usar nombre del grupo desde el caché o asignar valor por defecto
        String groupName = await _getGroupName(groupId);

        if (_disposed) return;

        _seguimientosGrupales.add({
          'id': doc.id,
          'groupId': groupId,
          'groupName': groupName,
          'semana': data['semana'] ?? 'Semana sin fecha',
          'timestamp': data['timestamp'],
          'createdBy': data['createdBy'],
          'data': data,
        });
      }
    } catch (e) {
      print('Error al cargar seguimientos grupales: $e');
    }

    // 2. Cargar seguimientos individuales
    if ((_selectedReportType == 'todos' ||
            _selectedReportType == 'individuales') &&
        !_disposed) {
      try {
        if (_userRole != 'administrador') {
          // Para asesores, necesitamos hacer una consulta más compleja
          // Primero obtenemos los alumnos de sus grupos
          List<String> alumnosIds = [];

          for (String groupId in _userGroups) {
            if (_disposed) return;

            QuerySnapshot alumnosQuery =
                await _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'alumno')
                    .where('groups', arrayContains: groupId)
                    .get();

            if (_disposed) return;

            for (var alumnoDoc in alumnosQuery.docs) {
              alumnosIds.add(alumnoDoc.id);
            }
          }

          // Luego filtramos los seguimientos por estos alumnos
          if (alumnosIds.isNotEmpty && !_disposed) {
            // Dividir en lotes de 10 por limitación de Firestore
            for (int i = 0; i < alumnosIds.length; i += 10) {
              if (_disposed) return;

              int end =
                  (i + 10 < alumnosIds.length) ? i + 10 : alumnosIds.length;
              List<String> batch = alumnosIds.sublist(i, end);

              QuerySnapshot batchQuery =
                  await _firestore
                      .collection('seguimientos')
                      .where('tipo', isEqualTo: 'individual')
                      .where('alumnoId', whereIn: batch)
                      .where(
                        'timestamp',
                        isGreaterThanOrEqualTo: startTimestamp,
                      )
                      .where('timestamp', isLessThan: endTimestamp)
                      .get();

              if (_disposed) return;

              await _processSeguimientosIndividuales(batchQuery.docs);
            }
          }
        } else {
          // Para administradores, obtener todos según filtros
          Query seguimientosIndQuery = _firestore
              .collection('seguimientos')
              .where('tipo', isEqualTo: 'individual')
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .where('timestamp', isLessThan: endTimestamp);

          QuerySnapshot seguimientosIndQueryResult =
              await seguimientosIndQuery.get();

          if (_disposed) return;

          await _processSeguimientosIndividuales(
            seguimientosIndQueryResult.docs,
          );
        }
      } catch (e) {
        print('Error al cargar seguimientos individuales: $e');
      }
    }

    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> exportAllSeguimientosDiscipulo(
    String alumnoId,
    String format, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_disposed) return;

    setExporting(true);

    try {
      List<Map<String, dynamic>> seguimientos =
          _seguimientosIndividuales.where((seguimiento) {
            return seguimiento['alumnoId'] == alumnoId;
          }).toList();

      bool success = await _exportService.exportSeguimientos(
        seguimientos,
        'Seguimientos_Discipulo_$alumnoId',
        format,
        tipo: 'individual',
      );

      if (_disposed) return;

      if (success) {
        onSuccess();
      } else {
        onError('Error al exportar los seguimientos del discípulo');
      }
    } catch (e) {
      if (!_disposed) {
        onError(e.toString());
      }
    } finally {
      if (!_disposed) {
        setExporting(false);
      }
    }
  }

  Future<void> exportSelectedSeguimientos(
    List<Map<String, dynamic>> seguimientos,
    String tipo,
    String format, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_disposed) return;

    _isExporting = true;
    notifyListeners();

    try {
      bool success = await _exportService.exportSeguimientos(
        seguimientos,
        'Seguimientos_${tipo}_Seleccionados',
        format,
        tipo: tipo,
      );

      if (_disposed) return;

      if (success) {
        onSuccess();
      } else {
        onError('Error al exportar los seguimientos seleccionados');
      }
    } catch (e) {
      if (!_disposed) {
        onError(e.toString());
      }
    } finally {
      if (!_disposed) {
        _isExporting = false;
        notifyListeners();
      }
    }
  }

  Future<void> exportAllSeguimientosGrupo(
    String groupId,
    String format, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_disposed) return;

    setExporting(true);

    try {
      List<Map<String, dynamic>> seguimientos =
          _seguimientosGrupales.where((seguimiento) {
            return seguimiento['groupId'] == groupId;
          }).toList();

      bool success = await _exportService.exportSeguimientos(
        seguimientos,
        'Seguimientos_Grupo_$groupId',
        format,
        tipo: 'grupal',
      );

      if (_disposed) return;

      if (success) {
        onSuccess();
      } else {
        onError('Error al exportar los seguimientos del grupo');
      }
    } catch (e) {
      if (!_disposed) {
        onError(e.toString());
      }
    } finally {
      if (!_disposed) {
        setExporting(false);
      }
    }
  }

  Future<String> _getGroupName(String groupId) async {
    // Si ya está en caché, devolver el valor
    if (_groupNamesCache.containsKey(groupId)) {
      return _groupNamesCache[groupId]!;
    }

    // Si no está en caché, intentar obtenerlo
    try {
      // Verificar si el controlador ha sido descartado
      if (_disposed) return 'Grupo $groupId';

      DocumentSnapshot groupDoc =
          await _firestore.collection('groups').doc(groupId).get();

      // Verificar nuevamente si el controlador ha sido descartado
      if (_disposed) return 'Grupo $groupId';

      if (groupDoc.exists) {
        String name = groupDoc['name'] ?? 'Grupo $groupId';
        // Guardar en caché para futuras referencias
        _groupNamesCache[groupId] = name;
        return name;
      } else {
        return 'Grupo $groupId';
      }
    } catch (e) {
      print('Error al obtener nombre del grupo $groupId: $e');
      return 'Grupo $groupId';
    }
  }

  Future<void> _processSeguimientosIndividuales(
    List<QueryDocumentSnapshot> docs,
  ) async {
    for (var doc in docs) {
      if (_disposed) return;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Conseguir información del alumno
      String alumnoName = 'Alumno desconocido';
      String alumnoId = data['alumnoId'] ?? '';
      String groupId = '';
      String groupName = '';

      try {
        DocumentSnapshot alumnoDoc =
            await _firestore.collection('users').doc(alumnoId).get();

        if (_disposed) return;

        if (alumnoDoc.exists) {
          Map<String, dynamic> alumnoData =
              alumnoDoc.data() as Map<String, dynamic>;
          alumnoName = alumnoData['name'] ?? 'Alumno $alumnoId';

          // Obtener el primer grupo del alumno
          if (alumnoData['groups'] != null && alumnoData['groups'].isNotEmpty) {
            List<dynamic> alumnoGroups = alumnoData['groups'];
            if (alumnoGroups.isNotEmpty) {
              groupId = alumnoGroups[0];

              // Obtener nombre del grupo usando la función con caché
              groupName = await _getGroupName(groupId);

              if (_disposed) return;
            }
          }
        }
      } catch (e) {
        print('Error al procesar alumno $alumnoId: $e');
        alumnoName = 'Alumno $alumnoId';
      }

      if (_disposed) return;

      _seguimientosIndividuales.add({
        'id': doc.id,
        'alumnoId': alumnoId,
        'alumnoName': alumnoName,
        'groupId': groupId,
        'groupName': groupName,
        'semana': data['semana'] ?? 'Semana sin fecha',
        'timestamp': data['timestamp'],
        'updatedBy': data['updatedBy'],
        'data': data,
      });
    }
  }

  Future<void> exportReportes(
    String format, {
    required String tipo,
    required int tabIndex,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_disposed) return;

    setExporting(true);

    try {
      bool success = false;

      if (tipo == 'grupal') {
        // Exportar seguimientos grupales
        success = await _exportService.exportSeguimientos(
          _seguimientosGrupales,
          'Seguimientos_Grupales',
          format,
          tipo: 'grupal',
        );
      } else {
        // Exportar seguimientos individuales
        success = await _exportService.exportSeguimientos(
          _seguimientosIndividuales,
          'Seguimientos_Individuales',
          format,
          tipo: 'individual',
        );
      }

      if (_disposed) return;

      if (success) {
        onSuccess();
      } else {
        onError('Error al exportar el reporte');
      }
    } catch (e) {
      if (!_disposed) {
        onError(e.toString());
      }
    } finally {
      if (!_disposed) {
        setExporting(false);
      }
    }
  }

  Future<void> exportSingleSeguimiento(
    Map<String, dynamic> seguimiento,
    String tipo,
    String format, {
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    if (_disposed) return;

    setExporting(true);

    try {
      String fileName =
          tipo == 'individual'
              ? 'Seguimiento_${seguimiento['alumnoName']}_${seguimiento['semana']}'
              : 'Seguimiento_${seguimiento['groupName']}_${seguimiento['semana']}';

      // Eliminar caracteres problemáticos del nombre de archivo
      fileName = fileName.replaceAll(RegExp(r'[\/\\\:\*\?\"\<\>\|]'), '_');

      bool success = await _exportService.exportSeguimientos(
        [seguimiento],
        fileName,
        format,
        tipo: tipo,
      );

      if (_disposed) return;

      if (success) {
        onSuccess();
      } else {
        onError('Error al exportar el reporte');
      }
    } catch (e) {
      if (!_disposed) {
        onError(e.toString());
      }
    } finally {
      if (!_disposed) {
        setExporting(false);
      }
    }
  }

  void applyFilters({
    required String selectedReportType,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> selectedGroups,
  }) {
    if (_disposed) return;

    // Establecer estado de carga
    _isLoadingFilters = true;
    notifyListeners();

    _selectedReportType = selectedReportType;
    _startDate = startDate;
    _endDate = endDate;
    _selectedGroups = selectedGroups;

    // Cargar los datos y restaurar estado
    loadSeguimientos()
        .then((_) {
          if (!_disposed) {
            _isLoadingFilters = false;
            notifyListeners();
          }
        })
        .catchError((error) {
          if (!_disposed) {
            _isLoadingFilters = false;
            notifyListeners();
          }
        });
  }

  // Métodos de ayuda para modificar el estado
  void setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void setExporting(bool exporting) {
    if (_disposed) return;
    _isExporting = exporting;
    notifyListeners();
  }

  void setError(bool hasError, String message) {
    if (_disposed) return;
    _hasError = hasError;
    _errorMessage = message;
    notifyListeners();
  }
}
