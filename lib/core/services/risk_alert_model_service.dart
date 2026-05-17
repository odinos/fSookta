import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/evaluation_models.dart';

class RiskAlertModelService {
  RiskAlertModelService._(this._model);

  static RiskAlertModelService? _instance;
  static Future<RiskAlertModelService> load({
    String assetPath = 'assets/ml/risk_alert_models.json',
  }) async {
    final existing = _instance;
    if (existing != null) return existing;

    final jsonText = await rootBundle.loadString(assetPath);
    final model = _RiskAlertModel.fromJson(
      jsonDecode(jsonText) as Map<String, Object?>,
    );
    return _instance = RiskAlertModelService._(model);
  }

  @visibleForTesting
  factory RiskAlertModelService.fromJson(Map<String, Object?> json) {
    return RiskAlertModelService._(_RiskAlertModel.fromJson(json));
  }

  final _RiskAlertModel _model;

  AiRiskAlert predict({
    required JobType jobType,
    required ErgoResult result,
    required ErgoInputData ergoInput,
    required RebaInputData rebaInput,
  }) {
    final features = _features(
      jobType: jobType,
      result: result,
      ergoInput: ergoInput,
      rebaInput: rebaInput,
    );
    final logisticScore = _model.logistic.intercept +
        _model.logistic.coefficients.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value * (features[entry.key] ?? 0),
        );
    final logisticProbability = _sigmoid(logisticScore);
    final treeResult = _model.xgBoost.predict(features);
    final xgBoostProbability = _sigmoid(treeResult.margin);
    final probability = ((logisticProbability + xgBoostProbability) / 2)
        .clamp(0.0, 1.0)
        .toDouble();
    final importance = _importance(features, treeResult.usedFeatures);

    return AiRiskAlert(
      probability: probability,
      logisticProbability: logisticProbability,
      xgBoostProbability: xgBoostProbability,
      level: _model.thresholds.levelFor(probability),
      modelVersion: _model.version,
      modelSource: _model.source,
      featureImportance: importance,
    );
  }

  Map<String, double> _features({
    required JobType jobType,
    required ErgoResult result,
    required ErgoInputData ergoInput,
    required RebaInputData rebaInput,
  }) {
    final highestBodyRisk = result.bodyPartRisks.values.fold<RiskLevel>(
      RiskLevel.low,
      (highest, risk) => risk.index > highest.index ? risk : highest,
    );
    final forceRatio = math.max(
      ergoInput.initialForce /
          (ergoInput.gender.toLowerCase() == 'female' ? 20 : 25),
      ergoInput.sustainForce /
          (ergoInput.gender.toLowerCase() == 'female' ? 12 : 15),
    );
    final technicalScoreNorm = switch (jobType) {
      JobType.reba => result.techScore / 12,
      JobType.lifting => result.techScore / 5,
      JobType.pushPull => result.techScore / 2,
    };

    return {
      'job_type_reba': jobType == JobType.reba ? 1 : 0,
      'job_type_lifting': jobType == JobType.lifting ? 1 : 0,
      'job_type_push_pull': jobType == JobType.pushPull ? 1 : 0,
      'user_score_norm': _norm(result.userScore.toDouble(), 1, 9),
      'technical_score_norm': _bounded(technicalScoreNorm),
      'economic_loss_norm': _bounded(result.economicLoss / 20000),
      'body_risk_max_norm':
          highestBodyRisk.index / (RiskLevel.values.length - 1),
      'duration_norm': _bounded(ergoInput.durationHours / 8),
      'frequency_norm': _bounded(ergoInput.liftFrequency / 6.5),
      'load_weight_norm': _bounded(ergoInput.loadWeight / 25),
      'horizontal_distance_norm': _bounded(ergoInput.horizontalDist / 65),
      'vertical_deviation_norm':
          _bounded((ergoInput.verticalHeight - 75).abs() / 100),
      'transport_distance_norm': _bounded(ergoInput.transportDistance / 20),
      'force_ratio_norm': _bounded(forceRatio / 2),
      'reba_trunk_norm': _norm(rebaInput.trunkScore.toDouble(), 1, 4),
      'reba_neck_norm': _norm(rebaInput.neckScore.toDouble(), 1, 2),
      'reba_leg_norm': _norm(rebaInput.legScore.toDouble(), 1, 2),
      'reba_upper_arm_norm': _norm(rebaInput.upperArmScore.toDouble(), 1, 4),
      'reba_wrist_norm': _norm(rebaInput.wristScore.toDouble(), 1, 2),
      'reba_load_norm': _norm(rebaInput.loadScore.toDouble(), 0, 2),
    };
  }

  List<AiFeatureImportance> _importance(
    Map<String, double> features,
    Map<String, double> treeUsage,
  ) {
    final scores = <String, double>{};
    for (final entry in _model.logistic.coefficients.entries) {
      final value = features[entry.key] ?? 0;
      scores[entry.key] =
          (scores[entry.key] ?? 0) + (entry.value * value).abs();
    }
    for (final entry in treeUsage.entries) {
      scores[entry.key] = (scores[entry.key] ?? 0) + entry.value.abs();
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .where((entry) => entry.value > 0)
        .take(5)
        .map(
          (entry) => AiFeatureImportance(
            key: entry.key,
            labelTh: _model.featureLabels[entry.key]?.th ?? entry.key,
            labelEn: _model.featureLabels[entry.key]?.en ?? entry.key,
            score: entry.value,
          ),
        )
        .toList();
  }

  double _norm(double value, double min, double max) {
    if (max <= min) return 0;
    return _bounded((value - min) / (max - min));
  }

  double _bounded(double value) => value.clamp(0.0, 1.0).toDouble();

  double _sigmoid(double value) => 1 / (1 + math.exp(-value));
}

