import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';

import '../../domain/entities/risk_assessment_result.dart';
import '../../domain/entities/joint_feature_schema.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';
import '../../domain/predictors/ergonomic_risk_predictor.dart';
import '../models/logistic_regression_weights.dart';

class LogisticRegressionPredictor implements ErgonomicRiskPredictor {
  LogisticRegressionPredictor({
    this.assetPath = 'assets/models/logistic_weights.json',
    this.featureSchema,
  });

  @visibleForTesting
  LogisticRegressionPredictor.fromWeights(LogisticRegressionWeights weights)
      : assetPath = '',
        featureSchema = null,
        _weights = weights;

  final String assetPath;
  final JointFeatureSchema? featureSchema;
  LogisticRegressionWeights? _weights;
  LogisticRegressor? _serializedMlAlgoModel;

  bool get usesSerializedMlAlgoModel => _serializedMlAlgoModel != null;

  @override
  Future<void> initModel() async {
    if (_weights != null) return;

    try {
      final jsonText = await rootBundle.loadString(assetPath);
      final json = Map<String, Object?>.from(jsonDecode(jsonText) as Map);
      _weights = LogisticRegressionWeights.fromJson(json);
      _validateFeatureSchema(_weights!);

      final mlAlgoModelJson = json['mlAlgoModelJson'];
      if (mlAlgoModelJson is String && mlAlgoModelJson.isNotEmpty) {
        _serializedMlAlgoModel = LogisticRegressor.fromJson(mlAlgoModelJson);
      }
    } catch (error, stackTrace) {
      throw ModelLoadException(
        'Failed to load Logistic Regression model from $assetPath.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _validateFeatureSchema(LogisticRegressionWeights weights) {
    final schema = featureSchema;
    if (schema == null) return;
    if (weights.featureSchemaId != schema.schemaId) {
      throw ModelLoadException(
        'Logistic model schema ${weights.featureSchemaId} does not match loaded feature schema ${schema.schemaId}.',
      );
    }
    if (weights.expectedInputFeatureCount != schema.featureCount) {
      throw ModelLoadException(
        'Logistic model expects ${weights.expectedInputFeatureCount} input features but schema has ${schema.featureCount}.',
      );
    }
  }

  @override
  Future<RiskAssessmentResult> predictRiskLevel(
    List<double> jointFeatures,
  ) async {
    final weights = _weights;
    if (weights == null) {
      throw const ModelLoadException(
        'Logistic Regression model is not initialized. Call initModel() first.',
      );
    }

    try {
      final features = _preprocessJointFeatures(jointFeatures, weights);
      _buildInferenceFrame(features, weights);

      var logit = weights.intercept;
      for (var i = 0; i < features.length; i++) {
        logit += features[i] * weights.weights[i];
      }

      final probability = 1 / (1 + math.exp(-logit));
      return RiskAssessmentResult.fromProbability(
        probability,
        thresholds: weights.thresholds,
      );
    } on RiskPredictionException {
      rethrow;
    } catch (error, stackTrace) {
      throw ModelInferenceException(
        'Logistic Regression inference failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<double> _preprocessJointFeatures(
    List<double> jointFeatures,
    LogisticRegressionWeights weights,
  ) {
    if (jointFeatures.length != weights.expectedInputFeatureCount) {
      throw InvalidJointFeaturesException(
        'Expected ${weights.expectedInputFeatureCount} joint features but got ${jointFeatures.length}.',
      );
    }

    // MoveNet usually returns normalized x/y coordinates plus confidence scores.
    // Before inference we copy the vector, verify every value is finite, and
    // derive the same REBA angle features that the training script appended.
    // This keeps app input simple for MoveNet while allowing the model to learn
    // trunk, neck, arm, and leg geometry instead of only raw x/y coordinates.
    final sanitizedInput = <double>[];
    for (final value in jointFeatures) {
      if (!value.isFinite) {
        throw const InvalidJointFeaturesException(
          'Joint features must contain finite numeric values only.',
        );
      }
      sanitizedInput.add(value);
    }

    final expanded = weights.usesRebaAngleFeatures
        ? <double>[
            ...sanitizedInput,
            ..._RebaAngleFeatureEngineering.extract(sanitizedInput),
          ]
        : sanitizedInput;

    if (expanded.length != weights.featureCount) {
      throw InvalidJointFeaturesException(
        'Model feature expansion produced ${expanded.length} features but expected ${weights.featureCount}.',
      );
    }

    if (!weights.hasStandardization) return expanded;

    return List<double>.generate(expanded.length, (index) {
      final std = weights.standardDeviation[index];
      if (std == 0) return 0;
      return (expanded[index] - weights.mean[index]) / std;
    }, growable: false);
  }

  DataFrame _buildInferenceFrame(
    List<double> features,
    LogisticRegressionWeights weights,
  ) {
    final schemaFeatureNames = featureSchema?.featureNames ?? const <String>[];
    final header = List<String>.generate(
      features.length,
      (index) {
        if (index < weights.featureNames.length) {
          return weights.featureNames[index];
        }
        if (index < schemaFeatureNames.length) {
          return schemaFeatureNames[index];
        }
        return 'model_feature_$index';
      },
      growable: false,
    );
    final frame = DataFrame([header, features]);
    if (frame.header.length != features.length) {
      throw const ModelInferenceException(
        'Failed to build ml_dataframe feature frame.',
      );
    }
    return frame;
  }
}

class _RebaAngleFeatureEngineering {
  static const double _minScore = 0.3;

  static List<double> extract(List<double> features) {
    final leftShoulder = _point(features, 15);
    final rightShoulder = _point(features, 18);
    final leftElbow = _point(features, 21);
    final rightElbow = _point(features, 24);
    final leftWrist = _point(features, 27);
    final rightWrist = _point(features, 30);
    final leftHip = _point(features, 33);
    final rightHip = _point(features, 36);
    final leftKnee = _point(features, 39);
    final rightKnee = _point(features, 42);
    final leftAnkle = _point(features, 45);
    final rightAnkle = _point(features, 48);
    final shoulders = _midpoint([leftShoulder, rightShoulder]);
    final hips = _midpoint([leftHip, rightHip]);
    final head = _midpoint([
      _point(features, 0),
      _point(features, 9),
      _point(features, 12),
    ]);

    final trunkAngle = _verticalAngleOrZero(hips, shoulders);
    final neckAngle = _verticalAngleOrZero(shoulders, head);
    final leftUpperArmAngle = _verticalAngleOrZero(leftShoulder, leftElbow);
    final rightUpperArmAngle = _verticalAngleOrZero(rightShoulder, rightElbow);
    final worstUpperArmAngle = math.max(leftUpperArmAngle, rightUpperArmAngle);
    final leftElbowAngle = _threePointAngleOrZero(
      leftShoulder,
      leftElbow,
      leftWrist,
    );
    final rightElbowAngle = _threePointAngleOrZero(
      rightShoulder,
      rightElbow,
      rightWrist,
    );
    final worstLowerArmDeviation = math.max(
      _lowerArmDeviation(leftElbowAngle),
      _lowerArmDeviation(rightElbowAngle),
    );
    final leftKneeAngle = _threePointAngleOrZero(
      leftHip,
      leftKnee,
      leftAnkle,
    );
    final rightKneeAngle = _threePointAngleOrZero(
      rightHip,
      rightKnee,
      rightAnkle,
    );
    final leftKneeReference = leftKneeAngle == 0 ? 180.0 : leftKneeAngle;
    final rightKneeReference = rightKneeAngle == 0 ? 180.0 : rightKneeAngle;
    final worstKneeFlexion = math
        .max(
          0,
          180 - math.min(leftKneeReference, rightKneeReference),
        )
        .toDouble();
    final shoulderSlope = leftShoulder != null && rightShoulder != null
        ? _horizontalAngle(leftShoulder, rightShoulder)
        : 0.0;
    final hipSlope = leftHip != null && rightHip != null
        ? _horizontalAngle(leftHip, rightHip)
        : 0.0;
    final shoulderWidth = leftShoulder != null && rightShoulder != null
        ? _distance(leftShoulder, rightShoulder)
        : 0.0;
    final hipWidth = leftHip != null && rightHip != null
        ? _distance(leftHip, rightHip)
        : 0.0;
    final upperBodyLean =
        shoulders != null && hips != null ? (shoulders.x - hips.x).abs() : 0.0;

    final scores = <double>[
      for (var index = 2; index < 51; index += 3) features[index],
    ];
    final upperScores = [2, 11, 14, 17, 20, 23, 26, 29, 32]
        .map((index) => features[index])
        .toList(growable: false);
    final lowerScores = [35, 38, 41, 44, 47, 50]
        .map((index) => features[index])
        .toList(growable: false);

    return [
      trunkAngle,
      neckAngle,
      leftUpperArmAngle,
      rightUpperArmAngle,
      worstUpperArmAngle,
      leftElbowAngle,
      rightElbowAngle,
      worstLowerArmDeviation,
      leftKneeAngle,
      rightKneeAngle,
      worstKneeFlexion,
      shoulderSlope,
      hipSlope,
      shoulderWidth,
      hipWidth,
      upperBodyLean,
      _visibleRatio(scores),
      scores.reduce((a, b) => a + b) / scores.length,
      _visibleRatio(lowerScores),
      _visibleRatio(upperScores),
    ];
  }

  static _PosePoint? _point(List<double> features, int offset) {
    final score = features[offset + 2];
    if (score < _minScore) return null;
    return _PosePoint(features[offset], features[offset + 1]);
  }

  static _PosePoint? _midpoint(List<_PosePoint?> points) {
    final visible = points.whereType<_PosePoint>().toList(growable: false);
    if (visible.isEmpty) return null;
    final x = visible.map((point) => point.x).reduce((a, b) => a + b);
    final y = visible.map((point) => point.y).reduce((a, b) => a + b);
    return _PosePoint(x / visible.length, y / visible.length);
  }

  static double _verticalAngleOrZero(_PosePoint? p1, _PosePoint? p2) {
    if (p1 == null || p2 == null) return 0;
    final dx = (p2.x - p1.x).abs();
    final dy = (p1.y - p2.y).abs();
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  static double _horizontalAngle(_PosePoint p1, _PosePoint p2) {
    final dx = (p2.x - p1.x).abs();
    final dy = (p2.y - p1.y).abs();
    return math.atan2(dy, dx) * 180 / math.pi;
  }

  static double _threePointAngleOrZero(
    _PosePoint? p1,
    _PosePoint? p2,
    _PosePoint? p3,
  ) {
    if (p1 == null || p2 == null || p3 == null) return 0;
    final a1 = math.atan2(p1.y - p2.y, p1.x - p2.x);
    final a2 = math.atan2(p3.y - p2.y, p3.x - p2.x);
    var angle = (a1 - a2) * 180 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  static double _lowerArmDeviation(double angle) {
    if (angle <= 0) return 0;
    if (angle >= 60 && angle <= 100) return 0;
    if (angle < 60) return 60 - angle;
    return angle - 100;
  }

  static double _distance(_PosePoint p1, _PosePoint p2) {
    return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2));
  }

  static double _visibleRatio(List<double> scores) {
    return scores.where((score) => score >= _minScore).length / scores.length;
  }
}

class _PosePoint {
  const _PosePoint(this.x, this.y);

  final double x;
  final double y;
}
