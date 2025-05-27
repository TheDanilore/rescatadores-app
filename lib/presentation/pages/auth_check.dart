import 'package:rescatadores_app/presentation/pages/alumno/home_screen.dart';
import 'package:rescatadores_app/presentation/pages/asesor/asesor_home_screen.dart';
import 'package:rescatadores_app/presentation/pages/admin/admin_home_screen.dart';
import 'package:rescatadores_app/presentation/pages/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Service
import 'package:rescatadores_app/domain/services/notification_service.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<void> _requestPermissions() async {
    final NotificationService _notificationService = NotificationService();
    await _notificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData) {
                var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                var role = userData['role'];

                print("Rol del usuario: $role");

                _requestPermissions();

                switch (role) {
                  case 'administrador':
                    return const AdminHomeScreen();
                  case 'asesor':
                    return const AsesorHomeScreen();
                  case 'alumno':
                    return const HomeScreen();
                  default:
                    return const LoginScreen();
                }
              }

              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
