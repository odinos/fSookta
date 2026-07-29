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
    expect(csv, contains('export_generated_at'));
    expect(csv, contains('msd_symptom_present'));
    expect(csv, contains('requires_medical_treatment_within_7_days'));
    expect(csv, contains('avg_reba_score_before_norm'));
    expect(csv, contains('avg_iso_score_before_norm'));
    expect(csv, contains('avg_reba_score_after_norm'));
    expect(csv, contains('max_reba_score_after_norm'));
    expect(csv, contains('avg_score_before_norm'));
    expect(csv, contains('max_score_before_norm'));
    expect(csv, contains('avg_score_after_norm'));
    expect(csv, contains('recent_score_slope_norm'));
    expect(csv, contains('neck_or_upper_limb_high_days_norm'));
    expect(csv, contains('avg_bmi_norm'));
    expect(csv, contains('load_weight_norm'));
    expect(csv, contains('frequency_of_lifting_norm'));
    expect(csv, contains('FARM-001_2026-06-01_2026-06-07_1-7'));
    expect(csv, contains('app_export_pending_research_follow_up'));
  });

  test('builds XGBoost pose rows with raw MoveNet feature columns', () {
    final record = _record(
      id: 10,
      dateTime: DateTime(2026, 6, 7),
      poseFrame: PoseRebaFrameAnalysis(
        imageIndex: 1,
        timestampMs: 1200,
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
    expect(csv, contains('tool_used_en'));
    expect(csv, contains('Seedling bucket (5-10 kg)'));
    expect(csv, contains('app_history_record:10/image:1'));
    expect(csv, contains('app_pseudo_label_pending_research_review'));
    expect(csv, contains('video_motion_pattern'));
    expect(csv, contains('video_any_segment_risk_frame_ratio'));
    expect(csv, contains('video_trunk_risk_frame_ratio'));
    expect(csv, contains('upper_arm'));
    expect(csv, contains('video_camera'));
    expect(csv, contains('staticHighRiskHold'));
    expect(csv, contains('farmer_age'));
    expect(csv, contains('farmer_gender'));
    expect(csv, contains('farmer_bmi'));
    expect(csv, contains('manual_handling_weight_kg'));
    expect(csv, contains('manual_handling_distance_m'));
    expect(csv, contains('lift_frequency_per_minute'));
    expect(csv, contains('duration_hours'));
    expect(csv, contains('work_days_per_week'));
    expect(csv, contains('initial_force_n'));
    expect(csv, contains('sustain_force_n'));
    expect(csv, contains('reba_score_before_app'));
    expect(csv, contains('iso_score_before_app'));
    expect(csv, contains('iso_risk_before_app'));
    expect(csv, contains('7.5'));
    expect(csv, contains('0.2'));
    expect(csv, contains('1200'));
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
    farmerAge: '45',
    farmerGender: 'Female',
    farmerWeight: '62',
    farmerHeight: '158',
    farmerBmi: 24.8,
    farmerBmiCategory: 'overweight',
    activity: SooktaActivity.transplanting,
    activityName: 'Planting',
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
      ergoInput: const ErgoInputData(
        jobType: JobType.reba,
        toolId: 'seedling_bucket_5_10kg',
        toolLabelTh: 'ถังกล้า (5-10 กก.)',
        toolLabelEn: 'Seedling bucket (5-10 kg)',
        toolWeightKg: 7.5,
        toolWeightBandCode: 2,
        loadWeight: 7.5,
      ),
      poseFrames: poseFrame == null ? const [] : [poseFrame],
      worstPoseImageIndex: poseFrame?.imageIndex,
      motionSummary: poseFrame == null
          ? null
          : const MotionAnalysisSummary(
              sourceKind: 'video_camera',
              durationMs: 9600,
              sampledFrameCount: 8,
              readableFrameCount: 8,
              sampleRateFps: 0.83,
              highRiskFrameCount: 6,
              highRiskFrameRatio: 0.75,
              deepTrunkFlexionFrameCount: 5,
              deepTrunkFlexionRatio: 0.625,
              estimatedHighRiskSeconds: 7.2,
              estimatedDeepTrunkSeconds: 6,
              movementChangeCount: 3,
              pattern: MotionPattern.staticHighRiskHold,
              anySegmentRiskFrameCount: 7,
              anySegmentRiskFrameRatio: 0.875,
              estimatedSegmentRiskSeconds: 8.4,
              neckRiskFrameCount: 3,
              neckRiskFrameRatio: 0.375,
              trunkRiskFrameCount: 6,
              trunkRiskFrameRatio: 0.75,
              upperArmRiskFrameCount: 7,
              upperArmRiskFrameRatio: 0.875,
              lowerArmRiskFrameCount: 1,
              lowerArmRiskFrameRatio: 0.125,
              wristRiskFrameCount: 2,
              wristRiskFrameRatio: 0.25,
              legRiskFrameCount: 2,
              legRiskFrameRatio: 0.25,
              dominantRiskBodyPart: 'upper_arm',
              maxTrunkFlexionDeg: 68,
              avgTrunkFlexionDeg: 51,
            ),
    ),
  );
}
