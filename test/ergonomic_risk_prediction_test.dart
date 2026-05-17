import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart';
import 'package:fsookta/core/ergonomics_risk_prediction/data/models/logistic_regression_weights.dart';
import 'package:fsookta/core/models/pose_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logistic predictor maps joint features to risk result', () async {
    final predictor = LogisticRegressionPredictor.fromWeights(
      const LogisticRegressionWeights(
        version: 'test',
        featureSchemaId: 'test-schema',
        modelSource: 'test',
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
        featureSchemaId: 'test-schema',
        modelSource: 'test',
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

  test('loads canonical MoveNet joint feature schema from assets', () async {
    final schema = await const JointFeatureSchemaLoader().load();

    expect(schema.schemaId, 'movenet-thunder-v1-17x3-normalized');
    expect(schema.featureCount, 51);
    expect(schema.featureNames.first, 'nose_x');
    expect(schema.featureNames.last, 'rightAnkle_score');
  });

  test('extracts deterministic MoveNet joint features with missing defaults',
      () async {
    final schema = await const JointFeatureSchemaLoader().load();
    final extractor = MoveNetJointFeatureExtractor(schema);

    const person = Person(
      score: 0.8,
      keyPoints: [
        KeyPoint(
          bodyPart: PoseLandmark.nose,
          coordinate: Point2D(0.25, 0.5),
          score: 0.9,
        ),
        KeyPoint(
          bodyPart: PoseLandmark.rightAnkle,
          coordinate: Point2D(1.2, -0.1),
          score: 0.7,
        ),
      ],
    );

    final features = extractor.extract(person);

    expect(features, hasLength(51));
    expect(features.take(3), [0.25, 0.5, 0.9]);
    expect(features.skip(3).take(3), [0, 0, 0]);
    expect(features.skip(48).take(3), [1, 0, 0.7]);
  });
}
