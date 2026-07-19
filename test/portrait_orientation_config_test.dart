import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS supports portrait orientation only', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(
      plist,
      contains('<string>UIInterfaceOrientationPortrait</string>'),
    );
    expect(
      plist,
      isNot(contains('UIInterfaceOrientationLandscapeLeft')),
    );
    expect(
      plist,
      isNot(contains('UIInterfaceOrientationLandscapeRight')),
    );
    expect(
      plist,
      isNot(contains('UIInterfaceOrientationPortraitUpsideDown')),
    );
  });

  test('iOS opts out of iPad multitasking for portrait-only support', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(
      plist,
      contains('<key>UIRequiresFullScreen</key>\n\t<true/>'),
    );
  });

  test('Android main activity is locked to portrait', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android:screenOrientation="portrait"'));
  });
}
