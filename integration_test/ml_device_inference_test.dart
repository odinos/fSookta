import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:fsookta/core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart'
    as ml;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ML-DEVICE-001 runs ONNX inference on device', (tester) async {
    final schema = await const ml.JointFeatureSchemaLoader().load();
    final neutral = _neutralMoveNetFeatures();
    final bent = _deepBendMoveNetFeatures();

    final xgBoost = ml.XGBoostOnnxPredictor(featureSchema: schema);
    addTearDown(xgBoost.dispose);
    await xgBoost.initModel();
    final xgNeutral = await xgBoost.predictRiskLevel(neutral);
    final xgBent = await xgBoost.predictRiskLevel(bent);

    expect(xgNeutral.confidenceScore, inInclusiveRange(0, 1));
    expect(xgBent.confidenceScore, inInclusiveRange(0, 1));
    expect(xgBent.actionRecommendation, isNotEmpty);

    await expectLater(
      () => xgBoost.predictRiskLevel(List<double>.filled(50, 0.5)),
      throwsA(isA<ml.InvalidJointFeaturesException>()),
    );

    // ignore: avoid_print
    print(
      'ML_DEVICE_RESULT: '
      'xgNeutral=${xgNeutral.confidenceScore.toStringAsFixed(4)} '
      'xgBent=${xgBent.confidenceScore.toStringAsFixed(4)}',
    );
  });
}

List<double> _neutralMoveNetFeatures() {
  final values = List<double>.filled(51, 0);
  for (var index = 0; index < values.length; index += 3) {
    values[index] = 0.5;
    values[index + 1] = 0.5;
    values[index + 2] = 0.9;
  }
  return values;
}

List<double> _deepBendMoveNetFeatures() {
  final values = _neutralMoveNetFeatures();
  void setPoint(int landmarkIndex, double x, double y, double score) {
    final offset = landmarkIndex * 3;
    values[offset] = x;
    values[offset + 1] = y;
    values[offset + 2] = score;
  }

  setPoint(5, 0.82, 0.63, 0.95);
  setPoint(6, 0.84, 0.65, 0.95);
  setPoint(11, 0.35, 0.62, 0.95);
  setPoint(12, 0.38, 0.64, 0.95);
  setPoint(3, 0.92, 0.72, 0.9);
  setPoint(7, 0.72, 0.78, 0.9);
  setPoint(9, 0.66, 0.9, 0.9);
  setPoint(13, 0.36, 0.82, 0.9);
  setPoint(15, 0.34, 0.98, 0.9);
  return values;
}
