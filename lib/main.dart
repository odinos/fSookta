import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'app/sookta_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final crashlyticsReady = await _initializeCrashlytics();
      if (crashlyticsReady) {
        _installCrashlyticsErrorHandlers();
      }

      runApp(const SooktaApp());
    },
    (error, stack) {
      _recordFatalError(error, stack);
    },
  );
}

Future<bool> _initializeCrashlytics() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    return true;
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'firebase_crashlytics',
        context: ErrorDescription('initializing Firebase Crashlytics'),
      ),
    );
    return false;
  }
}

void _installCrashlyticsErrorHandlers() {
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _recordFatalError(error, stack);
    return true;
  };
}

void _recordFatalError(Object error, StackTrace stack) {
  if (Firebase.apps.isEmpty) return;
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}
