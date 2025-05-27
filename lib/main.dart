import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rescatadores_app/config/theme.dart';
import 'package:rescatadores_app/config/theme_manager.dart';
import 'package:rescatadores_app/presentation/pages/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the correct configurations for the platform
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    print('Firebase initialization error: $e');
    print('Detailed stack trace: $stackTrace');
    // mostrar un diálogo de error al usuario
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData _themeData = AppTheme.lightTheme;

  void _onThemeChanged(ThemeData theme) {
    setState(() {
      _themeData = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeManager(
      themeData: _themeData,
      onThemeChanged: _onThemeChanged,
      child: MaterialApp(
        title: 'Rescatadores App',
        theme: _themeData,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
