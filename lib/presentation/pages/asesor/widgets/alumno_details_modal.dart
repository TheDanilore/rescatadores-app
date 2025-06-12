import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AlumnoDetailsModal {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> alumnoData, {
    String? alumnoId,
  }) {
    // First try to use the provided alumnoId parameter
    String id = alumnoId ?? '';

    // Si no se proporcionó un ID, intentar extraerlo de los datos
    if (id.isEmpty) {
      // Buscar ID en campos comunes
      if (alumnoData.containsKey('id')) {
        id = alumnoData['id'];
      } else if (alumnoData.containsKey('uid')) {
        id = alumnoData['uid'];
      } else if (alumnoData.containsKey('_id')) {
        id = alumnoData['_id'];
      } else if (alumnoData.containsKey('documentId')) {
        id = alumnoData['documentId'];
      }

      // Si aún está vacío, ver si hay un DocumentReference
      if (id.isEmpty &&
          alumnoData.containsKey('reference') &&
          alumnoData['reference'] is DocumentReference) {
        id = (alumnoData['reference'] as DocumentReference).id;
      }
    }

    // Si después de todo sigue vacío, mostrar error
    if (id.isEmpty) {
      print(
        'ADVERTENCIA: No se pudo obtener el ID del alumno de los datos: $alumnoData',
      );

      // Mostrar diálogo de error
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Error'),
              content: const Text(
                'No se pudo obtener el ID del alumno. Contacte al administrador.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );

      return Future.value();
    }

    print('Abriendo modal con ID de alumno: $id');

    // Continuar con la apertura del modal
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: _CombinedAlumnoDetailsForm(
              alumnoData: alumnoData,
              alumnoId: id,
            ),
          ),
    );
  }
}

class _CombinedAlumnoDetailsForm extends StatefulWidget {
  final Map<String, dynamic> alumnoData;
  final String alumnoId;

  const _CombinedAlumnoDetailsForm({
    required this.alumnoData,
    required this.alumnoId,
  });

  @override
  _CombinedAlumnoDetailsFormState createState() =>
      _CombinedAlumnoDetailsFormState();
}

