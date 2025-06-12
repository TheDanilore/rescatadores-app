import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rescatadores_app/presentation/widgets/admin_form_widgets.dart';
import 'package:http/http.dart' as http;

class AdminUserCreationScreen extends StatefulWidget {
  const AdminUserCreationScreen({super.key});

  @override
  State<AdminUserCreationScreen> createState() =>
      _AdminUserCreationScreenState();
}

class _AdminUserCreationScreenState extends State<AdminUserCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> _availableGroups = [];
  List<String> _selectedGroups = [];
  String _selectedRole = 'alumno';
  String _selectedStatus = 'activo';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  // Traducciones de roles para la UI
  final Map<String, String> _roleDisplay = {
    'alumno': 'Persona',
    'asesor': 'Rescatador',
    'administrador': 'Coordinador',
  };

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance
              .collection('users_rescatadores_app')
              .where('role', isEqualTo: 'administrador')
              .get();

      // Recoger todos los grupos únicos de los usuarios administradores
      final Set<String> uniqueGroups = {};
      for (var doc in usersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> userGroups = data['groups'] ?? [];
        uniqueGroups.addAll(userGroups.map((group) => group.toString()));
      }

      setState(() {
        _availableGroups =
            uniqueGroups.map((groupId) {
              return {
                'id': groupId,
                'name': 'Grupo $groupId',
                'description': 'Grupo número $groupId',
              };
            }).toList();
      });
    } catch (e) {
      print('Error al cargar grupos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar grupos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createUserRest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGroups.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor seleccione al menos un grupo';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Preparar datos para enviar
      final data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'role': _selectedRole,
        'groups': _selectedGroups,
        'status': _selectedStatus,
      };

      print("Preparando llamada a REST API con datos: $data");

      // Obtener token de autenticación
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      // Hacer la llamada REST a la función
      final response = await http.post(
        Uri.parse('https://createuserrestrescatadores-gsgjkmd7rq-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(data),
      );

      print("Respuesta recibida [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Limpiar el formulario
          _formKey.currentState!.reset();
          _firstNameController.clear();
          _lastNameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _ageController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _selectedRole = 'alumno';
            _selectedStatus = 'activo';
            _selectedGroups = [];
          });
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      print("Error detallado al crear usuario: $e");

      String errorMsg = 'Error al crear usuario';
      if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }

      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 992;
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 992;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = _isDesktop(context);
    final bool isTablet = _isTablet(context);
    final bool isSmallScreen = !isDesktop && !isTablet;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear nuevo usuario',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete los campos para crear un nuevo usuario en el sistema',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mensaje de error
                  if (_errorMessage != null)
                    ErrorMessageBox(message: _errorMessage!),
                  if (_errorMessage != null) const SizedBox(height: 24),

                  // Sección Datos Personales
                  FormSectionHeader(title: 'Datos Personales'),

                  // Nombre y Apellido (horizontal en pantallas grandes, vertical en pequeñas)
                  if (isSmallScreen)
                    Column(
                      children: [
                        FormInputField(
                          controller: _firstNameController,
                          label: 'Nombres',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingrese el nombre';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormInputField(
                          controller: _lastNameController,
                          label: 'Apellidos',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor ingrese el apellido';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FormInputField(
                            controller: _firstNameController,
                            label: 'Nombres',
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
                          child: FormInputField(
                            controller: _lastNameController,
                            label: 'Apellidos',
                            icon: Icons.person_outline,
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

                  // Correo, teléfono y edad
                  FormInputField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingrese el correo electrónico';
                      }
                      // Regex que permite caracteres internacionales
                      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  if (isSmallScreen)
                    Column(
                      children: [
                        FormInputField(
                          controller: _phoneController,
                          label: 'Teléfono (Opcional)',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            // El teléfono es opcional, así que solo validamos si se ingresa algo
                            if (value != null && value.trim().isNotEmpty) {
                              // Si se ingresa un valor, podemos agregar validaciones adicionales si es necesario
                              // Por ejemplo, validar formato de teléfono
                              final phoneRegex = RegExp(r'^[0-9]{7,15}$');
                              if (!phoneRegex.hasMatch(value.trim())) {
                                return 'Ingrese un número de teléfono válido';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        FormInputField(
                          controller: _ageController,
                          label: 'Edad (Opcional)',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            // La edad es opcional, así que solo validamos si se ingresa algo
                            if (value != null && value.trim().isNotEmpty) {
                              final age = int.parse(value);
                              if (age < 0 || age > 120) {
                                return 'Ingrese una Edad válida';
                              }
                            }

                            return null;
                          },
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FormInputField(
                            controller: _phoneController,
                            label: 'Teléfono (Opcional)',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              // El teléfono es opcional, así que solo validamos si se ingresa algo
                              if (value != null && value.trim().isNotEmpty) {
                                // Si se ingresa un valor, podemos agregar validaciones adicionales si es necesario
                                // Por ejemplo, validar formato de teléfono
                                final phoneRegex = RegExp(r'^[0-9]{7,15}$');
                                if (!phoneRegex.hasMatch(value.trim())) {
                                  return 'Ingrese un número de teléfono válido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormInputField(
                            controller: _ageController,
                            label: 'Edad (Opcional)',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              // La edad es opcional, así que solo validamos si se ingresa algo
                              if (value != null && value.trim().isNotEmpty) {
                                final age = int.parse(value);
                                if (age < 0 || age > 120) {
                                  return 'Ingrese una Edad válida';
                                }
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Sección Acceso y Permisos
                  FormSectionHeader(title: 'Acceso y Permisos'),

                  // Rol y Estado
                  if (isSmallScreen)
                    Column(
                      children: [
                        FormDropdownField<String>(
                          value: _selectedRole,
                          label: 'Rol',
                          icon: Icons.badge,
                          items: [
                            DropdownMenuItem(
                              value: 'alumno',
                              child: Text(_roleDisplay['alumno']!),
                            ),
                            DropdownMenuItem(
                              value: 'asesor',
                              child: Text(_roleDisplay['asesor']!),
                            ),
                            DropdownMenuItem(
                              value: 'administrador',
                              child: Text(_roleDisplay['administrador']!),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                              // Si el rol cambia a alumno y hay múltiples grupos seleccionados,
                              // mantener solo el primero
                              if (_selectedRole == 'alumno' &&
                                  _selectedGroups.length > 1) {
                                _selectedGroups = [_selectedGroups.first];
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                        FormDropdownField<String>(
                          value: _selectedStatus,
                          label: 'Estado',
                          icon: Icons.toggle_on,
                          items: const [
                            DropdownMenuItem(
                              value: 'activo',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'inactivo',
                              child: Text('Inactivo'),
                            ),
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
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: FormDropdownField<String>(
                            value: _selectedRole,
                            label: 'Rol',
                            icon: Icons.badge,
                            items: [
                              DropdownMenuItem(
                                value: 'alumno',
                                child: Text(_roleDisplay['alumno']!),
                              ),
                              DropdownMenuItem(
                                value: 'asesor',
                                child: Text(_roleDisplay['asesor']!),
                              ),
                              DropdownMenuItem(
                                value: 'administrador',
                                child: Text(_roleDisplay['administrador']!),
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
                          child: FormDropdownField<String>(
                            value: _selectedStatus,
                            label: 'Estado',
                            icon: Icons.toggle_on,
                            items: const [
                              DropdownMenuItem(
                                value: 'activo',
                                child: Text('Activo'),
                              ),
                              DropdownMenuItem(
                                value: 'inactivo',
                                child: Text('Inactivo'),
                              ),
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
                  const SizedBox(height: 16),

                  // Asignación de grupos
                  FormSectionHeader(title: 'Asignación de Grupos'),

                  if (_selectedRole == 'alumno')
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Nota: Los discípulos solo pueden pertenecer a un grupo',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  if (_availableGroups.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No hay grupos disponibles para asignar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _availableGroups.length,
                            itemBuilder: (context, index) {
                              final group = _availableGroups[index];
                              final isSelected = _selectedGroups.contains(
                                group['id'],
                              );

                              return CheckboxListTile(
                                title: Text(
                                  group['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(group['description']),
                                value: isSelected,
                                onChanged: (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      // Si el rol es alumno y ya hay un grupo seleccionado, reemplazarlo
                                      if (_selectedRole == 'alumno' &&
                                          _selectedGroups.isNotEmpty) {
                                        _selectedGroups = [group['id']];
                                      } else {
                                        _selectedGroups.add(group['id']);
                                      }
                                    } else {
                                      _selectedGroups.remove(group['id']);
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                                checkColor: Colors.white,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                // Deshabilitar la opción para seleccionar más grupos si ya hay uno seleccionado
                                // y el rol es alumno
                                enabled:
                                    !(_selectedRole == 'alumno' &&
                                        _selectedGroups.isNotEmpty &&
                                        !_selectedGroups.contains(group['id'])),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Sección de contraseña
                  FormSectionHeader(title: 'Contraseña'),

                  FormPasswordField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    isObscure: _obscurePassword,
                    toggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FormPasswordField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Contraseña',
                    isObscure: _obscureConfirmPassword,
                    toggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirme la contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botón de creación
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
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
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createUserRest,
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
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'CREAR USUARIO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
