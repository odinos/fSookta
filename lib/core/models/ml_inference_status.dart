import 'evaluation_models.dart';

enum MlInferenceState {
  success,
  unavailable,
  invalidInput,
  runtimeError,
}

class XGBoostInferenceOutcome {
  const XGBoostInferenceOutcome.success(this.alert)
      : state = MlInferenceState.success,
        errorCode = null;

  const XGBoostInferenceOutcome.unavailable([this.errorCode])
      : state = MlInferenceState.unavailable,
        alert = null;

  const XGBoostInferenceOutcome.invalidInput([this.errorCode])
      : state = MlInferenceState.invalidInput,
        alert = null;

  const XGBoostInferenceOutcome.runtimeError([this.errorCode])
      : state = MlInferenceState.runtimeError,
        alert = null;

  final MlInferenceState state;
  final AiRiskAlert? alert;
  final String? errorCode;
}

String xgboostPhotoStatus({
  required XGBoostInferenceOutcome outcome,
  required bool thai,
}) {
  if (outcome.state == MlInferenceState.success) {
    return thai
        ? 'ระบบประเมินคะแนน REBA จากภาพและตรวจเทียบสัญญาณด้วย XGBoost แล้ว'
        : 'REBA scores updated from photos and the XGBoost advisory check completed.';
  }
  return thai
      ? 'ระบบประเมินคะแนน REBA จากภาพแล้ว; XGBoost ไม่พร้อม จึงไม่ถูกนำมาใช้'
      : 'REBA scores updated from photos; XGBoost was unavailable and was not used.';
}
