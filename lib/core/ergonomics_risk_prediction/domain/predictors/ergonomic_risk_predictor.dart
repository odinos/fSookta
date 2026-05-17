import '../entities/risk_assessment_result.dart';

abstract class ErgonomicRiskPredictor {
  Future<void> initModel();

  Future<RiskAssessmentResult> predictRiskLevel(List<double> jointFeatures);
}
