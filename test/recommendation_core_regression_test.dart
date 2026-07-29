import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';
import 'package:fsookta/core/services/recommendation_catalog_service.dart';

void main() {
  test('recommendation localization does not change calculation outputs', () {
    const rebaInput = RebaInputData(
      dailyIncome: 500,
      trunkScore: 5,
      neckScore: 2,
      legScore: 2,
      upperArmScore: 3,
      lowerArmScore: 2,
      wristScore: 2,
      loadScore: 2,
      couplingScore: 1,
      activityScore: 1,
    );
    const isoInput = ErgoInputData(
      jobType: JobType.lifting,
      loadWeight: 20,
      horizontalDist: 60,
      verticalHeight: 30,
      liftFrequency: 5,
      durationHours: 4,
      transportDistance: 12,
    );
    final before = ErgoCalculator.calculateRebaRisk(rebaInput);
    final iso = ErgoCalculator.calculateLiftingRisk(isoInput);

    expect(before.userScore, 9);
    expect(before.riskLevel, RiskLevel.veryHigh);
    expect(before.economicLoss, 32244);
    expect(iso.userScore, 6);
    expect(iso.riskLevel, RiskLevel.medium);

    RecommendationCatalogService.joinedText(
      selectionKey: 'act_rest_stretch',
      language: RecommendationLanguage.en,
      riskLevel: before.riskLevel.name,
    );

    final after = ErgoCalculator.calculateRebaRisk(rebaInput);
    final isoAfter = ErgoCalculator.calculateLiftingRisk(isoInput);

    expect(after.userScore, before.userScore);
    expect(after.riskLevel, before.riskLevel);
    expect(after.economicLoss, before.economicLoss);
    expect(isoAfter.userScore, iso.userScore);
    expect(isoAfter.riskLevel, iso.riskLevel);
  });
}
