import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final screenshotDir =
      Platform.environment['SOOKTA_SCREENSHOT_DIR'] ?? 'qa/screenshots/flutter_ios';
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final file = File('$screenshotDir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
