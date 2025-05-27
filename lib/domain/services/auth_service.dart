import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;

  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Iniciar sesión con Google y registrar en Firestore
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print("Inicio de sesión cancelado por el usuario");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      if (_user != null) {
        await _saveUserToFirestore(_user!);
      }

      notifyListeners();
    } catch (e) {
      print("Error al iniciar sesión con Google: $e");
    }
  }

  // Registrar usuario con correo y contraseña
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;

      if (_user != null) {
        await _saveUserToFirestore(_user!);
      }

      notifyListeners();
    } catch (e) {
      print("Error al registrar usuario: $e");
      throw e;
    }
  }

  // Iniciar sesión con correo y contraseña
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      _user = userCredential.user;

      if (_user != null) {
        await _updateLastLogin(_user!.uid);
      }

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No se encontró un usuario con este correo');
      } else if (e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta');
      }
      rethrow;
    } catch (e) {
      print("Error al iniciar sesión: $e");
      rethrow;
    }
  }

  // Guardar o actualizar usuario en Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userRef = _db.collection('users').doc(user.uid);
      final userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        await userRef.update({
          'name': user.displayName ?? "Usuario",
          'email': user.email,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await userRef.set({
          'uid': user.uid,
          'name': user.displayName ?? "Usuario",
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error al guardar usuario en Firestore: $e");
    }
  }

  // Actualizar último inicio de sesión
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error al actualizar último inicio de sesión: $e");
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error al enviar email de recuperación: $e");
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _user = null;
    notifyListeners();
  }
}
