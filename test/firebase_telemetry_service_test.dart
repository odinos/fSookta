import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/services/firebase_telemetry_service.dart';

void main() {
  test('telemetry is disabled unless a local build explicitly enables it', () {
    expect(FirebaseTelemetryService.enabledByDefault, isFalse);
  });

  test('filesystem failures become a path-free error code', () {
    final code = FirebaseTelemetryService.errorCode(
      const FileSystemException(
        'failed to read',
        '/Users/private-person/Pictures/posture.jpg',
      ),
    );

    expect(code, 'file_system_error');
    expect(code, isNot(contains('private-person')));
    expect(code, isNot(contains('posture.jpg')));
  });

  test('platform and format failures become bounded category codes', () {
    expect(
      FirebaseTelemetryService.errorCode(
        PlatformException(code: 'MODEL_LOAD_FAILED'),
      ),
      'platform_model_load_failed',
    );
    expect(
      FirebaseTelemetryService.errorCode(const FormatException('bad input')),
      'invalid_input_format',
    );
  });
}
