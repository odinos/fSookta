import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store release uses the new 1.3.11 train and synchronized build 28', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildInfo = File('lib/app/build_info.dart').readAsStringSync();

    expect(pubspec, contains('version: 1.3.11+28'));
    expect(buildInfo, contains("versionName = '1.3.11'"));
    expect(buildInfo, contains("buildNumber = '28'"));
  });
}
