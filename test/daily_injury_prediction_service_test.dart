import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/daily_injury_prediction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('daily prediction waits until seven transactions are available',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      _record(1, score: 6),
      _record(2, score: 7),
    ]);

    expect(prediction.hasEnoughData, isFalse);
    expect(prediction.usedTransactions, 2);
    expect(prediction.level, DailyInjuryPredictionLevel.insufficient);
  });

  test('daily prediction flags repeated high trunk-risk history', () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9,
          afterScore: 8,
          risk: RiskLevel.high,
          bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
          economicLoss: 20000,
        ),
    ]);

    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.usedTransactions, 7);
    expect(prediction.probability, greaterThan(0.65));
    expect(prediction.isResearchTrained, isFalse);
    expect(prediction.validatedProbability, isNull);
    expect(prediction.requiresTrendAttention, isTrue);
    expect(prediction.requiresCareAlert, isTrue);
    expect(prediction.chartScores, List<int>.filled(7, 9));
  });

  test('daily prediction exposes separate REBA and ISO11228 features',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 8,
          afterScore: 6,
          risk: RiskLevel.high,
          bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
          assessmentBreakdown: _breakdownWithIso(
            rebaScore: 8,
            isoScore: day.isEven ? 6 : 4,
          ),
        ),
    ]);

    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.featureValues, contains('avg_reba_score_before_norm'));
    expect(prediction.featureValues, contains('avg_iso_score_before_norm'));
    expect(prediction.featureValues, contains('recent_iso_score_slope_norm'));
    expect(prediction.featureValues, contains('carrying_exposure_norm'));
    expect(
        prediction.featureValues['avg_reba_score_before_norm'], greaterThan(0));
    expect(
        prediction.featureValues['avg_iso_score_before_norm'], greaterThan(0));
  });

  test('daily prediction runs separate REBA and ISO11228 logistic models',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: day.isEven ? 7 : 8,
          afterScore: day.isEven ? 4 : 5,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.medium,
          bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
          assessmentBreakdown: _breakdownWithIso(
            rebaScore: day.isEven ? 7 : 8,
            isoScore: day.isEven ? 3 : 6,
          ),
        ),
    ]);

    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.rebaLogisticProbability, inInclusiveRange(0, 1));
    expect(prediction.iso11228LogisticProbability, inInclusiveRange(0, 1));
    expect(
      prediction.rebaLogisticProbability,
      isNot(prediction.iso11228LogisticProbability),
    );
    expect(prediction.rebaLogisticModelVersion, contains('reba'));
    expect(prediction.iso11228LogisticModelVersion, contains('iso11228'));
    expect(
      prediction.probability,
      prediction.rebaLogisticProbability >
              prediction.iso11228LogisticProbability
          ? prediction.rebaLogisticProbability
          : prediction.iso11228LogisticProbability,
    );
  });

  test('daily trend uses before-improvement actual risk for field research',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9,
          afterScore: 3,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.low,
          bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
        ),
    ]);

    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.chartScores, List<int>.filled(7, 9));
    expect(prediction.featureValues['high_or_above_days_norm'], 1);
    expect(prediction.level, DailyInjuryPredictionLevel.critical);
    expect(prediction.requiresCareAlert, isTrue);
  });

  test('daily trend uses REBA before values, not ISO-combined or after values',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9,
          afterScore: 3,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.low,
          assessmentBreakdown: _breakdownWithIso(
            rebaScore: day.isEven ? 6 : 5,
            isoScore: 9,
            rebaRisk: RiskLevel.medium,
            isoRisk: RiskLevel.high,
          ),
        ),
    ]);

    expect(prediction.chartScores, [5, 6, 5, 6, 5, 6, 5]);
    expect(prediction.latestScore, 5);
    expect(prediction.highRiskCount, 0);
    expect(prediction.level, DailyInjuryPredictionLevel.low);
  });

  test('daily trend exposes parallel before and after score series', () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9 - day % 2,
          afterScore: 5 - day % 2,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.medium,
        ),
    ]);

    expect(prediction.chartScores, [8, 9, 8, 9, 8, 9, 8]);
    expect(prediction.chartAfterScores, [4, 5, 4, 5, 4, 5, 4]);
  });

  test('daily trend exposes REBA and ISO before/after series separately',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9,
          afterScore: 2,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.low,
          assessmentBreakdown: _breakdownWithIso(
            rebaScore: day.isEven ? 8 : 9,
            isoScore: day.isEven ? 6 : 7,
          ),
          afterAssessmentBreakdown: _breakdownWithIso(
            rebaScore: day.isEven ? 4 : 5,
            isoScore: day.isEven ? 3 : 4,
            rebaRisk: RiskLevel.medium,
            isoRisk: RiskLevel.medium,
          ),
        ),
    ]);

    expect(prediction.chartRebaBeforeScores, [9, 8, 9, 8, 9, 8, 9]);
    expect(prediction.chartRebaAfterScores, [5, 4, 5, 4, 5, 4, 5]);
    expect(prediction.chartIsoBeforeScores, [7, 6, 7, 6, 7, 6, 7]);
    expect(prediction.chartIsoAfterScores, [4, 3, 4, 3, 4, 3, 4]);
    expect(prediction.averageIsoAfterScore, closeTo(25 / 7, 0.001));
  });

  test('daily logistic features include after-assessment values', () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 9,
          afterScore: 3,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.low,
          assessmentBreakdown: _breakdownWithIso(
            rebaScore: 9,
            isoScore: 8,
          ),
          afterAssessmentBreakdown: _breakdownWithIso(
            rebaScore: 3,
            isoScore: 2,
            rebaRisk: RiskLevel.low,
            isoRisk: RiskLevel.low,
          ),
        ),
    ]);

    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.featureValues['avg_reba_score_after_norm'],
        closeTo(0.25, 0.001));
    expect(prediction.featureValues['avg_iso_score_after_norm'],
        closeTo(0.125, 0.001));
    expect(prediction.featureValues['no_improvement_days_norm'], 0);
  });

  test('daily trend summarizes farmer-friendly before and after improvement',
      () async {
    final service = await DailyInjuryPredictionService.load();

    final prediction = service.predictForRecords([
      for (var day = 1; day <= 7; day++)
        _record(
          day,
          score: 8,
          afterScore: 5,
          risk: RiskLevel.high,
          riskAfter: RiskLevel.medium,
        ),
    ]);

    expect(prediction.averageBeforeScore, 8);
    expect(prediction.averageAfterScore, 5);
    expect(prediction.averageScoreReduction, 3);
    expect(prediction.improvedRecordCount, 7);
    expect(prediction.afterHighRiskCount, 0);
  });
}

