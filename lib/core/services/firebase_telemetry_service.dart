import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FirebaseTelemetryService {
  FirebaseTelemetryService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver? _observer;
  static var _enabled = false;

  static bool get isEnabled => _enabled;

  static List<NavigatorObserver> get navigatorObservers {
    final observer = _observer;
    return observer == null ? const [] : [observer];
  }

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) return;

    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await _analytics.setAnalyticsCollectionEnabled(true);
    _observer = FirebaseAnalyticsObserver(
      analytics: _analytics,
      onError: (error) => debugPrint('Firebase Analytics screen error: $error'),
    );
    _enabled = true;

    await _analytics.logAppOpen();
    await logEvent('app_start', {
      'platform': defaultTargetPlatform.name,
      'build_mode': kReleaseMode ? 'release' : 'debug',
    });
    await FirebaseCrashlytics.instance.log('Firebase telemetry initialized');
  }

  static Future<void> logImageAdded({
    required String source,
    required int imageCount,
  }) {
    return logEvent('assessment_image_added', {
      'source': source,
      'image_count': imageCount,
    });
  }

  static Future<void> logAssessmentCalculated({
    required String activity,
    required String jobType,
    required String primaryMethod,
    required String riskLevel,
    required int score,
    required int imageCount,
    required bool usesIso11228,
  }) {
    return logEvent('assessment_calculated', {
      'activity': activity,
      'job_type': jobType,
      'primary_method': primaryMethod,
      'risk_level': riskLevel,
      'score': score,
      'image_count': imageCount,
      'uses_iso11228': usesIso11228 ? 1 : 0,
    });
  }

  static Future<void> logAssessmentSaved({
    required String activity,
    required String beforeRisk,
    required String afterRisk,
    required int beforeScore,
    required int afterScore,
    required int suggestionCount,
  }) {
    return logEvent('assessment_saved', {
      'activity': activity,
      'before_risk': beforeRisk,
      'after_risk': afterRisk,
      'before_score': beforeScore,
      'after_score': afterScore,
      'suggestion_count': suggestionCount,
    });
  }

  static Future<void> logExportCreated({
    required String exportType,
    required int recordCount,
  }) {
    return logEvent('export_created', {
      'export_type': exportType,
      'record_count': recordCount,
    });
  }

  static Future<void> logEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    if (!_enabled || Firebase.apps.isEmpty) return;

    final safeParameters = _safeParameters(parameters);
    try {
      await _analytics.logEvent(name: name, parameters: safeParameters);
      await FirebaseCrashlytics.instance.log(
        '$name ${safeParameters.entries.map((entry) => '${entry.key}=${entry.value}').join(', ')}',
      );
    } catch (error) {
      debugPrint('Firebase telemetry event failed: $name $error');
    }
  }

  static Map<String, Object> _safeParameters(Map<String, Object> parameters) {
    return parameters.map((key, value) {
      final normalizedKey = _safeKey(key);
      final safeValue = switch (value) {
        String() => value.length > 100 ? value.substring(0, 100) : value,
        int() => value,
        double() => value,
        bool() => value ? 1 : 0,
        _ => value.toString(),
      };
      return MapEntry(normalizedKey, safeValue);
    });
  }

  static String _safeKey(String key) {
    var normalized = key.replaceAll(RegExp('[^A-Za-z0-9_]'), '_');
    if (normalized.isEmpty || !RegExp(r'^[A-Za-z]').hasMatch(normalized)) {
      normalized = 'p_$normalized';
    }
    return normalized.length <= 40 ? normalized : normalized.substring(0, 40);
  }
}
