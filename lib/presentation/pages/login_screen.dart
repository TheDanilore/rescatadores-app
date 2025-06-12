import 'package:flutter/material.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/presentation/pages/admin/admin_home_screen.dart';
import 'package:rescatadores_app/presentation/pages/asesor/asesor_home_screen.dart';
import 'package:rescatadores_app/presentation/pages/forgot_password_screen.dart';
import 'package:rescatadores_app/presentation/pages/alumno/home_screen.dart';
import 'package:rescatadores_app/presentation/pages/register_screen.dart';
import 'package:rescatadores_app/presentation/widgets/custom_button.dart';
import 'package:rescatadores_app/presentation/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Login con Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final userId = userCredential.user!.uid;

      // 2. Obtener documento en Firestore
      final userDocSnapshot =
          await FirebaseFirestore.instance
              .collection('users_rescatadores_app')
              .doc(userId)
              .get();

      if (!userDocSnapshot.exists) {
        // Usuario no registrado en Firestore
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage =
              'Tu cuenta no está registrada correctamente. Contacta con soporte.';
        });
        return;
      }

      final userData = userDocSnapshot.data();

      if (userData == null || userData['status'] != 'activo') {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Tu cuenta está inactiva. Contacta con soporte.';
        });
        return;
      }

      // 3. Actualizar último login
      await userDocSnapshot.reference.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // 4. Navegar según el rol
      _navigateByUserRole(userDocSnapshot);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
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

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final userId = userCredential.user!.uid;

      final userDocRef = FirebaseFirestore.instance
          .collection('users_rescatadores_app')
          .doc(userId);

      final userDocSnapshot = await userDocRef.get();

      if (!userDocSnapshot.exists) {
        // Crear nuevo documento
        await userDocRef.set({
          'name': googleUser.displayName,
          'email': googleUser.email,
          'role': 'alumno',
          'groups': [],
          'status': 'activo',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Obtener el nuevo snapshot para navegar correctamente
        final newUserDocSnapshot = await userDocRef.get();
        _navigateByUserRole(newUserDocSnapshot);
      } else {
        // Si existe, validar estado y actualizar login
        final data = userDocSnapshot.data();
        if (data == null || data['status'] != 'activo') {
          await FirebaseAuth.instance.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta está inactiva. Contacta con soporte.';
          });
          return;
        }

        await userDocRef.update({'lastLogin': FieldValue.serverTimestamp()});
        _navigateByUserRole(userDocSnapshot);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de autenticación: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inesperado: $e';
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
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      default:
        return 'Error de autenticación. Inténtalo de nuevo.';
    }
  }

  void _navigateByUserRole(DocumentSnapshot userDoc) {
    final role = userDoc.get('role');

    Widget targetScreen;

    switch (role) {
      case 'administrador':
        targetScreen = const AdminHomeScreen();
        break;
      case 'asesor':
        targetScreen = const AsesorHomeScreen();
        break;
      case 'alumno':
        targetScreen = const HomeScreen();
        break;
      default:
        setState(() {
          _errorMessage = 'Rol no reconocido. Contacta con soporte.';
        });
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => targetScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final isLargeScreen = constraints.maxWidth > 600;

          if (isLargeScreen) {
            // Diseño de escritorio: dos columnas
            return Row(
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
                            'Inicia Sesión en Rescatadores App',
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
                      child: _buildLoginForm(context, isLargeScreen),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Diseño móvil
            return Scaffold(
              body: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingL,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset('assets/logo.png', width: 200, height: 200),
                        const SizedBox(height: AppTheme.spacingM),

                        // Login Form
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            child: _buildLoginForm(context, isLargeScreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLargeScreen) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenido a Rescatadores App',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimaryColor,
              fontSize: isLargeScreen ? 32 : 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Inicia sesión para continuar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: isLargeScreen ? 20 : 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

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
            label: 'Contraseña',
            hint: '••••••••',
            controller: _passwordController,
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, ingresa tu contraseña';
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
          const SizedBox(height: AppTheme.spacingS),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Mensaje de error
          if (_errorMessage != null) ...[
            const SizedBox(height: AppTheme.spacingM),
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
          ],

          const SizedBox(height: AppTheme.spacingL),
          CustomButton(
            text: 'Iniciar Sesión',
            onPressed: _login,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppTheme.spacingM),
          CustomButton(
            text: 'Continuar con Google',
            icon: Icons.login,
            onPressed: _loginWithGoogle,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes una cuenta?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  'Regístrate',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
