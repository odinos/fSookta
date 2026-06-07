import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../models/evaluation_models.dart';

enum DailyInjuryPredictionLevel {
  insufficient,
  low,
  watch,
  high,
  critical,
}

class DailyInjuryPrediction {
  const DailyInjuryPrediction({
    required this.hasEnoughData,
    required this.requiredTransactions,
    required this.usedTransactions,
    required this.probability,
    required this.level,
    required this.modelVersion,
    required this.modelSource,
    required this.featureValues,
    required this.chartScores,
    this.windowStart,
    this.windowEnd,
  });

  final bool hasEnoughData;
  final int requiredTransactions;
  final int usedTransactions;
  final double probability;
  final DailyInjuryPredictionLevel level;
  final String modelVersion;
  final String modelSource;
  final Map<String, double> featureValues;
  final List<int> chartScores;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  bool get requiresCareAlert =>
      level == DailyInjuryPredictionLevel.high ||
      level == DailyInjuryPredictionLevel.critical;
}

class DailyInjuryPredictionService {
  DailyInjuryPredictionService._(this._model);

  static DailyInjuryPredictionService? _instance;

  static Future<DailyInjuryPredictionService> load({
    String assetPath = 'assets/ml/daily_injury_logistic_model.json',
  }) async {
    final existing = _instance;
    if (existing != null) return existing;

    final jsonText = await rootBundle.loadString(assetPath);
    final model = _DailyInjuryLogisticModel.fromJson(
      jsonDecode(jsonText) as Map<String, Object?>,
    );
    return _instance = DailyInjuryPredictionService._(model);
  }

  factory DailyInjuryPredictionService.fromJson(Map<String, Object?> json) {
    return DailyInjuryPredictionService._(
      _DailyInjuryLogisticModel.fromJson(json),
    );
  }

  final _DailyInjuryLogisticModel _model;

  DailyInjuryPrediction predictForRecords(
    List<EvaluationHistoryRecord> records,
  ) {
    final sorted = records.toList(growable: false)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final requiredTransactions = _model.minTransactions;
    if (sorted.length < requiredTransactions) {
      return DailyInjuryPrediction(
        hasEnoughData: false,
        requiredTransactions: requiredTransactions,
        usedTransactions: sorted.length,
        probability: 0,
        level: DailyInjuryPredictionLevel.insufficient,
        modelVersion: _model.version,
        modelSource: _model.source,
        featureValues: const {},
        chartScores: sorted.map((record) => record.scoreBefore).toList(),
      );
    }

    final window = sorted.sublist(sorted.length - requiredTransactions);
    final features = featureValuesForWindow(window);
    final probability = _predictProbability(features);
    return DailyInjuryPrediction(
      hasEnoughData: true,
      requiredTransactions: requiredTransactions,
      usedTransactions: window.length,
      probability: probability.clamp(0.0, 1.0).toDouble(),
      level: _model.thresholds.levelFor(probability),
      modelVersion: _model.version,
      modelSource: _model.source,
      featureValues: features,
      chartScores: window.map((record) => record.scoreBefore).toList(),
      windowStart: window.first.dateTime,
      windowEnd: window.last.dateTime,
    );
  }

  double _predictProbability(Map<String, double> features) {
    // Binary Logistic Regression:
    // logit = beta0 + beta1*x1 + ... + betak*xk
    // P(y = 1 | x) = 1 / (1 + exp(-logit)).
    //
    // The features have already been normalized into comparable 0..1 ranges
    // before entering this function. Coefficients must come from a binary
    // Logistic Regression fit using maximum likelihood / negative
    // log-likelihood on research outcome labels.
    final logit = _model.intercept +
        _model.coefficients.entries.fold<double>(
          0,
          (sum, entry) => sum + entry.value * (features[entry.key] ?? 0),
        );
    return _sigmoid(logit);
  }

