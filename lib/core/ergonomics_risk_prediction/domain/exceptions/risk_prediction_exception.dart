class RiskPredictionException implements Exception {
  const RiskPredictionException(
    this.message, {
    this.cause,
    this.stackTrace,
  });

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final causeText = cause == null ? '' : ' Cause: $cause';
    return 'RiskPredictionException: $message$causeText';
  }
}

class ModelLoadException extends RiskPredictionException {
  const ModelLoadException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class InvalidJointFeaturesException extends RiskPredictionException {
  const InvalidJointFeaturesException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

class ModelInferenceException extends RiskPredictionException {
  const ModelInferenceException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}