class _CombinedAlumnoDetailsFormState
    extends State<_CombinedAlumnoDetailsForm> {
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  late String _selectedStatus;
  String? _errorMessage;
  bool _isLoading = false;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();

    print('Inicializando formulario para alumno con ID: ${widget.alumnoId}');
    print('Datos del alumno: ${widget.alumnoData}');

    // Inicializar controladores
    _firstNameController = TextEditingController(
      text: widget.alumnoData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.alumnoData['lastName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.alumnoData['email'] ?? '',
    );
    _originalEmail = widget.alumnoData['email'];
    _phoneController = TextEditingController(
      text: widget.alumnoData['phone'] ?? '',
    );
    _ageController = TextEditingController(
      text: (widget.alumnoData['age'] ?? 0).toString(),
    );

    _selectedStatus = widget.alumnoData['status'] ?? 'activo';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // Función para actualizar el alumno
  Future<void> _updateAlumno() async {
    if (!_formKey.currentState!.validate()) {
      print('Validación del formulario fallida');
      return;
    }

    if (widget.alumnoId.isEmpty) {
      setState(() {
        _errorMessage =
            'Error: No se pudo obtener el ID del alumno. Contacta al administrador.';
      });
      print('ERROR: ID de alumno vacío, no se puede actualizar');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Iniciando actualización de alumno con ID: ${widget.alumnoId}');
      final newEmail = _emailController.text.trim();
      final bool emailChanged = _originalEmail != newEmail;

      // Si el correo cambió, actualizarlo primero
      if (emailChanged) {
        print(
          'El correo cambió de "$_originalEmail" a "$newEmail", actualizando en Auth...',
        );
        try {
          await _updateAlumnoEmail();
          print('Correo actualizado exitosamente en Auth');
        } catch (e) {
          print('ERROR en actualización de correo: $e');
          throw Exception('Error al actualizar correo: $e');
        }
      }

      // Recopilar todos los campos a actualizar
      final updateData = {
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'status': _selectedStatus,
      };

      // Si el email cambió, incluirlo en la actualización de Firestore
      if (emailChanged) {
        updateData['email'] = newEmail;
      }

      print('Actualizando datos en Firestore: $updateData');

      // Actualizar los datos en Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users_rescatadores_app')
            .doc(widget.alumnoId)
            .update(updateData);
        print('Datos actualizados exitosamente en Firestore');
      } catch (firestoreError) {
        print('ERROR al actualizar Firestore: $firestoreError');
        throw Exception('Error al actualizar datos: $firestoreError');
      }

      // Actualizar los datos locales
      widget.alumnoData['firstName'] = _firstNameController.text.trim();
      widget.alumnoData['lastName'] = _lastNameController.text.trim();
      widget.alumnoData['name'] =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      if (emailChanged) {
        widget.alumnoData['email'] = newEmail;
      }
      widget.alumnoData['phone'] = _phoneController.text.trim();
      widget.alumnoData['age'] = int.tryParse(_ageController.text.trim()) ?? 0;
      widget.alumnoData['status'] = _selectedStatus;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discípulo actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Cambiar a modo visualización
        setState(() {
          _isEditMode = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR general en actualización: $e');
      setState(() {
        _errorMessage = 'Error al actualizar discípulo: $e';
        _isLoading = false;
      });
    }
  }

  // Función para actualizar el email en Authentication
  Future<void> _updateAlumnoEmail() async {
    try {
      // Verificar que el usuario actual tenga permisos
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No se pudo obtener el usuario actual');
      }

      print(
        'Usuario actual: ${currentUser.uid}, rol: ${await _getUserRole(currentUser.uid)}',
      );

      // Obtener el token de autenticación
      final idToken = await currentUser.getIdToken();

      print('Llamando a Cloud Function para actualizar correo...');

      // Llamar a la Cloud Function para actualizar el correo
      final response = await http.post(
        Uri.parse('https://updateuseremailrestrescatadores-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'userId': widget.alumnoId,
          'newEmail': _emailController.text.trim(),
        }),
      );

      print(
        'Respuesta de Cloud Function: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Error desconocido al actualizar correo',
        );
      }
    } catch (e) {
      print('ERROR detallado en _updateAlumnoEmail: $e');
      throw Exception('Error al actualizar correo electrónico: $e');
    }
  }

  // Función auxiliar para obtener el rol del usuario
  Future<String> _getUserRole(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users_rescatadores_app').doc(uid).get();

      if (userDoc.exists) {
        return userDoc.data()?['role'] ?? 'desconocido';
      }
      return 'no encontrado';
    } catch (e) {
      print('Error al obtener rol de usuario: $e');
      return 'error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior con título y botones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Editar Discípulo' : 'Detalles del Discípulo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Row(
                  children: [
                    if (!_isLoading)
                      IconButton(
                        icon: Icon(
                          _isEditMode ? Icons.visibility : Icons.edit,
                          color: AppTheme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Línea divisoria
          const Divider(height: 1),

          // Contenido principal
          Flexible(child: _isEditMode ? _buildEditForm() : _buildDetailsView()),
        ],
      ),
    );
  }

  // Vista de detalles
  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.person,
            label: 'Nombre Completo',
            value: widget.alumnoData['name'] ?? 'No disponible',
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.email,
            label: 'Correo Electrónico',
            value: widget.alumnoData['email'] ?? 'No disponible',
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.phone,
            label: 'Teléfono',
            value: widget.alumnoData['phone'] ?? 'No disponible',
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Edad',
            value: widget.alumnoData['age']?.toString() ?? 'No disponible',
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.group,
            label: 'Grupos',
            value: _getGroupsDisplay(),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(
            icon: Icons.toggle_on,
            label: 'Estado',
            value: _getStatusDisplay(
              widget.alumnoData['status'] ?? 'No disponible',
            ),
          ),

          // Solo para depuración - ID de usuario
          const SizedBox(height: 24),
          Text(
            'ID: ${widget.alumnoId}',
            style: TextStyle(color: Colors.grey[400], fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Función para mostrar los grupos
  String _getGroupsDisplay() {
    if (widget.alumnoData['groups'] == null ||
        (widget.alumnoData['groups'] is List &&
            (widget.alumnoData['groups'] as List).isEmpty)) {
      return 'Sin grupos';
    }

    if (widget.alumnoData['groups'] is List) {
      return (widget.alumnoData['groups'] as List).join(', ');
    } else {
      return widget.alumnoData['groups'].toString();
    }
  }

  // Vista de edición
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje de error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Campo de nombre
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nombre',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'Nombre',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el nombre';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de apellido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apellido',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Apellido',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el apellido';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Correo Electrónico
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correo Electrónico',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Correo Electrónico',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                if (_originalEmail != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Nota: Cambiar el correo electrónico modificará la forma en que el usuario inicia sesión.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Teléfono
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teléfono (Opcional)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Teléfono',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Edad
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edad',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    hintText: 'Edad',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                _buildStatusDropdown(),
              ],
            ),
            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Restaurar valores originales
                      _firstNameController.text =
                          widget.alumnoData['firstName'] ?? '';
                      _lastNameController.text =
                          widget.alumnoData['lastName'] ?? '';
                      _emailController.text = widget.alumnoData['email'] ?? '';
                      _phoneController.text = widget.alumnoData['phone'] ?? '';
                      _ageController.text =
                          (widget.alumnoData['age'] ?? 0).toString();
                      _selectedStatus = widget.alumnoData['status'] ?? 'activo';

                      // Volver a modo visualización
                      setState(() {
                        _isEditMode = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAlumno,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Construir dropdown de estado
  Widget _buildStatusDropdown() {
    // Inicializar con un valor seguro
    final availableStatuses = ['activo', 'inactivo', 'suspendido'];
    final safeValue =
        availableStatuses.contains(_selectedStatus)
            ? _selectedStatus
            : 'activo';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: [
            DropdownMenuItem(
              value: 'activo',
              child: Row(
                children: [
                  const Icon(Icons.toggle_on, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Activo'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'inactivo',
              child: Row(
                children: [
                  Icon(Icons.toggle_off, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('Inactivo'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'suspendido',
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Suspendido'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ),
    );
  }

  // Widget para mostrar información en modo visualización
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Obtener el texto de estado formateado
  String _getStatusDisplay(String status) {
    switch (status.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      default:
        return status;
    }
  }

  // Validación de correo electrónico
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese un correo electrónico';
    }

    // Validación de formato de email
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }

    return null;
  }

  // Validación de teléfono
  String? _validatePhone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^[0-9]{7,15}$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Ingrese un número de teléfono válido';
      }
    }
    return null;
  }

  // Validación de edad
  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese la edad';
    }
    try {
      final age = int.parse(value);
      if (age < 0 || age > 120) {
        return 'Edad no válida';
      }
    } catch (e) {
      return 'Ingrese un número válido';
    }
    return null;
  }
}
