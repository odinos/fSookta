import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/models/ml_inference_status.dart';

void main() {
  const alert = AiRiskAlert(
    probability: 0.8,
    logisticProbability: 0,
    xgBoostProbability: 0.8,
    level: AiAlertLevel.high,
    modelVersion: 'test-model',
    modelSource: 'test',
    featureImportance: [],
  );

  test('successful XGBoost outcome reports a completed advisory check', () {
    const outcome = XGBoostInferenceOutcome.success(alert);

    expect(outcome.state, MlInferenceState.success);
    expect(outcome.alert, same(alert));
    expect(
      xgboostPhotoStatus(outcome: outcome, thai: true),
      contains('ตรวจเทียบสัญญาณด้วย XGBoost แล้ว'),
    );
  });

  test('failed XGBoost outcome reports deterministic fallback', () {
    const outcome = XGBoostInferenceOutcome.runtimeError(
      'xgboost_runtime_error',
    );

    expect(outcome.alert, isNull);
    expect(
      xgboostPhotoStatus(outcome: outcome, thai: true),
      contains('XGBoost ไม่พร้อม'),
    );
    expect(
      xgboostPhotoStatus(outcome: outcome, thai: false),
      isNot(contains('checked with XGBoost')),
    );
  });

  test('assessment breakdown preserves XGBoost provenance', () {
    const breakdown = AssessmentBreakdown(
      primaryMethod: AssessmentMethod.reba,
      rebaInput: RebaInputData(),
      rebaResult: ErgoResult(
        riskLevel: RiskLevel.low,
        techScore: 2,
        userScore: 2,
        userScoreColor: 0xFF66BB6A,
        limitValue: 9,
        suggestionKey: 'sugg_safe',
      ),
      ergoInput: ErgoInputData(jobType: JobType.reba),
      xgboostInferenceState: 'runtimeError',
      xgboostErrorCode: 'xgboost_runtime_error',
      deterministicScoreBeforeMl: 2,
    );

    final restored = AssessmentBreakdown.fromJson(breakdown.toJson());

    expect(restored.xgboostInferenceState, 'runtimeError');
    expect(restored.xgboostErrorCode, 'xgboost_runtime_error');
    expect(restored.deterministicScoreBeforeMl, 2);
  });
}
