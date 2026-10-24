import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase notifications are configured for Android, iOS and Web.',
      ),
    };
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBuj1vB160FKwaLYH1uAJVi4BHazRD2EKk',
    appId: '1:71208201851:android:8215c4a34905f9a194bcde',
    messagingSenderId: '71208201851',
    projectId: 'inventa-5cad4',
    storageBucket: 'inventa-5cad4.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDn0NY8KQ4KVfUv6TZV1XQHl_2TFdRYjZ4',
    appId: '1:71208201851:ios:4a2b5e1144657e0194bcde',
    messagingSenderId: '71208201851',
    projectId: 'inventa-5cad4',
    storageBucket: 'inventa-5cad4.firebasestorage.app',
    iosBundleId: 'com.example.inventa',
  );

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCqXvNa9fnTUyswJK8zGzOhNVvBJsAVdSs',
    appId: '1:71208201851:web:760e8cbfe84a904394bcde',
    messagingSenderId: '71208201851',
    projectId: 'inventa-5cad4',
    authDomain: 'inventa-5cad4.firebaseapp.com',
    storageBucket: 'inventa-5cad4.firebasestorage.app',
  );
}
