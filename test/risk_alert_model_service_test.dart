import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';
import 'package:fsookta/core/services/risk_alert_model_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads baseline Logistic Regression and XGBoost risk alert model',
      () async {
    final model = await RiskAlertModelService.load();
    const rebaInput = RebaInputData(
      dailyIncome: 500,
      trunkScore: 4,
      neckScore: 2,
      legScore: 2,
      upperArmScore: 4,
      lowerArmScore: 2,
      wristScore: 2,
      loadScore: 2,
      activityScore: 1,
    );
    final result = ErgoCalculator.calculateRebaRisk(rebaInput);
    const ergoInput = ErgoInputData(
      jobType: JobType.reba,
      dailyIncome: 500,
    );

    final alert = model.predict(
      jobType: JobType.reba,
      result: result,
      ergoInput: ergoInput,
      rebaInput: rebaInput,
    );

    expect(alert.probability, inInclusiveRange(0, 1));
    expect(alert.logisticProbability, inInclusiveRange(0, 1));
    expect(alert.xgBoostProbability, inInclusiveRange(0, 1));
    expect({AiAlertLevel.high, AiAlertLevel.critical}, contains(alert.level));
    expect(alert.featureImportance, isNotEmpty);
    expect(alert.usesResearchTrainedModel, isFalse);
  });

  test('push/pull force contributes to feature importance', () async {
    final model = await RiskAlertModelService.load();
    const ergoInput = ErgoInputData(
      jobType: JobType.pushPull,
      initialForce: 40,
      sustainForce: 24,
      durationHours: 8,
    );
    final result = ErgoCalculator.calculatePushPullRisk(ergoInput);

    final alert = model.predict(
      jobType: JobType.pushPull,
      result: result,
      ergoInput: ergoInput,
      rebaInput: const RebaInputData(),
    );

    expect(
      alert.featureImportance.map((feature) => feature.key),
      contains('force_ratio_norm'),
    );
  });
}
