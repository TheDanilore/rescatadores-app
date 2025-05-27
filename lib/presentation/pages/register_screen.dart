import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/presentation/pages/alumno/home_screen.dart';
import 'package:rescatadores_app/presentation/widgets/custom_button.dart';
import 'package:rescatadores_app/presentation/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate password confirmation manually
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas no coinciden.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Guardar información adicional en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'email': _emailController.text.trim(),
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'age': int.tryParse(_ageController.text.trim()) ?? 0,
            'role': 'alumno', // Asignar un rol por defecto
            'groups':
                [], // Inicialmente, el usuario no pertenece a ningún grupo
            'status': 'activo', // Estado inicial del usuario
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });

      // Actualizar el perfil del usuario
      await userCredential.user!.updateDisplayName(
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ocurrió un error inesperado. Inténtalo de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'operation-not-allowed':
        return 'El registro con correo y contraseña no está habilitado.';
      default:
        return 'Error de registro. Inténtalo de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;

          if (isLargeScreen) {
            // Diseño de escritorio: dos columnas con AppBar
            return Scaffold(
              body: Row(
                children: [
                  // Columna de imagen
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/logo.png', width: 400),
                            const SizedBox(height: AppTheme.spacingXL),
                            Text(
                              'Regístrate en Rescatadores App',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Columna de formulario
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXL * 2,
                          vertical: AppTheme.spacingXL,
                        ),
                        child: _buildRegistrationForm(context, isLargeScreen),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Diseño móvil: desplazamiento vertical con AppBar
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppTheme.textPrimaryColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  'Crear cuenta',
                  style: TextStyle(color: AppTheme.textPrimaryColor),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: _buildRegistrationForm(context, isLargeScreen),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context, bool isLargeScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Únete a Rescatadores App',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontSize: isLargeScreen ? 32 : 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Crea una cuenta para ingresar al sistema como Rescatadores',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: isLargeScreen ? 20 : 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Formulario
          CustomTextField(
            label: 'Nombre',
            hint: 'Juan',
            controller: _firstNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu nombre';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Apellidos',
            hint: 'Pérez',
            controller: _lastNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tus apellidos';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Teléfono',
            hint: '+123 456 7890',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu número de teléfono';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Correo electrónico',
            hint: 'ejemplo@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu correo electrónico';
              }
              // Regex que permite caracteres internacionales
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

              if (!emailRegex.hasMatch(value)) {
                return 'Por favor ingrese un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Edad',
            hint: '25',
            controller: _ageController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu edad';
              }
              if (int.tryParse(value) == null) {
                return 'Ingresa una edad válida';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Contraseña',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa una contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              if (!RegExp(
                r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
              ).hasMatch(value)) {
                return 'La contraseña debe tener mayúsculas, minúsculas, números y símbolos';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomTextField(
            label: 'Confirmar contraseña',
            hint: '••••••••',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, confirma tu contraseña';
              }
              return null;
            },
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Mensaje de error
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],

          // Botón de registro
          CustomButton(
            text: 'Crear Cuenta',
            onPressed: _register,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Términos y condiciones
          Text(
            'Al registrarte, aceptas nuestros Términos de servicio y Política de privacidad.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