EvaluationHistoryRecord _record(
  int day, {
  int score = 5,
  int? afterScore,
  RiskLevel risk = RiskLevel.medium,
  RiskLevel? riskAfter,
  Map<BodyPart, RiskLevel> bodyPartRisks = const {},
  int economicLoss = 0,
  AssessmentBreakdown? assessmentBreakdown,
  AssessmentBreakdown? afterAssessmentBreakdown,
}) {
  return EvaluationHistoryRecord(
    id: day,
    farmerProfileId: 'farmer-1',
    farmerId: 'FSK-001',
    farmerName: 'Test Farmer',
    activityName: 'Planting',
    dateTime: DateTime(2026, 6, day),
    scoreBefore: score,
    scoreAfter: afterScore ?? score - 1,
    riskBefore: risk,
    riskAfter: riskAfter ?? risk,
    economicLoss: economicLoss,
    moneySaved: 0,
    selectedSuggestions: const [],
    bodyPartRisks: bodyPartRisks,
    assessmentBreakdown: assessmentBreakdown,
    afterAssessmentBreakdown: afterAssessmentBreakdown,
  );
}

AssessmentBreakdown _breakdownWithIso({
  required int rebaScore,
  required int isoScore,
  RiskLevel rebaRisk = RiskLevel.high,
  RiskLevel isoRisk = RiskLevel.high,
}) {
  return AssessmentBreakdown(
    primaryMethod: AssessmentMethod.rebaIsoCombined,
    rebaInput: const RebaInputData(
      trunkScore: 4,
      neckScore: 2,
      upperArmScore: 2,
      activityScore: 1,
    ),
    rebaResult: ErgoResult(
      riskLevel: rebaRisk,
      techScore: rebaScore.toDouble(),
      userScore: rebaScore,
      userScoreColor: 0xFFF44336,
      limitValue: 15,
      suggestionKey: 'sugg_reba_high',
      bodyPartRisks: {BodyPart.trunk: rebaRisk},
    ),
    ergoInput: const ErgoInputData(
      jobType: JobType.lifting,
      toolWeightKg: 17.5,
      loadWeight: 17.5,
      liftFrequency: 1.5,
      durationHours: 2,
      transportDistance: 8,
    ),
    isoMethod: AssessmentMethod.iso11228Lifting,
    isoResult: ErgoResult(
      riskLevel: isoRisk,
      techScore: isoScore.toDouble(),
      userScore: isoScore,
      userScoreColor: 0xFFF44336,
      limitValue: 12,
      suggestionKey: 'sugg_improve',
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
    ),
  );
}
