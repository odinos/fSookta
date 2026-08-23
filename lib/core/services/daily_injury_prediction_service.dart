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
    required this.latestScore,
    required this.averageScore,
    required this.maximumScore,
    required this.highRiskCount,
    required this.trendDirection,
    required this.latestIsoRiskLevel,
    required this.latestIsoScore,
    required this.averageLoadKg,
    required this.averageLiftFrequencyPerHour,
    required this.averageBeforeScore,
    required this.averageAfterScore,
    required this.averageScoreReduction,
    required this.averageRebaBeforeScore,
    required this.averageRebaAfterScore,
    required this.averageIsoBeforeScore,
    required this.averageIsoAfterScore,
    required this.improvedRecordCount,
    required this.afterHighRiskCount,
    required this.rebaLogisticProbability,
    required this.iso11228LogisticProbability,
    required this.rebaLogisticModelVersion,
    required this.iso11228LogisticModelVersion,
    required this.modelVersion,
    required this.modelSource,
    required this.isResearchTrained,
    required this.featureValues,
    required this.chartScores,
    required this.chartAfterScores,
    required this.chartRebaBeforeScores,
    required this.chartRebaAfterScores,
    required this.chartIsoBeforeScores,
    required this.chartIsoAfterScores,
    this.windowStart,
    this.windowEnd,
  });

  final bool hasEnoughData;
  final int requiredTransactions;
  final int usedTransactions;
  final double probability;
  final DailyInjuryPredictionLevel level;
  final int latestScore;
  final double averageScore;
  final int maximumScore;
  final int highRiskCount;
  final TrendDirection trendDirection;
  final RiskLevel? latestIsoRiskLevel;
  final int? latestIsoScore;
  final double averageLoadKg;
  final double averageLiftFrequencyPerHour;
  final double averageBeforeScore;
  final double averageAfterScore;
  final double averageScoreReduction;
  final double averageRebaBeforeScore;
  final double averageRebaAfterScore;
  final double averageIsoBeforeScore;
  final double averageIsoAfterScore;
  final int improvedRecordCount;
  final int afterHighRiskCount;
  final double rebaLogisticProbability;
  final double iso11228LogisticProbability;
  final String rebaLogisticModelVersion;
  final String iso11228LogisticModelVersion;
  final String modelVersion;
  final String modelSource;
  final bool isResearchTrained;
  final Map<String, double> featureValues;
  final List<int> chartScores;
  final List<int> chartAfterScores;
  final List<int> chartRebaBeforeScores;
  final List<int> chartRebaAfterScores;
  final List<int?> chartIsoBeforeScores;
  final List<int?> chartIsoAfterScores;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  double? get validatedProbability =>
      isResearchTrained ? probability : null;

  bool get requiresTrendAttention =>
      level == DailyInjuryPredictionLevel.high ||
      level == DailyInjuryPredictionLevel.critical;

  bool get requiresCareAlert => requiresTrendAttention;
}

