class UatConfig {
  const UatConfig._();

  static const assessmentBypassEnabled = bool.fromEnvironment(
    'SOOKTA_UAT_BYPASS',
  );

  static bool canBypassAssessment({
    required bool enabled,
    required bool hasMedia,
    required bool poseBusy,
  }) {
    return enabled && hasMedia && !poseBusy;
  }
}
