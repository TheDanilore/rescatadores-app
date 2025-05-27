import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:rescatadores_app/config/theme.dart';
import 'package:intl/intl.dart';
import 'package:rescatadores_app/presentation/pages/login_screen.dart';

class AsesorProfileScreen extends StatefulWidget {
  const AsesorProfileScreen({super.key});

  @override
  _AsesorProfileScreenState createState() => _AsesorProfileScreenState();
}

class _AsesorProfileScreenState extends State<AsesorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _roleController = TextEditingController();

  String? _originalEmail; // Para detectar cambios en el correo
  List<String> _grupos = [];
  Timestamp? _createdAt;
  Timestamp? _lastLogin;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _emailChanged = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosAsesor();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Editar perfil',
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar y nombre
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFDCEDFC),
                    child: Text(
                      _nombreController.text.isNotEmpty
                          ? _nombreController.text[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nombreController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7F8C8D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _roleController.text.toLowerCase() == 'asesor'
                        ? 'ACOMPAÑANTE'
                        : _roleController.text.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF57C00),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido del perfil
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child:
                    MediaQuery.of(context).size.width > 800
                        ? _buildWideProfileContent()
                        : _buildNarrowProfileContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _isEditing
              ? FloatingActionButton(
                onPressed: _guardarCambios,
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.save),
              )
              : null,
    );
  }

  Widget _buildWideProfileContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Columna izquierda: Información personal
        SizedBox(
          width: 400,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildProfileField(
                    label: 'Nombres',
                    value: _firstNameController.text,
                    icon: Icons.person_outline,
                    isEditing: _isEditing,
                    controller: _firstNameController,
                  ),
                  _buildProfileField(
                    label: 'Apellidos',
                    value: _lastNameController.text,
                    icon: Icons.person_outline,
                    isEditing: _isEditing,
                    controller: _lastNameController,
                  ),
                  _buildProfileField(
                    label: 'Edad',
                    value: _ageController.text,
                    icon: Icons.cake_outlined,
                    isEditing: _isEditing,
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                  ),
                  _buildProfileField(
                    label: 'Teléfono',
                    value: _phoneController.text,
                    icon: Icons.phone_outlined,
                    isEditing: _isEditing,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildProfileField(
                    label: 'Correo Electrónico',
                    value: _emailController.text,
                    icon: Icons.email_outlined,
                    isEditing: _isEditing, // Modificado para permitir edición
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail, // Agregado validador
                  ),
                  // Nota sobre cambio de correo (visible solo en modo edición)
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Nota: Cambiar el correo electrónico modificará la forma en que inicia sesión.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Columna derecha: Información de cuenta
        SizedBox(
          width: 400,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información de Cuenta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.work_outline,
                    title: 'Rol',
                    value:
                        _roleController.text.toLowerCase() == 'asesor'
                            ? 'Acompañante'
                            : _roleController.text,
                  ),
                  _buildGroupsRow(),
                  _buildInfoRow(
                    icon: Icons.calendar_today_outlined,
                    title: 'Fecha de creación',
                    value: _formatTimestamp(_createdAt),
                  ),
                  _buildInfoRow(
                    icon: Icons.login_outlined,
                    title: 'Último inicio de sesión',
                    value: _formatTimestamp(_lastLogin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información Personal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildProfileField(
                  label: 'Nombres',
                  value: _firstNameController.text,
                  icon: Icons.person_outline,
                  isEditing: _isEditing,
                  controller: _firstNameController,
                ),
                _buildProfileField(
                  label: 'Apellidos',
                  value: _lastNameController.text,
                  icon: Icons.person_outline,
                  isEditing: _isEditing,
                  controller: _lastNameController,
                ),
                _buildProfileField(
                  label: 'Edad',
                  value: _ageController.text,
                  icon: Icons.cake_outlined,
                  isEditing: _isEditing,
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                ),
                _buildProfileField(
                  label: 'Teléfono',
                  value: _phoneController.text,
                  icon: Icons.phone_outlined,
                  isEditing: _isEditing,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                _buildProfileField(
                  label: 'Correo Electrónico',
                  value: _emailController.text,
                  icon: Icons.email_outlined,
                  isEditing: _isEditing, // Modificado para permitir edición
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail, // Agregado validador
                ),
                // Nota sobre cambio de correo (visible solo en modo edición)
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Nota: Cambiar el correo electrónico modificará la forma en que inicia sesión.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información de Cuenta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                _buildInfoRow(
                  icon: Icons.work_outline,
                  title: 'Rol',
                  value:
                      _roleController.text.toLowerCase() == 'asesor'
                          ? 'Acompañante'
                          : _roleController.text,
                ),
                _buildGroupsRow(),
                _buildInfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Fecha de creación',
                  value: _formatTimestamp(_createdAt),
                ),
                _buildInfoRow(
                  icon: Icons.login_outlined,
                  title: 'Último inicio de sesión',
                  value: _formatTimestamp(_lastLogin),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Validador de correo electrónico
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

  Widget _buildProfileField({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditing,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 4),
          isEditing
              ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 12,
                  ),
                ),
                keyboardType: keyboardType,
                validator: validator,
              )
              : Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(value, style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
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
      ),
    );
  }

  Widget _buildGroupsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Grupos asignados',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _grupos
                    .map(
                      (grupo) => Chip(
                        label: Text('Grupo $grupo'),
                        backgroundColor: const Color(0xFFECF7FE),
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarDatosAsesor() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (!mounted) return;

        if (snapshot.exists) {
          Map<String, dynamic> userData =
              snapshot.data() as Map<String, dynamic>;

          if (mounted) {
            setState(() {
              _nombreController.text = userData['name'] ?? '';
              _firstNameController.text = userData['firstName'] ?? '';
              _lastNameController.text = userData['lastName'] ?? '';
              _emailController.text =
                  userData['email'] ?? currentUser.email ?? '';
              _originalEmail =
                  userData['email'] ??
                  currentUser.email; // Guardar el correo original
              _phoneController.text = userData['phone'] ?? '';
              _ageController.text = (userData['age'] ?? '').toString();
              _roleController.text = userData['role'] ?? '';

              if (userData['groups'] != null && userData['groups'] is List) {
                _grupos = List<String>.from(userData['groups']);
              }

              _createdAt = userData['createdAt'];
              _lastLogin = userData['lastLogin'];

              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontraron datos del perfil'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print('Error al cargar datos: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar perfil: $e')));
      }
    }
  }

  // Método para actualizar el correo electrónico
  Future<void> _updateUserEmail(String userId, String newEmail) async {
    try {
      // Verificar que el usuario actual sea administrador
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No se pudo obtener el usuario actual');
      }

      // Obtener el token de autenticación
      final idToken = await currentUser.getIdToken();

      // Llamar a la Cloud Function para actualizar el correo
      final response = await http.post(
        Uri.parse('https://updateuseremailrest-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'userId': userId, 'newEmail': newEmail}),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Error desconocido al actualizar correo',
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar correo electrónico: $e');
    }
  }

void _guardarCambios() async {
  if (!_formKey.currentState!.validate()) return;

  // Verificar si el correo ha cambiado
  final newEmail = _emailController.text.trim();
  _emailChanged = _originalEmail != newEmail;

  // 1. Si el correo NO cambió, actualizar normalmente todo
  if (!_emailChanged) {
    await _actualizarPerfilSinCambioCorreo();
    return;
  }

  // 2. Para cambio de correo, mostrar confirmación
  bool confirmar = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmar cambio de correo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Al cambiar su correo electrónico:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Su sesión se cerrará automáticamente'),
            const Text('• Deberá iniciar sesión nuevamente'),
            const Text(
              '• Use su nuevo correo para el próximo inicio de sesión',
            ),
            const SizedBox(height: 16),
            Text(
              '¿Está seguro que desea cambiar su correo de "$_originalEmail" a "$newEmail"?',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Confirmar cambio'),
          ),
        ],
      );
    },
  ) ?? false;

  if (!confirmar) {
    _emailController.text = _originalEmail!;
    return;
  }

  // 3. Actualizar solo datos básicos primero en Firestore
  setState(() => _isLoading = true);
  
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    setState(() => _isLoading = false);
    return;
  }

  try {
    // Actualizar perfil básico en Firestore ANTES de cambiar el correo
    // para evitar problemas de token invalidado
    final updateData = {
      'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'email': newEmail, // Incluir el nuevo correo en Firestore
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .update(updateData);

    await currentUser.updateDisplayName(_nombreController.text);

    // 4. Actualizar el correo (esto invalidará el token)
    await _updateUserEmail(currentUser.uid, newEmail);

    // 5. Mostrar mensaje y redirigir a login INMEDIATAMENTE
    setState(() => _isLoading = false);
    
    if (mounted) {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {  // Usa un contexto específico para el diálogo
      return AlertDialog(
        title: const Text('Correo actualizado'),
        content: const Text(
          'Su correo electrónico ha sido actualizado exitosamente. Por motivos de seguridad, necesita iniciar sesión nuevamente usando su nuevo correo.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();  // Cierra el diálogo primero
              
              // Usa try-catch para el cierre de sesión
              try {
                FirebaseAuth.instance.signOut().then((_) {
                  if (mounted) {  // Verifica de nuevo si está montado
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }).catchError((error) {
                  print('Error al cerrar sesión: $error');
                  // Si falla el cierre de sesión normal, intenta navegar directamente
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                });
              } catch (e) {
                print('Error general al cerrar sesión: $e');
                // Si falla todo lo anterior, intenta esta forma
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/login', 
                    (route) => false
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );
}
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al actualizar: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Método auxiliar para actualización sin cambio de correo
Future<void> _actualizarPerfilSinCambioCorreo() async {
  setState(() => _isLoading = true);

  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      await currentUser.updateDisplayName(_nombreController.text);

      final updateData = {
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text.isEmpty ? null : _phoneController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    setState(() => _isLoading = false);
  }
}
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No disponible';
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  void _cerrarSesion() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }
}
