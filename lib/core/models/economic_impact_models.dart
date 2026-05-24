import 'evaluation_models.dart';

class CostSurveyRecord {
  const CostSurveyRecord({
    required this.labelTh,
    required this.labelEn,
    required this.peopleCount,
    required this.totalCost,
    required this.averageCost,
  });

  final String labelTh;
  final String labelEn;
  final int peopleCount;
  final double totalCost;
  final double averageCost;

  String label({required bool thai}) => thai ? labelTh : labelEn;
}

class BodyAreaCostRecord {
  const BodyAreaCostRecord({
    required this.labelTh,
    required this.labelEn,
    required this.bodyPart,
    required this.peopleCount,
    required this.totalCost,
    required this.averageCost,
  });

  final String labelTh;
  final String labelEn;
  final BodyPart bodyPart;
  final int peopleCount;
  final double totalCost;
  final double averageCost;

  String label({required bool thai}) => thai ? labelTh : labelEn;
}

class BodyPartCostImpact {
  const BodyPartCostImpact({
    required this.bodyPart,
    required this.riskLevel,
    required this.estimatedTreatmentCost,
  });

  final BodyPart bodyPart;
  final RiskLevel riskLevel;
  final int estimatedTreatmentCost;
}

class EconomicImpactBreakdown {
  const EconomicImpactBreakdown({
    required this.bodyTreatmentCost,
    required this.medicalVisitCost,
    required this.medicineAndSuppliesCost,
    required this.travelCost,
    required this.lostIncome,
    required this.reducedIncome,
    required this.compensationCost,
    required this.bodyImpacts,
  });

  final int bodyTreatmentCost;
  final int medicalVisitCost;
  final int medicineAndSuppliesCost;
  final int travelCost;
  final int lostIncome;
  final int reducedIncome;
  final int compensationCost;
  final List<BodyPartCostImpact> bodyImpacts;

  int get totalCost =>
      bodyTreatmentCost +
      medicalVisitCost +
      medicineAndSuppliesCost +
      travelCost +
      lostIncome +
      reducedIncome;

  int get directCareCost =>
      bodyTreatmentCost +
      medicalVisitCost +
      medicineAndSuppliesCost +
      travelCost;
}
