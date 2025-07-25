// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAaawTqisHVCgYpDZlqjx8S9bR_iIfZWas',
    appId: '1:506221282284:web:599361891fc87ffb07f6c9',
    messagingSenderId: '506221282284',
    projectId: 'asesor-app-9ea9d',
    authDomain: 'asesor-app-9ea9d.firebaseapp.com',
    storageBucket: 'asesor-app-9ea9d.firebasestorage.app',
    measurementId: 'G-8FJWBQD7PQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsr-yCZq0A8Fu_mmHsU2yZ9LvJBy_rDn4',
    appId: '1:506221282284:android:9c55163e85f7b54e07f6c9',
    messagingSenderId: '506221282284',
    projectId: 'asesor-app-9ea9d',
    storageBucket: 'asesor-app-9ea9d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD6cU4VnEEpFPczNAo5mCaXpXQW-w1GESM',
    appId: '1:506221282284:ios:176370107b2d875507f6c9',
    messagingSenderId: '506221282284',
    projectId: 'asesor-app-9ea9d',
    storageBucket: 'asesor-app-9ea9d.firebasestorage.app',
    androidClientId: '506221282284-muevs0i292ntn3771e5oebeblq0c2js1.apps.googleusercontent.com',
    iosClientId: '506221282284-72t8rmcqqfeiff0vht1rt8tab6kcutt4.apps.googleusercontent.com',
    iosBundleId: 'com.example.rescatadoresApp',
  );

}