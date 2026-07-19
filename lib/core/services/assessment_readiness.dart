class AssessmentReadiness {
  const AssessmentReadiness({
    required this.hasMedia,
    required this.hasImageQualityIssues,
    required this.poseAssessmentReady,
    required this.poseBusy,
    required this.requiredDataIssues,
  });

  final bool hasMedia;
  final bool hasImageQualityIssues;
  final bool poseAssessmentReady;
  final bool poseBusy;
  final List<String> requiredDataIssues;

  bool get canAnalyze =>
      hasMedia &&
      !hasImageQualityIssues &&
      poseAssessmentReady &&
      !poseBusy &&
      requiredDataIssues.isEmpty;

  AssessmentReadiness copyWith({
    bool? hasMedia,
    bool? hasImageQualityIssues,
    bool? poseAssessmentReady,
    bool? poseBusy,
    List<String>? requiredDataIssues,
  }) {
    return AssessmentReadiness(
      hasMedia: hasMedia ?? this.hasMedia,
      hasImageQualityIssues:
          hasImageQualityIssues ?? this.hasImageQualityIssues,
      poseAssessmentReady: poseAssessmentReady ?? this.poseAssessmentReady,
      poseBusy: poseBusy ?? this.poseBusy,
      requiredDataIssues: requiredDataIssues ?? this.requiredDataIssues,
    );
  }
}
