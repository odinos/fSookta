import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/uat_config.dart';

void main() {
  test('UAT bypass allows uploaded video frames while analysis is idle', () {
    expect(
      UatConfig.canBypassAssessment(
        enabled: true,
        hasMedia: true,
        poseBusy: false,
      ),
      isTrue,
    );
  });

  test('UAT bypass never allows empty media or analysis in progress', () {
    expect(
      UatConfig.canBypassAssessment(
        enabled: true,
        hasMedia: false,
        poseBusy: false,
      ),
      isFalse,
    );
    expect(
      UatConfig.canBypassAssessment(
        enabled: true,
        hasMedia: true,
        poseBusy: true,
      ),
      isFalse,
    );
  });

  test('production builds cannot bypass assessment validation', () {
    expect(
      UatConfig.canBypassAssessment(
        enabled: false,
        hasMedia: true,
        poseBusy: false,
      ),
      isFalse,
    );
  });
}
