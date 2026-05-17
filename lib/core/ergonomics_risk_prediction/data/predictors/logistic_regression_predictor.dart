import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';

import '../../domain/entities/risk_assessment_result.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';
import '../../domain/predictors/ergonomic_risk_predictor.dart';
import '../models/logistic_regression_weights.dart';

class LogisticRegressionPredictor implements ErgonomicRiskPredictor {
  LogisticRegressionPredictor({
    this.assetPath = 'assets/models/logistic_weights.json',
  });

  @visibleForTesting
  LogisticRegressionPredictor.fromWeights(LogisticRegressionWeights weights)
      : assetPath = '',
        _weights = weights;

  final String assetPath;
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
      _buildInferenceFrame(features);

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
    if (jointFeatures.length != weights.featureCount) {
      throw InvalidJointFeaturesException(
        'Expected ${weights.featureCount} joint features but got ${jointFeatures.length}.',
      );
    }

    // MoveNet usually returns normalized x/y coordinates plus confidence scores.
    // Before inference we copy the vector, verify every value is finite, and
    // apply the same standardization stats used during training when they are
    // shipped in JSON. Without mean/std, the features are treated as already
    // normalized or feature-engineered by the upstream pose pipeline.
    final sanitized = <double>[];
    for (final value in jointFeatures) {
      if (!value.isFinite) {
        throw const InvalidJointFeaturesException(
          'Joint features must contain finite numeric values only.',
        );
      }
      sanitized.add(value);
    }

    if (!weights.hasStandardization) return sanitized;

    return List<double>.generate(sanitized.length, (index) {
      final std = weights.standardDeviation[index];
      if (std == 0) return 0;
      return (sanitized[index] - weights.mean[index]) / std;
    }, growable: false);
  }

  DataFrame _buildInferenceFrame(List<double> features) {
    final header = List<String>.generate(
      features.length,
      (index) => 'joint_feature_$index',
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
