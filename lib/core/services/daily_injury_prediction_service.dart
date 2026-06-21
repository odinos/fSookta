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
    final rebaScores = window.map(_rebaScoreBefore).toList();
    final isoScores = window.map(_isoScoreBefore).whereType<double>().toList();
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
        .where((record) =>
            _bodyRiskIndex(record, BodyPart.trunk) >= RiskLevel.high.index)
        .length;
    final neckHighDays = window
        .where((record) =>
            _bodyRiskIndex(record, BodyPart.neck) >= RiskLevel.high.index)
        .length;
    final upperLimbHighDays = window.where((record) {
      final arms = _bodyRiskIndex(record, BodyPart.arms);
      final wrists = _bodyRiskIndex(record, BodyPart.wrists);
      return math.max(arms, wrists) >= RiskLevel.high.index;
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
    final recentRebaSlope = _recentSlope(rebaScores);
    final recentIsoSlope = _recentSlope(isoScores);
    final avgEconomicLoss =
        window.map((record) => record.economicLoss).fold<double>(
                  0,
                  (sum, value) => sum + value,
                ) /
            count;
    final ages = window
        .map((record) => _parseDouble(record.farmerAge))
        .whereType<double>()
        .toList();
    final genders = window
        .map(
          (record) => (record.farmerGender ??
                  record.assessmentBreakdown?.ergoInput.gender ??
                  '')
              .toLowerCase(),
        )
        .toList();
    final maleDays = genders
        .where((value) => value.startsWith('male') || value.startsWith('ชาย'))
        .length;
    final bmis = window.map(_bmiForRecord).whereType<double>().toList();
    final overweightBmiDays =
        window.where((record) => (_bmiForRecord(record) ?? 0) >= 23).length;
    final toolWeightList =
        window.map(_toolLoadKg).where((value) => value > 0).toList();
    final highToolLoadDays =
        window.where((record) => _toolLoadKg(record) >= 15).length;
    final liftFrequencyPerHour = window
        .map((record) =>
            (record.assessmentBreakdown?.ergoInput.liftFrequency ?? 0) * 60)
        .toList();
    final carryingExposures = window.map(_carryingExposureNorm).toList();
    final pushPullExposures = window.map(_pushPullExposureNorm).toList();

    final avgScoreBefore = _norm(_avg(beforeScores), 1, 9);
    final maxScoreBefore = _norm(beforeScores.reduce(math.max), 1, 9);
    final avgScoreAfter = _norm(_avg(afterScores), 1, 9);
    final avgRebaScore = _norm(_avg(rebaScores), 1, 9);
    final maxRebaScore = _norm(rebaScores.reduce(math.max), 1, 9);
    final avgIsoScore = isoScores.isEmpty ? 0.0 : _norm(_avg(isoScores), 1, 9);
    final maxIsoScore =
        isoScores.isEmpty ? 0.0 : _norm(isoScores.reduce(math.max), 1, 9);
    final avgToolLoad =
        toolWeightList.isEmpty ? 0.0 : _bounded(_avg(toolWeightList) / 50);
    final maxToolLoad = toolWeightList.isEmpty
        ? 0.0
        : _bounded(toolWeightList.reduce(math.max) / 50);
    final avgLiftFrequencyPerHour = _bounded(_avg(liftFrequencyPerHour) / 720);

    return {
      'avg_reba_score_before_norm': avgRebaScore,
      'max_reba_score_before_norm': maxRebaScore,
      'avg_app_score_after_norm': avgScoreAfter,
      'avg_iso_score_before_norm': avgIsoScore,
      'max_iso_score_before_norm': maxIsoScore,
      'high_or_above_days_norm': highOrAboveDays / count,
      'very_high_days_norm': veryHighDays / count,
      'no_improvement_days_norm': noImprovementDays / count,
      'trunk_high_days_norm': trunkHighDays / count,
      'neck_high_days_norm': neckHighDays / count,
      'upper_limb_high_days_norm': upperLimbHighDays / count,
      'iso_days_norm': isoDays / count,
      'load_weight_norm': avgToolLoad,
      'max_load_weight_norm': maxToolLoad,
      'high_tool_load_days_norm': highToolLoadDays / count,
      'frequency_of_lifting_norm': avgLiftFrequencyPerHour,
      'carrying_exposure_norm': _avg(carryingExposures),
      'push_pull_exposure_norm': _avg(pushPullExposures),
      'avg_economic_loss_norm': _bounded(avgEconomicLoss / 40000),
      'repeated_same_activity_norm': repeatedActivityDays / count,
      'recent_reba_score_slope_norm': _bounded((recentRebaSlope + 8) / 16),
      'recent_iso_score_slope_norm':
          isoScores.length < 2 ? 0 : _bounded((recentIsoSlope + 8) / 16),
      'avg_age_norm': ages.isEmpty ? 0 : _bounded(_avg(ages) / 80),
      'male_ratio_norm': maleDays / count,
      'avg_bmi_norm': bmis.isEmpty ? 0 : _norm(_avg(bmis), 15, 35),
      'overweight_bmi_days_norm': overweightBmiDays / count,
      // Backward-compatible aliases for older local test fixtures and
      // previously exported templates. New model assets use the explicit
      // REBA/ISO feature names above.
      'avg_score_before_norm': avgScoreBefore,
      'max_score_before_norm': maxScoreBefore,
      'avg_score_after_norm': avgScoreAfter,
      'neck_or_upper_limb_high_days_norm':
          math.max(neckHighDays, upperLimbHighDays) / count,
      'recent_score_slope_norm':
          _bounded((_recentSlope(beforeScores) + 8) / 16),
      'avg_tool_load_kg_norm': avgToolLoad,
      'max_tool_load_kg_norm': maxToolLoad,
      'avg_lift_frequency_per_hour_norm': avgLiftFrequencyPerHour,
    };
  }

  static double _rebaScoreBefore(EvaluationHistoryRecord record) {
    return (record.assessmentBreakdown?.rebaResult.userScore ??
            record.scoreBefore)
        .toDouble();
  }

  static double? _isoScoreBefore(EvaluationHistoryRecord record) {
    return record.assessmentBreakdown?.isoResult?.userScore.toDouble();
  }

  static int _bodyRiskIndex(
    EvaluationHistoryRecord record,
    BodyPart bodyPart,
  ) {
    final rebaRisks = record.assessmentBreakdown?.rebaResult.bodyPartRisks;
    final rebaRisk =
        rebaRisks == null || rebaRisks.isEmpty ? null : rebaRisks[bodyPart];
    return (rebaRisk ?? record.bodyPartRisks[bodyPart])?.index ?? -1;
  }

  static double _recentSlope(List<double> scores) {
    if (scores.length < 2) return 0;
    return scores.last - scores.first;
  }

  static double _carryingExposureNorm(EvaluationHistoryRecord record) {
    final input = record.assessmentBreakdown?.ergoInput;
    if (input == null || input.jobType != JobType.lifting) return 0;
    final load = _bounded(_toolLoadKg(record) / 50);
    final duration = _bounded(input.durationHours / 8);
    final frequency = _bounded((input.liftFrequency * 60) / 720);
    final distance = _bounded(input.transportDistance / 20);
    // Exposure feature for research fitting: load dominates, with duration,
    // repetition, and carrying distance as additional ISO11228-1 context.
    return _bounded(
      (load * 0.45) +
          (duration * 0.25) +
          (frequency * 0.20) +
          (distance * 0.10),
    );
  }

  static double _pushPullExposureNorm(EvaluationHistoryRecord record) {
    final input = record.assessmentBreakdown?.ergoInput;
    if (input == null || input.jobType != JobType.pushPull) return 0;
    final forceRatio =
        math.max(input.initialForce / 25, input.sustainForce / 15);
    final duration = _bounded(input.durationHours / 8);
    final distance = _bounded(input.transportDistance / 20);
    return _bounded(
        (forceRatio * 0.60) + (duration * 0.25) + (distance * 0.15));
  }

  static double? _parseDouble(String? raw) {
    final value = raw?.trim().replaceAll(',', '.');
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  static double? _bmiForRecord(EvaluationHistoryRecord record) {
    if (record.farmerBmi != null && record.farmerBmi! > 0) {
      return record.farmerBmi;
    }
    final weight = _parseDouble(record.farmerWeight);
    final height = _parseDouble(record.farmerHeight);
    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return null;
    }
    final meters = height / 100;
    return weight / (meters * meters);
  }

  static double _toolLoadKg(EvaluationHistoryRecord record) {
    final input = record.assessmentBreakdown?.ergoInput;
    if (input == null) return 0;
    if (input.toolWeightKg > 0) return input.toolWeightKg;
    return input.loadWeight;
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