enum TrendDirection {
  decreasing,
  stable,
  increasing,
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
      final rebaBeforeScores =
          sorted.map((record) => _rebaScoreBefore(record).toDouble()).toList();
      final rebaAfterScores =
          sorted.map((record) => _rebaScoreAfter(record).toDouble()).toList();
      final isoBeforeScores = sorted.map(_isoScoreBefore).toList();
      final isoAfterScores = sorted.map(_isoScoreAfter).toList();
      return DailyInjuryPrediction(
        hasEnoughData: false,
        requiredTransactions: requiredTransactions,
        usedTransactions: sorted.length,
        probability: 0,
        level: DailyInjuryPredictionLevel.insufficient,
        latestScore: sorted.isEmpty ? 0 : _rebaScoreBefore(sorted.last),
        averageScore: rebaBeforeScores.isEmpty ? 0 : _avg(rebaBeforeScores),
        maximumScore:
            sorted.isEmpty ? 0 : sorted.map(_rebaScoreBefore).reduce(math.max),
        highRiskCount: sorted
            .where((record) =>
                _rebaRiskBefore(record).index >= RiskLevel.high.index)
            .length,
        trendDirection: _trendDirection(
          rebaBeforeScores,
        ),
        latestIsoRiskLevel: sorted.isEmpty ? null : _isoRiskBefore(sorted.last),
        latestIsoScore:
            sorted.isEmpty ? null : _isoScoreBefore(sorted.last)?.round(),
        averageLoadKg: _averageToolLoadKg(sorted),
        averageLiftFrequencyPerHour: _averageLiftFrequencyPerHour(sorted),
        averageBeforeScore:
            rebaBeforeScores.isEmpty ? 0 : _avg(rebaBeforeScores),
        averageAfterScore: rebaAfterScores.isEmpty ? 0 : _avg(rebaAfterScores),
        averageScoreReduction:
            _averageScoreReduction(rebaBeforeScores, rebaAfterScores),
        averageRebaBeforeScore:
            rebaBeforeScores.isEmpty ? 0 : _avg(rebaBeforeScores),
        averageRebaAfterScore:
            rebaAfterScores.isEmpty ? 0 : _avg(rebaAfterScores),
        averageIsoBeforeScore: _avgNullable(isoBeforeScores),
        averageIsoAfterScore: _avgNullable(isoAfterScores),
        improvedRecordCount: _improvedRecordCount(sorted),
        afterHighRiskCount: sorted
            .where((record) =>
                _rebaRiskAfter(record).index >= RiskLevel.high.index)
            .length,
        rebaLogisticProbability: 0,
        iso11228LogisticProbability: 0,
        rebaLogisticModelVersion: _model.rebaLogistic.version,
        iso11228LogisticModelVersion: _model.iso11228Logistic.version,
        modelVersion: _model.version,
        modelSource: _model.source,
        isResearchTrained: _model.researchTrained,
        featureValues: const {},
        chartScores: sorted.map(_rebaScoreBefore).toList(),
        chartAfterScores: sorted.map(_rebaScoreAfter).toList(),
        chartRebaBeforeScores: sorted.map(_rebaScoreBefore).toList(),
        chartRebaAfterScores: sorted.map(_rebaScoreAfter).toList(),
        chartIsoBeforeScores:
            sorted.map((record) => _isoScoreBefore(record)?.round()).toList(),
        chartIsoAfterScores:
            sorted.map((record) => _isoScoreAfter(record)?.round()).toList(),
      );
    }

    final window = sorted.sublist(sorted.length - requiredTransactions);
    final features = featureValuesForWindow(window);
    final rebaProbability =
        _predictLogisticProbability(_model.rebaLogistic, features);
    final iso11228Probability =
        _predictLogisticProbability(_model.iso11228Logistic, features);
    final probability = _model.usesSeparateLogisticRegressions
        ? math.max(rebaProbability, iso11228Probability)
        : rebaProbability;
    final actualScores = window.map(_rebaScoreBefore).toList();
    final afterScores = window.map(_rebaScoreAfter).toList();
    final isoBeforeScores = window.map(_isoScoreBefore).toList();
    final isoAfterScores = window.map(_isoScoreAfter).toList();
    final highRiskCount = window
        .where(
            (record) => _rebaRiskBefore(record).index >= RiskLevel.high.index)
        .length;
    return DailyInjuryPrediction(
      hasEnoughData: true,
      requiredTransactions: requiredTransactions,
      usedTransactions: window.length,
      probability: probability.clamp(0.0, 1.0).toDouble(),
      level: _levelForHighRiskCount(highRiskCount),
      latestScore: actualScores.last,
      averageScore:
          _avg(actualScores.map((score) => score.toDouble()).toList()),
      maximumScore: actualScores.reduce(math.max),
      highRiskCount: highRiskCount,
      trendDirection: _trendDirection(
        actualScores.map((score) => score.toDouble()).toList(),
      ),
      latestIsoRiskLevel: _isoRiskBefore(window.last),
      latestIsoScore: _isoScoreBefore(window.last)?.round(),
      averageLoadKg: _averageToolLoadKg(window),
      averageLiftFrequencyPerHour: _averageLiftFrequencyPerHour(window),
      averageBeforeScore:
          _avg(actualScores.map((score) => score.toDouble()).toList()),
      averageAfterScore:
          _avg(afterScores.map((score) => score.toDouble()).toList()),
      averageScoreReduction: _averageScoreReduction(
        actualScores.map((score) => score.toDouble()).toList(),
        afterScores.map((score) => score.toDouble()).toList(),
      ),
      averageRebaBeforeScore:
          _avg(actualScores.map((score) => score.toDouble()).toList()),
      averageRebaAfterScore:
          _avg(afterScores.map((score) => score.toDouble()).toList()),
      averageIsoBeforeScore: _avgNullable(isoBeforeScores),
      averageIsoAfterScore: _avgNullable(isoAfterScores),
      improvedRecordCount: _improvedRecordCount(window),
      afterHighRiskCount: window
          .where(
              (record) => _rebaRiskAfter(record).index >= RiskLevel.high.index)
          .length,
      rebaLogisticProbability: rebaProbability,
      iso11228LogisticProbability: iso11228Probability,
      rebaLogisticModelVersion: _model.rebaLogistic.version,
      iso11228LogisticModelVersion: _model.iso11228Logistic.version,
      modelVersion: _model.version,
      modelSource: _model.source,
      isResearchTrained: _model.researchTrained,
      featureValues: features,
      chartScores: actualScores,
      chartAfterScores: afterScores,
      chartRebaBeforeScores: actualScores,
      chartRebaAfterScores: afterScores,
      chartIsoBeforeScores:
          window.map((record) => _isoScoreBefore(record)?.round()).toList(),
      chartIsoAfterScores:
          window.map((record) => _isoScoreAfter(record)?.round()).toList(),
      windowStart: window.first.dateTime,
      windowEnd: window.last.dateTime,
    );
  }

  static DailyInjuryPredictionLevel _levelForHighRiskCount(int count) {
    if (count >= 6) return DailyInjuryPredictionLevel.critical;
    if (count >= 4) return DailyInjuryPredictionLevel.high;
    if (count >= 2) return DailyInjuryPredictionLevel.watch;
    return DailyInjuryPredictionLevel.low;
  }

  double _predictLogisticProbability(
    _DailyLogisticRegression logistic,
    Map<String, double> features,
  ) {
    // Binary Logistic Regression:
    // logit = beta0 + beta1*x1 + ... + betak*xk
    // P(y = 1 | x) = 1 / (1 + exp(-logit)).
    //
    // The features have already been normalized into comparable 0..1 ranges
    // before entering this function. Coefficients must come from a binary
    // Logistic Regression fit using maximum likelihood / negative
    // log-likelihood on research outcome labels.
    final logit = logistic.intercept +
        logistic.coefficients.entries.fold<double>(
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
        window.map((record) => _rebaScoreBefore(record).toDouble()).toList();
    final afterScores =
        window.map((record) => _rebaScoreAfter(record).toDouble()).toList();
    final rebaScores = beforeScores;
    final isoScores = window.map(_isoScoreBefore).whereType<double>().toList();
    final isoAfterScores =
        window.map(_isoScoreAfter).whereType<double>().toList();
    final highOrAboveDays = window
        .where(
            (record) => _rebaRiskBefore(record).index >= RiskLevel.high.index)
        .length;
    final veryHighDays = window
        .where((record) => _rebaRiskBefore(record) == RiskLevel.veryHigh)
        .length;
    final noImprovementDays = window
        .where((record) => _rebaScoreAfter(record) >= _rebaScoreBefore(record))
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
    final avgIsoAfterScore =
        isoAfterScores.isEmpty ? 0.0 : _norm(_avg(isoAfterScores), 1, 9);
    final avgToolLoad =
        toolWeightList.isEmpty ? 0.0 : _bounded(_avg(toolWeightList) / 50);
    final maxToolLoad = toolWeightList.isEmpty
        ? 0.0
        : _bounded(toolWeightList.reduce(math.max) / 50);
    final avgLiftFrequencyPerHour = _bounded(_avg(liftFrequencyPerHour) / 720);

    return {
      'avg_reba_score_before_norm': avgRebaScore,
      'max_reba_score_before_norm': maxRebaScore,
      'avg_reba_score_after_norm': avgScoreAfter,
      'max_reba_score_after_norm': _norm(afterScores.reduce(math.max), 1, 9),
      'avg_app_score_after_norm': avgScoreAfter,
      'avg_iso_score_before_norm': avgIsoScore,
      'max_iso_score_before_norm': maxIsoScore,
      'avg_iso_score_after_norm': avgIsoAfterScore,
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

  static double? _isoScoreBefore(EvaluationHistoryRecord record) {
    return record.assessmentBreakdown?.isoResult?.userScore.toDouble();
  }

  static double? _isoScoreAfter(EvaluationHistoryRecord record) {
    return record.afterAssessmentBreakdown?.isoResult?.userScore.toDouble();
  }

  static RiskLevel? _isoRiskBefore(EvaluationHistoryRecord record) {
    return record.assessmentBreakdown?.isoResult?.riskLevel;
  }

  static int _rebaScoreBefore(EvaluationHistoryRecord record) {
    return record.assessmentBreakdown?.rebaResult.userScore ??
        record.scoreBefore;
  }

  static RiskLevel _rebaRiskBefore(EvaluationHistoryRecord record) {
    return record.assessmentBreakdown?.rebaResult.riskLevel ??
        record.riskBefore;
  }

  static int _rebaScoreAfter(EvaluationHistoryRecord record) {
    return record.afterAssessmentBreakdown?.rebaResult.userScore ??
        record.scoreAfter;
  }

  static RiskLevel _rebaRiskAfter(EvaluationHistoryRecord record) {
    return record.afterAssessmentBreakdown?.rebaResult.riskLevel ??
        record.riskAfter;
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

  static TrendDirection _trendDirection(List<double> scores) {
    final slope = _recentSlope(scores);
    if (slope >= 1) return TrendDirection.increasing;
    if (slope <= -1) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  static double _averageScoreReduction(
    List<double> beforeScores,
    List<double> afterScores,
  ) {
    if (beforeScores.isEmpty || afterScores.isEmpty) return 0;
    final pairCount = math.min(beforeScores.length, afterScores.length);
    final reductions = <double>[];
    for (var i = 0; i < pairCount; i++) {
      reductions.add(beforeScores[i] - afterScores[i]);
    }
    return _avg(reductions);
  }

  static int _improvedRecordCount(List<EvaluationHistoryRecord> records) {
    return records
        .where((record) => _rebaScoreAfter(record) < _rebaScoreBefore(record))
        .length;
  }

  static double _averageToolLoadKg(List<EvaluationHistoryRecord> records) {
    final values =
        records.map(_toolLoadKg).where((value) => value > 0).toList();
    return values.isEmpty ? 0 : _avg(values);
  }

  static double _averageLiftFrequencyPerHour(
    List<EvaluationHistoryRecord> records,
  ) {
    final values = records
        .map((record) =>
            (record.assessmentBreakdown?.ergoInput.liftFrequency ?? 0) * 60)
        .where((value) => value > 0)
        .toList();
    return values.isEmpty ? 0 : _avg(values);
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

  static double _avgNullable(List<double?> values) {
    final present = values.whereType<double>().toList();
    return present.isEmpty ? 0 : _avg(present);
  }

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
    required this.rebaLogistic,
    required this.iso11228Logistic,
    required this.usesSeparateLogisticRegressions,
    required this.researchTrained,
  });

  final String version;
  final String source;
  final int minTransactions;
  final _DailyPredictionThresholds thresholds;
  final _DailyLogisticRegression rebaLogistic;
  final _DailyLogisticRegression iso11228Logistic;
  final bool usesSeparateLogisticRegressions;
  final bool researchTrained;

  factory _DailyInjuryLogisticModel.fromJson(Map<String, Object?> json) {
    final version = json['version'] as String? ?? 'unknown';
    final source = json['source'] as String? ?? 'unknown';
    final logistic = Map<String, Object?>.from(
      json['logisticRegression'] as Map? ?? {},
    );
    final fallbackLogistic = _DailyLogisticRegression.fromJson(
      logistic,
      fallbackVersion: '$version-combined',
      fallbackSource: source,
    );
    final logisticRegressions = Map<String, Object?>.from(
      json['logisticRegressions'] as Map? ?? {},
    );
    final trainingStatus = Map<String, Object?>.from(
      json['trainingStatus'] as Map? ?? {},
    );
    final rebaJson = Map<String, Object?>.from(
      logisticRegressions['reba'] as Map? ?? {},
    );
    final iso11228Json = Map<String, Object?>.from(
      logisticRegressions['iso11228'] as Map? ?? {},
    );
    return _DailyInjuryLogisticModel(
      version: version,
      source: source,
      minTransactions: (json['minTransactions'] as num?)?.toInt() ?? 7,
      thresholds: _DailyPredictionThresholds.fromJson(
        Map<String, Object?>.from(json['thresholds'] as Map? ?? {}),
      ),
      rebaLogistic: rebaJson.isEmpty
          ? fallbackLogistic.copyWith(version: '$version-reba')
          : _DailyLogisticRegression.fromJson(
              rebaJson,
              fallbackVersion: '$version-reba',
              fallbackSource: source,
            ),
      iso11228Logistic: iso11228Json.isEmpty
          ? fallbackLogistic.copyWith(version: '$version-iso11228')
          : _DailyLogisticRegression.fromJson(
              iso11228Json,
              fallbackVersion: '$version-iso11228',
              fallbackSource: source,
            ),
      usesSeparateLogisticRegressions:
          rebaJson.isNotEmpty || iso11228Json.isNotEmpty,
      researchTrained:
          trainingStatus['researchTrained'] as bool? ?? false,
    );
  }
}

class _DailyLogisticRegression {
  const _DailyLogisticRegression({
    required this.version,
    required this.source,
    required this.intercept,
    required this.coefficients,
  });

  final String version;
  final String source;
  final double intercept;
  final Map<String, double> coefficients;

  _DailyLogisticRegression copyWith({String? version, String? source}) {
    return _DailyLogisticRegression(
      version: version ?? this.version,
      source: source ?? this.source,
      intercept: intercept,
      coefficients: coefficients,
    );
  }

  factory _DailyLogisticRegression.fromJson(
    Map<String, Object?> json, {
    required String fallbackVersion,
    required String fallbackSource,
  }) {
    return _DailyLogisticRegression(
      version: json['version'] as String? ?? fallbackVersion,
      source: json['source'] as String? ?? fallbackSource,
      intercept: (json['intercept'] as num?)?.toDouble() ?? 0,
      coefficients: (json['coefficients'] as Map? ?? {}).map(
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
