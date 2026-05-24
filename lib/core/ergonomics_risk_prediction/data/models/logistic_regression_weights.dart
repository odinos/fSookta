import '../../domain/entities/risk_assessment_result.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';

class LogisticRegressionWeights {
  const LogisticRegressionWeights({
    required this.version,
    required this.featureSchemaId,
    required this.modelSource,
    required this.intercept,
    required this.weights,
    required this.thresholds,
    this.inputFeatureCount,
    this.featureEngineering,
    this.featureNames = const [],
    this.engineeredFeatureNames = const [],
    this.mean = const [],
    this.standardDeviation = const [],
  });

  final String version;
  final String featureSchemaId;
  final String modelSource;
  final double intercept;
  final List<double> weights;
  final RiskThresholds thresholds;
  final int? inputFeatureCount;
  final String? featureEngineering;
  final List<String> featureNames;
  final List<String> engineeredFeatureNames;
  final List<double> mean;
  final List<double> standardDeviation;

  int get featureCount => weights.length;
  int get expectedInputFeatureCount => inputFeatureCount ?? featureCount;
  bool get usesRebaAngleFeatures =>
      featureEngineering == 'reba_angle_features_v1';

  bool get hasStandardization =>
      mean.length == weights.length &&
      standardDeviation.length == weights.length;

  factory LogisticRegressionWeights.fromJson(Map<String, Object?> json) {
    final weights = _numbers(json['weights'], fieldName: 'weights');
    if (weights.isEmpty) {
      throw const ModelLoadException('Logistic weights must not be empty.');
    }

    final featureCount = (json['featureCount'] as num?)?.toInt();
    if (featureCount != null && featureCount != weights.length) {
      throw ModelLoadException(
        'featureCount $featureCount does not match weights length ${weights.length}.',
      );
    }

    final thresholds = json['thresholds'] is Map
        ? Map<String, Object?>.from(json['thresholds'] as Map)
        : const <String, Object?>{};

    return LogisticRegressionWeights(
      version: json['version'] as String? ?? 'unknown',
      featureSchemaId: json['featureSchemaId'] as String? ?? 'unknown',
      modelSource: json['modelSource'] as String? ?? 'unknown',
      intercept: (json['intercept'] as num?)?.toDouble() ??
          (json['bias'] as num?)?.toDouble() ??
          0,
      weights: weights,
      thresholds: RiskThresholds(
        medium: (thresholds['medium'] as num?)?.toDouble() ?? 0.35,
        high: (thresholds['high'] as num?)?.toDouble() ?? 0.6,
        veryHigh: (thresholds['veryHigh'] as num?)?.toDouble() ?? 0.82,
      ),
      inputFeatureCount: (json['inputFeatureCount'] as num?)?.toInt(),
      featureEngineering: json['featureEngineering'] as String?,
      featureNames: _strings(json['featureNames']),
      engineeredFeatureNames: _strings(json['engineeredFeatureNames']),
      mean: _numbers(json['mean'], fieldName: 'mean', allowEmpty: true),
      standardDeviation: _numbers(
        json['standardDeviation'] ?? json['std'],
        fieldName: 'standardDeviation',
        allowEmpty: true,
      ),
    );
  }

  static List<double> _numbers(
    Object? raw, {
    required String fieldName,
    bool allowEmpty = false,
  }) {
    if (raw == null && allowEmpty) return const [];
    if (raw is! List) {
      throw ModelLoadException('$fieldName must be a numeric array.');
    }
    return raw.map((value) {
      if (value is! num) {
        throw ModelLoadException('$fieldName contains a non-numeric value.');
      }
      return value.toDouble();
    }).toList(growable: false);
  }

  static List<String> _strings(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List) {
      throw const ModelLoadException('String field must be an array.');
    }
    return raw.map((value) {
      if (value is! String) {
        throw const ModelLoadException(
            'String array contains a non-string value.');
      }
      return value;
    }).toList(growable: false);
  }
}
