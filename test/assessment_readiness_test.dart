import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/services/assessment_readiness.dart';

void main() {
  const ready = AssessmentReadiness(
    hasMedia: true,
    hasImageQualityIssues: false,
    poseAssessmentReady: true,
    poseBusy: false,
    requiredDataIssues: <String>[],
  );

  test('valid production input is ready for assessment', () {
    expect(ready.canAnalyze, isTrue);
  });

  test('each incomplete production condition blocks assessment', () {
    final blocked = <AssessmentReadiness>[
      ready.copyWith(hasMedia: false),
      ready.copyWith(hasImageQualityIssues: true),
      ready.copyWith(poseAssessmentReady: false),
      ready.copyWith(poseBusy: true),
      ready.copyWith(requiredDataIssues: const <String>['missing distance']),
    ];

    expect(blocked.every((state) => !state.canAnalyze), isTrue);
  });
}
