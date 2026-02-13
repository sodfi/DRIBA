// Firebase configuration for driba-os project
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      case TargetPlatform.macOS: return macos;
      case TargetPlatform.windows: return windows;
      case TargetPlatform.linux: return linux;
      default: throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    authDomain: 'driba-os.firebaseapp.com',
    storageBucket: 'driba-os.firebasestorage.app',
    measurementId: 'G-YYLFN4X1JF',
  );

  // Register Android app in Firebase Console:
  // Package: com.driba.os → download google-services.json → android/app/
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    storageBucket: 'driba-os.firebasestorage.app',
  );

  // Register iOS app in Firebase Console:
  // Bundle ID: com.driba.os → download GoogleService-Info.plist → ios/Runner/
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    storageBucket: 'driba-os.firebasestorage.app',
    iosBundleId: 'com.driba.os',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    storageBucket: 'driba-os.firebasestorage.app',
    iosBundleId: 'com.driba.os',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    storageBucket: 'driba-os.firebasestorage.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCMSMsYWk3u_mawv1YyKdQTfd1OXeiTtc4',
    appId: '1:475335977281:web:09ef849c22e0c4afecd9c0',
    messagingSenderId: '475335977281',
    projectId: 'driba-os',
    storageBucket: 'driba-os.firebasestorage.app',
  );
}
