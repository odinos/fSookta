// File generated from the Firebase config files for Sookta.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase has not been configured for web in this app.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase has not been configured for this platform in this app.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAh0ZopLz_-Fe3p8OVC1_c1lytPGtEWqOY',
    appId: '1:420009490598:android:afaf2df24005c0b3b19c67',
    messagingSenderId: '420009490598',
    projectId: 'sookta-flutter',
    storageBucket: 'sookta-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDP7tWrUl58x_JHTiMDrAvJlSc4MEKMb9A',
    appId: '1:420009490598:ios:f980d1f456395f32b19c67',
    messagingSenderId: '420009490598',
    projectId: 'sookta-flutter',
    storageBucket: 'sookta-flutter.firebasestorage.app',
    iosBundleId: 'com.kdev.sookta',
  );
}
