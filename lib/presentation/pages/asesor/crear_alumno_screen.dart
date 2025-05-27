import 'dart:convert';
import 'package:rescatadores_app/config/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  String? _selectedGroup;
  String _selectedStatus = 'activo';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  List<String> _asesorGroups = [];

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
    super.dispose();
  }

  Future<void> _loadAsesorGroups() async {
    if (!mounted) return;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot asesorDoc =
            await FirebaseFirestore.instance
                .collection('users')
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
    // Validaciones iniciales
    if (!_formKey.currentState!.validate()) {
      int errorStep = _validateStepFields();
      if (errorStep != _currentStep) {
        setState(() {
          _currentStep = errorStep;
        });
      }
      return;
    }

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
      };

      print("Preparando llamada a REST API con datos: $data");

      // Obtener token de autenticación
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.post(
        Uri.parse('https://createalumnorest-gsgjkmd7rq-uc.a.run.app'),
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
              content: Text('Discípulo creado exitosamente'),
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
      print("Error detallado al crear Discípulo: $e");

      String errorMsg = 'Error al crear Discípulo';
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

  int _validateStepFields() {
    // Validar primer paso (información personal)
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      return 0;
    }

    // Validar segundo paso (información académica)
    if (_ageController.text.trim().isEmpty ||
        int.tryParse(_ageController.text) == null ||
        _selectedGroup == null) {
      return 1;
    }

    // El tercer paso (contraseñas) se valida al final
    return _currentStep;
  }

  void _resetForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _ageController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _selectedGroup = null;
      _selectedStatus = 'activo';
      _currentStep = 0;
    });
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

    return Scaffold(
      body: SafeArea(child: _buildResponsiveLayout(isDesktop, isTablet)),
    );
  }

  Widget _buildResponsiveLayout(bool isDesktop, bool isTablet) {
    if (isDesktop) {
      // Layout para desktop
      return Row(
        children: [
          // Sidebar con pasos
          Container(
            width: 250,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pasos a completar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStepIndicator(
                  0,
                  'Información Personal',
                  Icons.person,
                  _currentStep == 0 ? AppTheme.primaryColor : Colors.grey,
                  _currentStep >= 0,
                ),
                _buildStepConnector(),
                _buildStepIndicator(
                  1,
                  'Información Académica',
                  Icons.school,
                  _currentStep == 1 ? AppTheme.primaryColor : Colors.grey,
                  _currentStep >= 1,
                ),
                _buildStepConnector(),
                _buildStepIndicator(
                  2,
                  'Seguridad',
                  Icons.lock,
                  _currentStep == 2 ? AppTheme.primaryColor : Colors.grey,
                  _currentStep >= 2,
                ),
                const Spacer(),
                Icon(Icons.person_add, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Divider vertical
          VerticalDivider(width: 1, color: Colors.grey.shade300),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title and description
                    Text(
                      _getStepTitle(_currentStep),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStepDescription(_currentStep),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Form content
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: _buildCurrentStepContent(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Navigation buttons
                    Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _buildNavigationButtons(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (isTablet) {
      // Layout para tablet
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Step indicator row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStepIndicatorTablet(
                      0,
                      'Información Personal',
                      Icons.person,
                      _currentStep >= 0,
                      _currentStep > 0,
                    ),
                  ),
                  Expanded(
                    child: _buildStepIndicatorTablet(
                      1,
                      'Información Académica',
                      Icons.school,
                      _currentStep >= 1,
                      _currentStep > 1,
                    ),
                  ),
                  Expanded(
                    child: _buildStepIndicatorTablet(
                      2,
                      'Seguridad',
                      Icons.lock,
                      _currentStep >= 2,
                      _currentStep > 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Step content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStepTitle(_currentStep),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getStepDescription(_currentStep),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCurrentStepContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: _buildNavigationButtons(),
            ),
          ],
        ),
      );
    } else {
      // Layout para mobile (stepper vertical)
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mobile Step Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepDot(0, _currentStep >= 0),
                    _buildStepLine(_currentStep > 0),
                    _buildStepDot(1, _currentStep >= 1),
                    _buildStepLine(_currentStep > 1),
                    _buildStepDot(2, _currentStep >= 2),
                  ],
                ),
                const SizedBox(height: 24),

                // Step Title and Description
                Text(
                  _getStepTitle(_currentStep),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepDescription(_currentStep),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Current Step Content
                _buildCurrentStepContent(),

                const SizedBox(height: 24),

                // Navigation Buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStepIndicator(
    int step,
    String title,
    IconData icon,
    Color color,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        if (isActive) {
          setState(() {
            _currentStep = step;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isActive ? color : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight:
                      _currentStep == step
                          ? FontWeight.bold
                          : FontWeight.normal,
                  color: isActive ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
            if (_currentStep > step)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector() {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(width: 2, height: 30, color: Colors.grey.shade300),
    );
  }

  Widget _buildStepIndicatorTablet(
    int step,
    String title,
    IconData icon,
    bool isActive,
    bool isCompleted,
  ) {
    return InkWell(
      onTap: () {
        if (isActive) {
          setState(() {
            _currentStep = step;
          });
        }
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isActive
                      ? (isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.1))
                      : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isActive
                        ? (isCompleted ? Colors.green : AppTheme.primaryColor)
                        : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: Center(
              child:
                  isCompleted
                      ? const Icon(Icons.check, color: Colors.green)
                      : Icon(
                        icon,
                        color: isActive ? AppTheme.primaryColor : Colors.grey,
                      ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  _currentStep == step ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          setState(() {
            _currentStep = step;
          });
        }
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color:
              _currentStep == step
                  ? AppTheme.primaryColor
                  : (isActive ? Colors.white : Colors.grey.shade300),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child:
            _currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : (_currentStep == step ? const SizedBox() : null),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Información Personal';
      case 1:
        return 'Información Académica';
      case 2:
        return 'Configuración de Seguridad';
      default:
        return '';
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Ingresa los datos personales del Discípulo';
      case 1:
        return 'Configura la información académica y asignación de grupo';
      case 2:
        return 'Crea credenciales seguras para el Discípulo';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildAcademicInfoStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == 2;
    final isFirstStep = _currentStep == 0;

    return Row(
      children: [
        if (!isFirstStep)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentStep -= 1;
                });
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ATRÁS'),
            ),
          ),
        if (!isFirstStep) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                _isLoading
                    ? null
                    : isLastStep
                    ? _crearAlumnoConREST
                    : () {
                      // Validar el paso actual antes de continuar
                      bool isValid = true;

                      // Validaciones específicas por paso
                      if (_currentStep == 0) {
                        if (_firstNameController.text.trim().isEmpty ||
                            _lastNameController.text.trim().isEmpty ||
                            _emailController.text.trim().isEmpty ||
                            !_emailController.text.contains('@') ||
                            !_emailController.text.contains('.')) {
                          isValid = false;
                        }
                      }

                      if (isValid) {
                        setState(() {
                          _currentStep += 1;
                        });
                      } else {
                        // Mostrar mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor complete todos los campos requeridos',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
                    : Text(
                      isLastStep ? 'REGISTRAR DISCÍPULO' : 'CONTINUAR',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);

    if (isDesktop || isTablet) {
      // Layout 2 columnas para desktop y tablet
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
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
                child: _buildInputField(
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
          _buildInputField(
            controller: _emailController,
            label: 'Correo Electrónico',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un correo';
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
          _buildInputField(
            controller: _phoneController,
            label: 'Teléfono (opcional)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              // El teléfono ahora es opcional
              return null;
            },
          ),
        ],
      );
    } else {
      // Layout 1 columna para móvil
      return Column(
        children: [
          _buildInputField(
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
          _buildInputField(
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
          const SizedBox(height: 16),
          _buildInputField(
            controller: _emailController,
            label: 'Correo Electrónico',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un correo';
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
          _buildInputField(
            controller: _phoneController,
            label: 'Teléfono (opcional)',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              // El teléfono ahora es opcional
              return null;
            },
          ),
        ],
      );
    }
  }

  Widget _buildAcademicInfoStep() {
    final isDesktop = _isDesktop(context);
    final isTablet = _isTablet(context);

    if (isDesktop || isTablet) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInputField(
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
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _selectedStatus,
                  label: 'Estado',
                  icon: Icons.toggle_on,
                  items: const [
                    DropdownMenuItem(value: 'activo', child: Text('Activo')),
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
        ],
      );
    } else {
      return Column(
        children: [
          _buildInputField(
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
        ],
      );
    }
  }

  Widget _buildSecurityStep() {
    return Column(
      children: [
        _buildPasswordField(
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
        _buildPasswordField(
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
        const SizedBox(height: 24),
        _buildRequirementsCard(),
      ],
    );
  }

  Widget _buildRequirementsCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Requisitos de contraseña',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRequirementItem('Al menos 6 caracteres'),
            _buildRequirementItem(
              'Combine letras y números para mayor seguridad',
            ),
            _buildRequirementItem(
              'Use símbolos especiales para aumentar la seguridad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese $label',
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
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese $label',
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.primaryColor,
          ),
          onPressed: toggleObscure,
        ),
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
      obscureText: isObscure,
      validator: validator,
      textInputAction: TextInputAction.next,
    );
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
}