  static Map<String, double> featureValuesForWindow(
    List<EvaluationHistoryRecord> window,
  ) {
    final count = window.length;
    final beforeScores =
        window.map((record) => record.scoreBefore.toDouble()).toList();
    final afterScores =
        window.map((record) => record.scoreAfter.toDouble()).toList();
    final highOrAboveDays = window
        .where((record) => record.riskBefore.index >= RiskLevel.high.index)
        .length;
    final veryHighDays = window
        .where((record) => record.riskBefore == RiskLevel.veryHigh)
        .length;
    final noImprovementDays = window
        .where((record) => record.scoreAfter >= record.scoreBefore)
        .length;
    final trunkHighDays = window
        .where(
          (record) =>
              (record.bodyPartRisks[BodyPart.trunk]?.index ?? -1) >=
              RiskLevel.high.index,
        )
        .length;
    final neckOrUpperLimbHighDays = window.where((record) {
      final neck = record.bodyPartRisks[BodyPart.neck]?.index ?? -1;
      final arms = record.bodyPartRisks[BodyPart.arms]?.index ?? -1;
      final wrists = record.bodyPartRisks[BodyPart.wrists]?.index ?? -1;
      return math.max(neck, math.max(arms, wrists)) >= RiskLevel.high.index;
    }).length;
    final isoDays = window
        .where((record) => record.assessmentBreakdown?.isoResult != null)
        .length;
    final activityCounts = <String, int>{};
    for (final record in window) {
      final key = record.activity?.name ?? record.activityName;
      activityCounts[key] = (activityCounts[key] ?? 0) + 1;
    }
    final repeatedActivityDays = activityCounts.values.isEmpty
        ? 0
        : activityCounts.values.reduce(math.max);
    final recentSlope =
        beforeScores.isEmpty ? 0 : beforeScores.last - beforeScores.first;
    final avgEconomicLoss =
        window.map((record) => record.economicLoss).fold<double>(
                  0,
                  (sum, value) => sum + value,
                ) /
            count;

    return {
      'avg_score_before_norm': _norm(_avg(beforeScores), 1, 9),
      'max_score_before_norm': _norm(beforeScores.reduce(math.max), 1, 9),
      'avg_score_after_norm': _norm(_avg(afterScores), 1, 9),
      'high_or_above_days_norm': highOrAboveDays / count,
      'very_high_days_norm': veryHighDays / count,
      'no_improvement_days_norm': noImprovementDays / count,
      'trunk_high_days_norm': trunkHighDays / count,
      'neck_or_upper_limb_high_days_norm': neckOrUpperLimbHighDays / count,
      'iso_days_norm': isoDays / count,
      'avg_economic_loss_norm': _bounded(avgEconomicLoss / 40000),
      'repeated_same_activity_norm': repeatedActivityDays / count,
      'recent_score_slope_norm': _bounded((recentSlope + 8) / 16),
    };
  }

  static double _avg(List<double> values) =>
      values.fold<double>(0, (sum, value) => sum + value) / values.length;

  static double _norm(double value, double min, double max) {
    if (max <= min) return 0;
    return _bounded((value - min) / (max - min));
  }

  static double _bounded(double value) => value.clamp(0.0, 1.0).toDouble();

  double _sigmoid(double logit) {
    if (logit >= 0) {
      final expNeg = math.exp(-logit);
      return 1 / (1 + expNeg);
    }
    final expValue = math.exp(logit);
    return expValue / (1 + expValue);
  }
}

class _DailyInjuryLogisticModel {
  const _DailyInjuryLogisticModel({
    required this.version,
    required this.source,
    required this.minTransactions,
    required this.thresholds,
    required this.intercept,
    required this.coefficients,
  });

  final String version;
  final String source;
  final int minTransactions;
  final _DailyPredictionThresholds thresholds;
  final double intercept;
  final Map<String, double> coefficients;

  factory _DailyInjuryLogisticModel.fromJson(Map<String, Object?> json) {
    final logistic = Map<String, Object?>.from(
      json['logisticRegression'] as Map? ?? {},
    );
    return _DailyInjuryLogisticModel(
      version: json['version'] as String? ?? 'unknown',
      source: json['source'] as String? ?? 'unknown',
      minTransactions: (json['minTransactions'] as num?)?.toInt() ?? 7,
      thresholds: _DailyPredictionThresholds.fromJson(
        Map<String, Object?>.from(json['thresholds'] as Map? ?? {}),
      ),
      intercept: (logistic['intercept'] as num?)?.toDouble() ?? 0,
      coefficients: (logistic['coefficients'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
    );
  }
}

class _DailyPredictionThresholds {
  const _DailyPredictionThresholds({
    required this.watch,
    required this.high,
    required this.critical,
  });

  final double watch;
  final double high;
  final double critical;

  factory _DailyPredictionThresholds.fromJson(Map<String, Object?> json) {
    return _DailyPredictionThresholds(
      watch: (json['watch'] as num?)?.toDouble() ?? 0.45,
      high: (json['high'] as num?)?.toDouble() ?? 0.65,
      critical: (json['critical'] as num?)?.toDouble() ?? 0.82,
    );
  }

  DailyInjuryPredictionLevel levelFor(double probability) {
    if (probability >= critical) return DailyInjuryPredictionLevel.critical;
    if (probability >= high) return DailyInjuryPredictionLevel.high;
    if (probability >= watch) return DailyInjuryPredictionLevel.watch;
    return DailyInjuryPredictionLevel.low;
  }
}
