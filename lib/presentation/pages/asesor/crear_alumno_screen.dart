import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rescatadores_app/presentation/widgets/admin_form_widgets.dart';

class CrearAlumnoScreen extends StatefulWidget {
  const CrearAlumnoScreen({super.key});

  @override
  _CrearAlumnoScreenState createState() => _CrearAlumnoScreenState();
}

class _CrearAlumnoScreenState extends State<CrearAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _redemptionDateController = TextEditingController();
  final _childDateBirthController = TextEditingController();
  final _reasonAbortionController = TextEditingController();

  String? _selectedGroup;
  String _selectedStatus = 'activo';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  List<String> _asesorGroups = [];

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAsesorGroups();
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
    _redemptionDateController.dispose();
    _childDateBirthController.dispose();
    _reasonAbortionController.dispose();
    super.dispose();
  }

  Future<void> _loadAsesorGroups() async {
    if (!mounted) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot asesorDoc =
            await FirebaseFirestore.instance
                .collection('users_rescatadores_app')
                .doc(currentUser.uid)
                .get();

        if (asesorDoc.exists && asesorDoc.data() != null) {
          var data = asesorDoc.data() as Map<String, dynamic>;
          if (data.containsKey('groups') && data['groups'] is List) {
            if (mounted) {
              setState(() {
                _asesorGroups = List<String>.from(data['groups']);
              });
            }
          }
        }
      }
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

  Future<void> _crearAlumnoConREST() async {
     if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (_selectedGroup == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un grupo'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Activar indicador de carga
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Preparar datos para enviar
      final data = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'groups': [_selectedGroup],
        'status': _selectedStatus,
        'redemptionDate': _redemptionDateController.text.trim(),
        'childDateBirth': _childDateBirthController.text.trim(),
        'reasonAbortion': _reasonAbortionController.text.trim(),
      };

      print("Preparando llamada a REST API con datos: $data");

      // Obtener token de autenticación
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.post(
        Uri.parse(
          'https://createalumnorestrescatadores-gsgjkmd7rq-uc.a.run.app',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(data),
      );

      print("Respuesta recibida [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        jsonDecode(response.body);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Persona creado exitosamente'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Reiniciar formulario
          _resetForm();
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      print("Error detallado al crear Persona: $e");

      String errorMsg = 'Error al crear Persona';
      if (e is Exception) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _resetForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _ageController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _redemptionDateController.clear();
    _childDateBirthController.clear();
    _reasonAbortionController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedStatus = 'activo';
      _currentStep = 0;
    });
  }

  String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Validar formato con RegEx dd/mm/aaaa
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(value)) {
      return 'Formato inválido. Ingresa dd/mm/aaaa, ej. 13/07/2024';
    }

    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(value);
      // Agregar lógica extra para fechas futuras, pasadas, etc.
    } catch (e) {
      return 'Fecha inválida';
    }

    return null;
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 992;
  }

  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 992;
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
      isExpanded: true,
      dropdownColor: Colors.white,
    );
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
                    'Registrar nueva persona',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Complete los campos para registar una nueva persona en el sistema',
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

                  FormSectionHeader(title: 'Datos Adicionales'),
                  if (isSmallScreen)
                    Column(
                      children: [
                        FormInputField(
                          controller: _redemptionDateController,
                          label: 'Fecha de Rescate (dd/mm/aaaa)',
                          icon: Icons.date_range_outlined,
                          keyboardType: TextInputType.text,
                          validator: validateDate,
                        ),
                        const SizedBox(height: 16),
                        FormInputField(
                          controller: _childDateBirthController,
                          label: 'Fecha probable de parto (dd/mm/aaaa)',
                          icon: Icons.date_range_outlined,
                          keyboardType: TextInputType.text,
                          validator: validateDate,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonAbortionController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 4,
                          validator: (value) => null,
                          decoration: InputDecoration(
                            labelText: 'Motivo por el que iba a abortar',
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FormInputField(
                            controller: _redemptionDateController,
                            label: 'Fecha de Rescate (dd/mm/aaaa)',
                            icon: Icons.date_range_outlined,
                            keyboardType: TextInputType.text,
                            validator: validateDate,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormInputField(
                            controller: _childDateBirthController,
                            label: 'Fecha probable de parto (dd/mm/aaaa)',
                            icon: Icons.date_range_outlined,
                            keyboardType: TextInputType.text,
                            validator: validateDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _reasonAbortionController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            minLines: 4,
                            validator: (value) => null,
                            decoration: InputDecoration(
                              labelText: 'Motivo por el que iba a abortar',
                              alignLabelWithHint: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: 12.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Sección de asignación de grupos
                  FormSectionHeader(title: 'Asignación de Grupos'),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Nota: Solo puedes asignar a un grupo propio',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                  if (_asesorGroups.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No tienes grupos asignados',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    _buildDropdownField(
                      value: _selectedGroup,
                      label: 'Grupo',
                      icon: Icons.group,
                      items:
                          _asesorGroups.map((String group) {
                            return DropdownMenuItem<String>(
                              value: group,
                              child: Text('Grupo $group'),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGroup = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor selecciona un grupo';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),

                  FormSectionHeader(title: 'Estado'),

                  // Estado
                  if (isSmallScreen)
                    Column(
                      children: [
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
                          onPressed: _isLoading ? null : _crearAlumnoConREST,
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
                                    'REGISTRAR PERSONA',
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
