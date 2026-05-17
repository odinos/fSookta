import '../entities/risk_assessment_result.dart';
import '../predictors/ergonomic_risk_predictor.dart';

class AssessRiskUseCase {
  AssessRiskUseCase(this._predictor);

  final ErgonomicRiskPredictor _predictor;
  bool _isInitialized = false;

  Future<RiskAssessmentResult> call(List<double> jointFeatures) async {
    if (!_isInitialized) {
      await _predictor.initModel();
      _isInitialized = true;
    }
    return _predictor.predictRiskLevel(jointFeatures);
  }

  Future<RiskAssessmentResult> execute(List<double> jointFeatures) {
    return call(jointFeatures);
  }
}
