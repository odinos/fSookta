import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assessment bypass config and build flag are absent', () {
    expect(File('lib/app/uat_config.dart').existsSync(), isFalse);

    final productionFiles = <File>[
      ...Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart')),
      File('android/app/build.gradle'),
      File('android/app/src/main/AndroidManifest.xml'),
      File('ios/Flutter/Debug.xcconfig'),
      File('ios/Flutter/Release.xcconfig'),
      File('ios/Runner.xcodeproj/project.pbxproj'),
      File('ios/Runner/Info.plist'),
      File('ios/Podfile'),
      ...Directory('ios/scripts').listSync().whereType<File>(),
    ];

    for (final file in productionFiles) {
      final content = file.readAsStringSync();
      expect(
        content,
        isNot(contains('SOOKTA_UAT_BYPASS')),
        reason: file.path,
      );
      expect(content, isNot(contains('UatConfig')), reason: file.path);
      expect(
        content,
        isNot(contains('UAT mode: View Assessment')),
        reason: file.path,
      );
    }
  });

  test('button and handler both consume production readiness', () {
    final source =
        File('lib/screens/main/evaluation_form_screen.dart').readAsStringSync();

    expect(
      RegExp(r'AssessmentReadiness\(').allMatches(source).length,
      greaterThanOrEqualTo(2),
    );
    expect(
      source,
      contains('onAnalyze: readiness.canAnalyze ? _analyze : null'),
    );
    expect(source, contains('if (!readiness.canAnalyze)'));
  });

  test('README distinguishes production and research model status', () {
    final readme = File('README.md').readAsStringSync();

    expect(readme, contains('Legacy posture Logistic'));
    expect(readme, contains('ไม่ได้รวมในแอป'));
    expect(readme, contains('template coefficients'));
    expect(readme, contains('XGBoost advisory-only'));
    expect(readme, contains('SOOKTA_TELEMETRY_ENABLED=true'));
  });

  test('Android build has one active Groovy Gradle configuration', () {
    for (final path in [
      'android/settings.gradle.kts',
      'android/build.gradle.kts',
      'android/app/build.gradle.kts',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }

    final settings = File('android/settings.gradle').readAsStringSync();
    final app = File('android/app/build.gradle').readAsStringSync();
    expect(settings, contains('com.google.gms.google-services'));
    expect(settings, contains('com.google.firebase.crashlytics'));
    expect(app, contains('abiFilters'));
    expect(app, contains('signingConfigs'));
  });

  test('iOS release artifact has a non-destructive framework inspection gate',
      () {
    final script = File('tooling/verify_ios_release_artifact.sh');
    expect(script.existsSync(), isTrue);
    final source = script.readAsStringSync();
    expect(source, contains('integration_test.framework'));
    expect(source, contains('otool -L'));
    expect(source, contains('nm -u'));
  });
}
