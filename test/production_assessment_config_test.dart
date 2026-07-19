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
      File('android/app/build.gradle.kts'),
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
}
