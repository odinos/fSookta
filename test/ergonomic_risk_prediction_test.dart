import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart';
import 'package:fsookta/core/ergonomics_risk_prediction/data/models/logistic_regression_weights.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logistic predictor maps joint features to risk result', () async {
    final predictor = LogisticRegressionPredictor.fromWeights(
      const LogisticRegressionWeights(
        version: 'test',
        intercept: -1,
        weights: [2, 2, 2],
        thresholds: RiskThresholds(medium: 0.35, high: 0.6, veryHigh: 0.82),
      ),
    );

    final result = await predictor.predictRiskLevel([1, 1, 1]);

    expect(result.confidenceScore, inInclusiveRange(0, 1));
    expect(result.level, RiskLevel.veryHigh);
    expect(result.actionRecommendation, isNotEmpty);
  });

  test('logistic predictor rejects invalid feature length', () async {
    final predictor = LogisticRegressionPredictor.fromWeights(
      const LogisticRegressionWeights(
        version: 'test',
        intercept: 0,
        weights: [1, 1],
        thresholds: RiskThresholds(),
      ),
    );

    expect(
      () => predictor.predictRiskLevel([1]),
      throwsA(isA<InvalidJointFeaturesException>()),
    );
  });

  test('assess risk use case initializes predictor lazily', () async {
    final useCase = AssessRiskUseCase(
      LogisticRegressionPredictor(
        assetPath: 'assets/models/logistic_weights.json',
      ),
    );

    final result = await useCase(List<double>.filled(51, 0.7));

    expect(result.confidenceScore, inInclusiveRange(0, 1));
  });
}
