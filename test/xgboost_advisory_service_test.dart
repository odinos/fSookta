import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/xgboost_advisory_service.dart';

void main() {
  test('XGBoost advisory never changes deterministic score or risk', () {
    const deterministic = ErgoResult(
      riskLevel: RiskLevel.low,
      techScore: 2,
      userScore: 2,
      userScoreColor: 0xFF66BB6A,
      limitValue: 9,
      suggestionKey: 'sugg_safe',
    );
    const alert = AiRiskAlert(
      probability: 0.95,
      logisticProbability: 0,
      xgBoostProbability: 0.95,
      level: AiAlertLevel.critical,
      modelVersion: 'test',
      modelSource: 'test',
      featureImportance: [],
    );

    final result = attachAdvisoryXGBoostAlert(deterministic, alert);

    expect(result.userScore, deterministic.userScore);
    expect(result.riskLevel, deterministic.riskLevel);
    expect(result.userScoreColor, deterministic.userScoreColor);
    expect(result.suggestionKey, deterministic.suggestionKey);
    expect(result.aiRiskAlert, same(alert));
  });
}
