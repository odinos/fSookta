class JointFeatureSchema {
  const JointFeatureSchema({
    required this.schemaId,
    required this.version,
    required this.featureCount,
    required this.landmarks,
    required this.components,
    this.missingValue = 0,
  });

  final String schemaId;
  final String version;
  final int featureCount;
  final List<String> landmarks;
  final List<String> components;
  final double missingValue;

  List<String> get featureNames {
    return [
      for (final landmark in landmarks)
        for (final component in components) '${landmark}_$component',
    ];
  }

  factory JointFeatureSchema.fromJson(Map<String, Object?> json) {
    final landmarks =
        (json['landmarks'] as List? ?? []).whereType<String>().toList();
    final components =
        (json['components'] as List? ?? []).whereType<String>().toList();
    final featureCount = (json['featureCount'] as num?)?.toInt() ??
        landmarks.length * components.length;

    return JointFeatureSchema(
      schemaId: json['schemaId'] as String? ?? 'unknown',
      version: json['version'] as String? ?? 'unknown',
      featureCount: featureCount,
      landmarks: landmarks,
      components: components,
      missingValue: (json['missingValue'] as num?)?.toDouble() ?? 0,
    );
  }

  void validate() {
    if (schemaId.isEmpty || schemaId == 'unknown') {
      throw StateError('Feature schemaId must be defined.');
    }
    if (landmarks.isEmpty || components.isEmpty) {
      throw StateError('Feature schema landmarks/components must be defined.');
    }
    if (featureCount != landmarks.length * components.length) {
      throw StateError(
        'Feature schema count $featureCount does not match ${landmarks.length} landmarks x ${components.length} components.',
      );
    }
  }
}
