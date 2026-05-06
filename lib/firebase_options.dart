import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'iOS není nakonfigurován. Přidej iOS aplikaci ve Firebase Console a spusť flutterfire configure.',
        );
      default:
        throw UnsupportedError('Tato platforma není podporována.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDTDVUFTXi9QVvgGGDcRP7-2NzOeckypR4',
    appId: '1:929846473056:web:3005da5a5aecc1f7e72e05',
    messagingSenderId: '929846473056',
    projectId: 'qrkni-44ce9',
    storageBucket: 'qrkni-44ce9.firebasestorage.app',
    authDomain: 'qrkni-44ce9.firebaseapp.com',
    measurementId: 'G-N5ZMJPZXF5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmQGFhoefg8PtPg_fmqAj7WSb8AITw6-c',
    appId: '1:929846473056:android:1d76afd031b496c7e72e05',
    messagingSenderId: '929846473056',
    projectId: 'qrkni-44ce9',
    storageBucket: 'qrkni-44ce9.firebasestorage.app',
  );
}