class _RiskAlertModel {
  const _RiskAlertModel({
    required this.version,
    required this.source,
    required this.thresholds,
    required this.featureLabels,
    required this.logistic,
    required this.xgBoost,
  });

  final String version;
  final String source;
  final _Thresholds thresholds;
  final Map<String, _FeatureLabel> featureLabels;
  final _LogisticRegression logistic;
  final _XgBoostModel xgBoost;

  factory _RiskAlertModel.fromJson(Map<String, Object?> json) {
    final labels = (json['featureLabels'] as Map? ?? {}).map(
      (key, value) => MapEntry(
        key.toString(),
        _FeatureLabel.fromJson(Map<String, Object?>.from(value as Map)),
      ),
    );
    return _RiskAlertModel(
      version: json['version'] as String? ?? 'unknown',
      source: json['source'] as String? ?? 'unknown',
      thresholds: _Thresholds.fromJson(
        Map<String, Object?>.from(json['thresholds'] as Map? ?? {}),
      ),
      featureLabels: labels,
      logistic: _LogisticRegression.fromJson(
        Map<String, Object?>.from(json['logisticRegression'] as Map? ?? {}),
      ),
      xgBoost: _XgBoostModel.fromJson(
        Map<String, Object?>.from(json['xgboost'] as Map? ?? {}),
      ),
    );
  }
}

class _FeatureLabel {
  const _FeatureLabel({required this.th, required this.en});

  final String th;
  final String en;

  factory _FeatureLabel.fromJson(Map<String, Object?> json) {
    return _FeatureLabel(
      th: json['th'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }
}

class _Thresholds {
  const _Thresholds({
    required this.watch,
    required this.high,
    required this.critical,
  });

  final double watch;
  final double high;
  final double critical;

  factory _Thresholds.fromJson(Map<String, Object?> json) {
    return _Thresholds(
      watch: (json['watch'] as num?)?.toDouble() ?? 0.45,
      high: (json['high'] as num?)?.toDouble() ?? 0.65,
      critical: (json['critical'] as num?)?.toDouble() ?? 0.82,
    );
  }

  AiAlertLevel levelFor(double probability) {
    if (probability >= critical) return AiAlertLevel.critical;
    if (probability >= high) return AiAlertLevel.high;
    if (probability >= watch) return AiAlertLevel.watch;
    return AiAlertLevel.low;
  }
}

class _LogisticRegression {
  const _LogisticRegression({
    required this.intercept,
    required this.coefficients,
  });

  final double intercept;
  final Map<String, double> coefficients;

  factory _LogisticRegression.fromJson(Map<String, Object?> json) {
    return _LogisticRegression(
      intercept: (json['intercept'] as num?)?.toDouble() ?? 0,
      coefficients: (json['coefficients'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
  }
}

class _XgBoostModel {
  const _XgBoostModel({
    required this.baseMargin,
    required this.learningRate,
    required this.trees,
  });

  final double baseMargin;
  final double learningRate;
  final List<_TreeNode> trees;

  factory _XgBoostModel.fromJson(Map<String, Object?> json) {
    return _XgBoostModel(
      baseMargin: (json['baseMargin'] as num?)?.toDouble() ?? 0,
      learningRate: (json['learningRate'] as num?)?.toDouble() ?? 1,
      trees: (json['trees'] as List? ?? [])
          .whereType<Map>()
          .map((tree) => _TreeNode.fromJson(Map<String, Object?>.from(tree)))
          .toList(),
    );
  }

  _TreePrediction predict(Map<String, double> features) {
    var margin = baseMargin;
    final used = <String, double>{};
    for (final tree in trees) {
      final result = tree.evaluate(features);
      margin += learningRate * result.leaf;
      for (final feature in result.usedFeatures) {
        used[feature] = (used[feature] ?? 0) + 1;
      }
    }
    return _TreePrediction(margin: margin, usedFeatures: used);
  }
}

class _TreeNode {
  const _TreeNode.branch({
    required this.split,
    required this.threshold,
    required this.yes,
    required this.no,
  }) : leaf = null;

  const _TreeNode.leaf(this.leaf)
      : split = null,
        threshold = null,
        yes = null,
        no = null;

  final String? split;
  final double? threshold;
  final _TreeNode? yes;
  final _TreeNode? no;
  final double? leaf;

  factory _TreeNode.fromJson(Map<String, Object?> json) {
    final leaf = json['leaf'];
    if (leaf is num) return _TreeNode.leaf(leaf.toDouble());

    return _TreeNode.branch(
      split: json['split'] as String? ?? '',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      yes: _TreeNode.fromJson(Map<String, Object?>.from(json['yes'] as Map)),
      no: _TreeNode.fromJson(Map<String, Object?>.from(json['no'] as Map)),
    );
  }

  _NodePrediction evaluate(Map<String, double> features) {
    final leafValue = leaf;
    if (leafValue != null) {
      return _NodePrediction(leaf: leafValue, usedFeatures: const []);
    }

    final feature = split ?? '';
    final value = features[feature] ?? 0;
    final next = value < (threshold ?? 0) ? yes : no;
    final result = next?.evaluate(features) ??
        const _NodePrediction(leaf: 0, usedFeatures: []);
    return _NodePrediction(
      leaf: result.leaf,
      usedFeatures: [feature, ...result.usedFeatures],
    );
  }
}

class _NodePrediction {
  const _NodePrediction({required this.leaf, required this.usedFeatures});

  final double leaf;
  final List<String> usedFeatures;
}

class _TreePrediction {
  const _TreePrediction({required this.margin, required this.usedFeatures});

  final double margin;
  final Map<String, double> usedFeatures;
}
