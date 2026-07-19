import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store release uses the new 1.3.7 train and synchronized build 24', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildInfo = File('lib/app/build_info.dart').readAsStringSync();

    expect(pubspec, contains('version: 1.3.7+24'));
    expect(buildInfo, contains("versionName = '1.3.7'"));
    expect(buildInfo, contains("buildNumber = '24'"));
  });
}
