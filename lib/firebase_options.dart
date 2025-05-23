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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBltNxEmNq1z9Gupciu9_8o6A7u2CNONuc',
    appId: '1:81931429241:android:f40ab497b5da473aa5fba8',
    messagingSenderId: '81931429241',
    projectId: 'cos-connect',
    storageBucket: 'cos-connect.firebasestorage.app',
  );

  // For Firebase JS SDK v7.20.0 and later, measurementId is optional
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBCmic-quEQJORibzDx1TpscGgmiZcIpw4",
    authDomain: "cos-connect.firebaseapp.com",
    projectId: "cos-connect",
    storageBucket: "cos-connect.firebasestorage.app",
    messagingSenderId: "81931429241",
    appId: "1:81931429241:web:68d77095d8164938a5fba8",
    measurementId: "G-KXTE5PB3PV"
  );
}
