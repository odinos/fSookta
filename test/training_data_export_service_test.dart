import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/training_data_export_service.dart';

void main() {
  test('builds daily Logistic Regression windows for researcher labels', () {
    final records = List.generate(
      7,
      (index) => _record(
        id: index + 1,
        dateTime: DateTime(2026, 6, index + 1),
      ),
    );

    final csv = TrainingDataExportService.buildDailyLogisticTrainingCsv(
      records: records,
      profilesByRecordId: const {
        7: UserProfile(
          profileId: 'profile-a',
          farmerId: 'FARM-001',
          name: 'Research Farmer',
        ),
      },
    );

    expect(TrainingDataExportService.dailyLogisticWindowCount(records), 1);
    expect(csv, contains('requires_medical_treatment_within_7_days'));
    expect(csv, contains('avg_score_before_norm'));
    expect(csv, contains('FARM-001_2026-06-01_2026-06-07_1-7'));
    expect(csv, contains('app_export_pending_research_follow_up'));
  });

  test('builds XGBoost pose rows with raw MoveNet feature columns', () {
    final record = _record(
      id: 10,
      dateTime: DateTime(2026, 6, 7),
      poseFrame: PoseRebaFrameAnalysis(
        imageIndex: 1,
        rebaInput: const RebaInputData(trunkScore: 4, neckScore: 2),
        rebaScore: 9,
        riskLevel: RiskLevel.veryHigh,
        trunkFlexionDeg: 68,
        jointFeatures: List.generate(51, (index) => (index + 1) / 100),
      ),
    );

    final csv = TrainingDataExportService.buildXGBoostTrainingCsv(
      records: [record],
      profilesByRecordId: const {
        10: UserProfile(profileId: 'profile-a', farmerId: 'FARM-001'),
      },
    );

    expect(TrainingDataExportService.xGBoostPoseRowCount([record]), 1);
    expect(csv, contains('nose_x'));
    expect(csv, contains('rightAnkle_score'));
    expect(csv, contains('training_reba_score'));
    expect(csv, contains('app_history_record:10/image:1'));
    expect(csv, contains('app_pseudo_label_pending_research_review'));
  });
}

EvaluationHistoryRecord _record({
  required int id,
  required DateTime dateTime,
  PoseRebaFrameAnalysis? poseFrame,
}) {
  return EvaluationHistoryRecord(
    id: id,
    farmerProfileId: 'profile-a',
    farmerId: 'FARM-001',
    activity: SooktaActivity.transplanting,
    activityName: 'Transplanting',
    dateTime: dateTime,
    scoreBefore: 8,
    scoreAfter: 6,
    riskBefore: RiskLevel.high,
    riskAfter: RiskLevel.medium,
    economicLoss: 12000,
    moneySaved: 3000,
    selectedSuggestions: const ['Raise work height'],
    bodyPartRisks: const {
      BodyPart.trunk: RiskLevel.high,
      BodyPart.neck: RiskLevel.medium,
    },
    assessmentBreakdown: AssessmentBreakdown(
      primaryMethod: AssessmentMethod.reba,
      rebaInput: const RebaInputData(
        trunkScore: 4,
        neckScore: 2,
        legScore: 1,
        upperArmScore: 2,
        lowerArmScore: 1,
        wristScore: 1,
        activityScore: 1,
      ),
      rebaResult: const ErgoResult(
        riskLevel: RiskLevel.high,
        techScore: 8,
        userScore: 8,
        userScoreColor: 0xFFF44336,
        limitValue: 15,
        suggestionKey: 'sugg_reba_high',
      ),
      ergoInput: const ErgoInputData(jobType: JobType.reba),
      poseFrames: poseFrame == null ? const [] : [poseFrame],
      worstPoseImageIndex: poseFrame?.imageIndex,
    ),
  );
}
