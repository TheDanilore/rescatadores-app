import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Services
import 'package:rescatadores_app/domain/services/initialization_service.dart';

// Configuration
import 'package:rescatadores_app/config/theme.dart';

// Pages
import 'package:rescatadores_app/presentation/pages/auth_check.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Services
  final InitializationService _initService = InitializationService();

  // State variables
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApplication();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _initializeApplication() async {
    try {
      // Verifica si Firebase ya está inicializado
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Resto de tu código de inicialización
      await _initService.initialize();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isInitialized = true);
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthCheck()));
      }
    } catch (e, stackTrace) {
      _handleInitializationError(e, stackTrace);
    }
  }

  void _handleInitializationError(Object error, StackTrace stackTrace) {
    print('Initialization Error: $error');
    print('Stack Trace: $stackTrace');

    if (mounted) {
      setState(() {
        _errorMessage = "Error al inicializar la app: ${error.toString()}";
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });
    _initializeApplication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', width: 300),
                    const SizedBox(height: 24),
                    Text(
                      'Rescatadores App',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppTheme.lightBackgroundColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestiona el seguimiento de tus Rescatadoress',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightBackgroundColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildStatusWidget(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    if (!_isInitialized) {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.lightBackgroundColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: AppTheme.buildElevatedButtonStyle(
              AppTheme.primaryColor,
              Colors.white,
            ),
            onPressed: _retryInitialization,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
