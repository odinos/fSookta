import '../models/evaluation_models.dart';

ErgoResult attachAdvisoryXGBoostAlert(
  ErgoResult deterministic,
  AiRiskAlert alert,
) {
  return deterministic.copyWith(aiRiskAlert: alert);
}
