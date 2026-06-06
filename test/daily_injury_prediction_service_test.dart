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
    expect(prediction.requiresCareAlert, isTrue);
    expect(prediction.chartScores, List<int>.filled(7, 9));
  });
}

EvaluationHistoryRecord _record(
  int day, {
  int score = 5,
  int? afterScore,
  RiskLevel risk = RiskLevel.medium,
  Map<BodyPart, RiskLevel> bodyPartRisks = const {},
  int economicLoss = 0,
}) {
  return EvaluationHistoryRecord(
    id: day,
    farmerProfileId: 'farmer-1',
    farmerId: 'FSK-001',
    farmerName: 'Test Farmer',
    activityName: 'Transplanting',
    dateTime: DateTime(2026, 6, day),
    scoreBefore: score,
    scoreAfter: afterScore ?? score - 1,
    riskBefore: risk,
    riskAfter: risk,
    economicLoss: economicLoss,
    moneySaved: 0,
    selectedSuggestions: const [],
    bodyPartRisks: bodyPartRisks,
  );
}
