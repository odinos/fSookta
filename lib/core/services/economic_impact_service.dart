import 'dart:math' as math;

import '../models/economic_impact_models.dart';
import '../models/evaluation_models.dart';

class EconomicImpactService {
  const EconomicImpactService._();

  static const treatmentCostRecords = <CostSurveyRecord>[
    CostSurveyRecord(
      labelTh: 'โรงพยาบาลรัฐ ค่าตรวจ+ค่ายา',
      labelEn: 'Public hospital visit and medicine',
      peopleCount: 18,
      totalCost: 9428.361512,
      averageCost: 523.7978618,
    ),
    CostSurveyRecord(
      labelTh: 'โรงพยาบาลเอกชน ค่าตรวจ+ค่ายา',
      labelEn: 'Private hospital visit and medicine',
      peopleCount: 4,
      totalCost: 8076.345597,
      averageCost: 2019.086399,
    ),
    CostSurveyRecord(
      labelTh: 'คลินิกเอกชน/หมอเอกชน',
      labelEn: 'Private clinic or doctor',
      peopleCount: 12,
      totalCost: 20863.5695,
      averageCost: 1738.630792,
    ),
    CostSurveyRecord(
      labelTh: 'นักกายภาพบำบัด',
      labelEn: 'Physiotherapy',
      peopleCount: 4,
      totalCost: 2841.421356,
      averageCost: 710.3553391,
    ),
    CostSurveyRecord(
      labelTh: 'หมอนวดแผนไทย',
      labelEn: 'Thai traditional massage',
      peopleCount: 60,
      totalCost: 2067.386062,
      averageCost: 34.45643437,
    ),
    CostSurveyRecord(
      labelTh: 'อื่น ๆ',
      labelEn: 'Other care',
      peopleCount: 6,
      totalCost: 4619.071964,
      averageCost: 769.8453274,
    ),
    CostSurveyRecord(
      labelTh: 'รวมค่ายาและเวชภัณฑ์',
      labelEn: 'Medicine and supplies',
      peopleCount: 17,
      totalCost: 45515.53041,
      averageCost: 2677.384142,
    ),
    CostSurveyRecord(
      labelTh: 'รวมค่าเดินทาง',
      labelEn: 'Travel cost',
      peopleCount: 18,
      totalCost: 45211.59516,
      averageCost: 2511.755286,
    ),
    CostSurveyRecord(
      labelTh: 'รวมรายได้ที่สูญเสีย',
      labelEn: 'Lost income',
      peopleCount: 8,
      totalCost: 61453.00069,
      averageCost: 7681.625087,
    ),
    CostSurveyRecord(
      labelTh: 'รายได้ที่ลดลง',
      labelEn: 'Reduced income',
      peopleCount: 7,
      totalCost: 61314.29178,
      averageCost: 8759.184541,
    ),
    CostSurveyRecord(
      labelTh: 'รวมค่าทดแทน',
      labelEn: 'Compensation',
      peopleCount: 6,
      totalCost: 20876.02548,
      averageCost: 3479.33758,
    ),
  ];

  static const bodyAreaCostRecords = <BodyAreaCostRecord>[
    BodyAreaCostRecord(
      labelTh: 'คอ',
      labelEn: 'Neck',
      bodyPart: BodyPart.neck,
      peopleCount: 10,
      totalCost: 5000,
      averageCost: 500,
    ),
    BodyAreaCostRecord(
      labelTh: 'ไหล่',
      labelEn: 'Shoulder',
      bodyPart: BodyPart.arms,
      peopleCount: 15,
      totalCost: 7400,
      averageCost: 493.33,
    ),
    BodyAreaCostRecord(
      labelTh: 'แขนด้านบน',
      labelEn: 'Upper arm',
      bodyPart: BodyPart.arms,
      peopleCount: 8,
      totalCost: 5000,
      averageCost: 625,
    ),
    BodyAreaCostRecord(
      labelTh: 'ข้อศอก',
      labelEn: 'Elbow',
      bodyPart: BodyPart.arms,
      peopleCount: 3,
      totalCost: 0,
      averageCost: 0,
    ),
    BodyAreaCostRecord(
      labelTh: 'แขนด้านล่าง/ข้อมือ',
      labelEn: 'Forearm or wrist',
      bodyPart: BodyPart.wrists,
      peopleCount: 8,
      totalCost: 5000,
      averageCost: 625,
    ),
    BodyAreaCostRecord(
      labelTh: 'หลังด้านบน',
      labelEn: 'Upper back',
      bodyPart: BodyPart.trunk,
      peopleCount: 5,
      totalCost: 2000,
      averageCost: 400,
    ),
    BodyAreaCostRecord(
      labelTh: 'หลังด้านล่าง',
      labelEn: 'Lower back',
      bodyPart: BodyPart.trunk,
      peopleCount: 12,
      totalCost: 5270,
      averageCost: 439.17,
    ),
    BodyAreaCostRecord(
      labelTh: 'สะโพก/ก้น',
      labelEn: 'Hip or buttock',
      bodyPart: BodyPart.legs,
      peopleCount: 7,
      totalCost: 5830,
      averageCost: 832.86,
    ),
    BodyAreaCostRecord(
      labelTh: 'ขาด้านบน',
      labelEn: 'Thigh',
      bodyPart: BodyPart.legs,
      peopleCount: 5,
      totalCost: 4800,
      averageCost: 960,
    ),
    BodyAreaCostRecord(
      labelTh: 'เข่า',
      labelEn: 'Knee',
      bodyPart: BodyPart.legs,
      peopleCount: 7,
      totalCost: 5710,
      averageCost: 815.71,
    ),
  ];

