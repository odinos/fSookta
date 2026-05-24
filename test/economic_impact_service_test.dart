import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/economic_impact_service.dart';

void main() {
  test('stores treatment and body-area survey costs', () {
    expect(
      EconomicImpactService.averageTreatmentCost('รวมรายได้ที่สูญเสีย'),
      closeTo(7681.625087, 0.001),
    );
    expect(
      EconomicImpactService.bodyPartAverageCost(BodyPart.legs),
      closeTo(860.0, 0.01),
    );
    expect(
      EconomicImpactService.averageMedicalVisitCost(),
      closeTo(1128.478724, 0.001),
    );
  });

  test('estimates cost impact from risk level and affected body parts', () {
    final impact = EconomicImpactService.estimate(
      overallRisk: RiskLevel.high,
      dailyIncome: 500,
      bodyPartRisks: const {
        BodyPart.trunk: RiskLevel.high,
        BodyPart.neck: RiskLevel.medium,
      },
    );

    expect(impact.bodyTreatmentCost, greaterThan(0));
    expect(impact.medicalVisitCost, greaterThan(0));
    expect(impact.travelCost, greaterThan(0));
    expect(impact.lostIncome, greaterThan(0));
    expect(impact.totalCost, greaterThan(impact.directCareCost));
  });
}
