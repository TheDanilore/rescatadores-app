import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:rescatadores_app/config/theme.dart';

class UserEditScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserEditScreen({Key? key, required this.userId, required this.userData})
    : super(key: key);

  @override
  _UserEditScreenState createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isLoading = false;
  String? _errorMessage;
  String? _originalEmail;
  bool _emailChanged = false;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con datos existentes
    _firstNameController = TextEditingController(
      text: widget.userData['firstName'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['lastName'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _originalEmail = widget.userData['email'];
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );
    _ageController = TextEditingController(
      text: (widget.userData['age']).toString(),
    );

    _selectedRole = widget.userData['role'] ?? 'alumno';
    _selectedStatus = widget.userData['status'] ?? 'activo';
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

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final newEmail = _emailController.text.trim();
      _emailChanged = _originalEmail != newEmail;

      // Si el correo cambió, actualizarlo primero
      if (_emailChanged) {
        await _updateUserEmail();
      }

      // Luego actualizar el resto de los datos en Firestore
      await FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .doc(widget.userId)
          .update({
            'name':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'role': _selectedRole,
            'status': _selectedStatus,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al actualizar usuario: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserEmail() async {
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
        Uri.parse('https://updateuseremailrestrescatadores-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'newEmail': _emailController.text.trim(),
        }),
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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Está seguro que desea eliminar este usuario? Esta acción no se puede deshacer y eliminará todos los datos asociados a este usuario.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
                _deleteUser(); // Proceder con la eliminación
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener el token de autenticación
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      // Llamar a la Cloud Function para eliminar el usuario
      final response = await http.post(
        Uri.parse('https://deleteuserrestrescatadores-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'userId': widget.userId}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Cerrar la pantalla de edición
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al eliminar usuario: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de arrastre
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Título y botón de cierre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar Usuario',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenido del formulario - usando Expanded con un SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mensaje de error
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 20),

                    // Campos del formulario
                    if (isSmallScreen)
                      _buildSmallScreenForm()
                    else
                      _buildLargeScreenForm(),

                    const SizedBox(height: 24),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
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
                            onPressed: _isLoading ? null : _updateUser,
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

                    const SizedBox(height: 24),

                    // Botón de eliminación
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _showDeleteConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Eliminar Usuario'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Refactorizamos los layouts para mayor claridad
  Widget _buildSmallScreenForm() {
    return Column(
      children: [
        // Nombre
        _buildTextField(
          controller: _firstNameController,
          label: 'Nombre',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingrese el nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Apellido
        _buildTextField(
          controller: _lastNameController,
          label: 'Apellido',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingrese el apellido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Email - ahora habilitado para edición
        _buildTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          enabled: true, // Habilitado para edición
          validator: _validateEmail,
        ),

        // Nota sobre el cambio de correo
        if (_originalEmail != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'Nota: Cambiar el correo electrónico modificará la forma en que el usuario inicia sesión.',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Teléfono
        _buildTextField(
          controller: _phoneController,
          label: 'Teléfono (Opcional)',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
        const SizedBox(height: 16),

        // Edad
        _buildTextField(
          controller: _ageController,
          label: 'Edad (Opcional)',
          icon: Icons.calendar_today,
          keyboardType: TextInputType.number,
          validator: _validateAge,
        ),
        const SizedBox(height: 16),

        // Rol
        _buildDropdownField(
          value: _selectedRole,
          label: 'Rol',
          icon: Icons.badge,
          items: const [
            DropdownMenuItem(value: 'alumno', child: Text('Persona')),
            DropdownMenuItem(value: 'asesor', child: Text('Rescatador')),
            DropdownMenuItem(
              value: 'administrador',
              child: Text('Coordinador'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        // Estado
        _buildDropdownField(
          value: _selectedStatus,
          label: 'Estado',
          icon: Icons.toggle_on,
          items: const [
            DropdownMenuItem(value: 'activo', child: Text('Activo')),
            DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
            DropdownMenuItem(value: 'suspendido', child: Text('Suspendido')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLargeScreenForm() {
    return Column(
      children: [
        // Primera fila: Nombre y Apellido
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el nombre';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el apellido';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Correo electrónico
        _buildTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          enabled: true, // Habilitado para edición
          validator: _validateEmail,
        ),

        // Nota sobre el cambio de correo
        if (_originalEmail != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'Nota: Cambiar el correo electrónico modificará la forma en que el usuario inicia sesión.',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Segunda fila: Teléfono y Edad
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _phoneController,
                label: 'Teléfono (Opcional)',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _ageController,
                label: 'Edad (Opcional)',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                validator: _validateAge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tercera fila: Rol y Estado
        Row(
          children: [
            Expanded(
              child: _buildDropdownField(
                value: _selectedRole,
                label: 'Rol',
                icon: Icons.badge,
                items: const [
                  DropdownMenuItem(value: 'alumno', child: Text('Persona')),
                  DropdownMenuItem(value: 'asesor', child: Text('Rescatador')),
                  DropdownMenuItem(
                    value: 'administrador',
                    child: Text('Coordinador'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                value: _selectedStatus,
                label: 'Estado',
                icon: Icons.toggle_on,
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  DropdownMenuItem(
                    value: 'suspendido',
                    child: Text('Suspendido'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Funciones de validación extraídas para claridad
  String? _validatePhone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^[0-9]{7,15}$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Ingrese un número de teléfono válido';
      }
    }
    return null;
  }

  String? _validateAge(String? value) {
    // La edad es opcional, así que solo validamos si se ingresa algo
    if (value != null && value.trim().isNotEmpty) {
      final age = int.parse(value);
      if (age < 0 || age > 120) {
        return 'Ingrese una Edad válida';
      }
    }

    return null;
  }

  // Validador de email
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese un correo electrónico';
    }

    // Regex que permite caracteres internacionales
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }

    return null;
  }

  // Widget reutilizable para campos de texto
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      style: TextStyle(color: enabled ? Colors.black : Colors.grey[700]),
    );
  }

  // Widget reutilizable para campos de selección
  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