  static EconomicImpactBreakdown estimate({
    required RiskLevel overallRisk,
    required double dailyIncome,
    required Map<BodyPart, RiskLevel> bodyPartRisks,
  }) {
    if (overallRisk == RiskLevel.low) {
      return const EconomicImpactBreakdown(
        bodyTreatmentCost: 0,
        medicalVisitCost: 0,
        medicineAndSuppliesCost: 0,
        travelCost: 0,
        lostIncome: 0,
        reducedIncome: 0,
        compensationCost: 0,
        bodyImpacts: [],
      );
    }

    final bodyImpacts = <BodyPartCostImpact>[];
    for (final entry in bodyPartRisks.entries) {
      if (entry.value == RiskLevel.low) continue;
      final treatmentCost =
          bodyPartAverageCost(entry.key) * _riskMultiplier(entry.value);
      bodyImpacts.add(
        BodyPartCostImpact(
          bodyPart: entry.key,
          riskLevel: entry.value,
          estimatedTreatmentCost: treatmentCost.round(),
        ),
      );
    }

    final overallMultiplier = _riskMultiplier(overallRisk);
    final dailyIncomeBase = dailyIncome > 0 ? dailyIncome : 350.0;
    final lostIncomeFromDays = dailyIncomeBase * _lostWorkDays(overallRisk);
    final observedLostIncome =
        averageTreatmentCost('รวมรายได้ที่สูญเสีย') * overallMultiplier;

    return EconomicImpactBreakdown(
      bodyTreatmentCost: bodyImpacts.fold<int>(
        0,
        (sum, impact) => sum + impact.estimatedTreatmentCost,
      ),
      medicalVisitCost: (averageMedicalVisitCost() * overallMultiplier).round(),
      medicineAndSuppliesCost:
          (averageTreatmentCost('รวมค่ายาและเวชภัณฑ์') * overallMultiplier)
              .round(),
      travelCost:
          (averageTreatmentCost('รวมค่าเดินทาง') * overallMultiplier).round(),
      lostIncome: math.max(lostIncomeFromDays, observedLostIncome).round(),
      reducedIncome:
          (averageTreatmentCost('รายได้ที่ลดลง') * overallMultiplier).round(),
      compensationCost:
          (averageTreatmentCost('รวมค่าทดแทน') * overallMultiplier).round(),
      bodyImpacts: bodyImpacts,
    );
  }

  static double averageTreatmentCost(String labelTh) {
    return treatmentCostRecords
        .firstWhere(
          (record) => record.labelTh == labelTh,
          orElse: () => const CostSurveyRecord(
            labelTh: '',
            labelEn: '',
            peopleCount: 0,
            totalCost: 0,
            averageCost: 0,
          ),
        )
        .averageCost;
  }

  static double averageMedicalVisitCost() {
    const visitLabels = {
      'โรงพยาบาลรัฐ ค่าตรวจ+ค่ายา',
      'โรงพยาบาลเอกชน ค่าตรวจ+ค่ายา',
      'คลินิกเอกชน/หมอเอกชน',
    };
    var people = 0;
    var total = 0.0;
    for (final record in treatmentCostRecords) {
      if (!visitLabels.contains(record.labelTh)) continue;
      people += record.peopleCount;
      total += record.totalCost;
    }
    return people == 0 ? 0 : total / people;
  }

  static double bodyPartAverageCost(BodyPart part) {
    final records =
        bodyAreaCostRecords.where((record) => record.bodyPart == part);
    var people = 0;
    var total = 0.0;
    for (final record in records) {
      people += record.peopleCount;
      total += record.totalCost;
    }
    return people == 0 ? 0 : total / people;
  }

  static int estimatedLostWorkDays(RiskLevel risk) {
    return _lostWorkDays(risk).round();
  }

  static double _riskMultiplier(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 0,
      RiskLevel.medium => 0.35,
      RiskLevel.high => 0.75,
      RiskLevel.veryHigh => 1,
    };
  }

  static double _lostWorkDays(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 0,
      RiskLevel.medium => 2,
      RiskLevel.high => 7,
      RiskLevel.veryHigh => 30,
    };
  }
}
