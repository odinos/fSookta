import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';

import '../../app/app_state.dart';
import '../models/evaluation_models.dart';
import 'daily_injury_prediction_service.dart';

class TrainingDataExportBundle {
  const TrainingDataExportBundle({
    required this.dailyLogisticFile,
    required this.xgBoostFile,
    required this.dailyLogisticRows,
    required this.xgBoostRows,
  });

  final File dailyLogisticFile;
  final File xgBoostFile;
  final int dailyLogisticRows;
  final int xgBoostRows;
}

class TrainingDataExportService {
  const TrainingDataExportService._();

  static const dailyFeatureColumns = [
    'avg_score_before_norm',
    'max_score_before_norm',
    'avg_score_after_norm',
    'high_or_above_days_norm',
    'very_high_days_norm',
    'no_improvement_days_norm',
    'trunk_high_days_norm',
    'neck_or_upper_limb_high_days_norm',
    'iso_days_norm',
    'avg_economic_loss_norm',
    'repeated_same_activity_norm',
    'recent_score_slope_norm',
  ];

  static const _landmarks = [
    'nose',
    'leftEye',
    'rightEye',
    'leftEar',
    'rightEar',
    'leftShoulder',
    'rightShoulder',
    'leftElbow',
    'rightElbow',
    'leftWrist',
    'rightWrist',
    'leftHip',
    'rightHip',
    'leftKnee',
    'rightKnee',
    'leftAnkle',
    'rightAnkle',
  ];

  static const _components = ['x', 'y', 'score'];

  static List<String> get xGBoostFeatureColumns => [
        for (final landmark in _landmarks)
          for (final component in _components) '${landmark}_$component',
      ];

  static int dailyLogisticWindowCount(
    List<EvaluationHistoryRecord> records,
  ) {
    return _groupByFarmer(records).values.fold<int>(
          0,
          (sum, rows) => sum + math.max(0, rows.length - 6),
        );
  }

  static int xGBoostPoseRowCount(
    List<EvaluationHistoryRecord> records,
  ) {
    return records.fold<int>(
      0,
      (sum, record) =>
          sum +
          (record.assessmentBreakdown?.poseFrames
                  .where((frame) => frame.jointFeatures.length == 51)
                  .length ??
              0),
    );
  }

  static Future<TrainingDataExportBundle> exportTrainingFiles({
    required List<EvaluationHistoryRecord> records,
    required Map<int, UserProfile> profilesByRecordId,
    bool thai = true,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');

    final dailyRows = dailyLogisticWindowCount(records);
    final xgbRows = xGBoostPoseRowCount(records);
    final dailyFile =
        File('${directory.path}/sookta_train_daily_logistic_$timestamp.csv');
    final xgbFile =
        File('${directory.path}/sookta_train_xgboost_pose_$timestamp.csv');

    await dailyFile.writeAsString(
      buildDailyLogisticTrainingCsv(
        records: records,
        profilesByRecordId: profilesByRecordId,
        thai: thai,
      ),
      flush: true,
    );
    await xgbFile.writeAsString(
      buildXGBoostTrainingCsv(
        records: records,
        profilesByRecordId: profilesByRecordId,
      ),
      flush: true,
    );

    return TrainingDataExportBundle(
      dailyLogisticFile: dailyFile,
      xgBoostFile: xgbFile,
      dailyLogisticRows: dailyRows,
      xgBoostRows: xgbRows,
    );
  }

  static String buildDailyLogisticTrainingCsv({
    required List<EvaluationHistoryRecord> records,
    required Map<int, UserProfile> profilesByRecordId,
    bool thai = true,
  }) {
    final headers = [
      'row_type',
      'window_id',
      'farmer_id',
      'participant_code',
      'window_start_date',
      'window_end_date',
      'transaction_count',
      'transaction_ids',
      'activity_summary',
      'assessment_methods',
      ...dailyFeatureColumns,
      'requires_medical_treatment_within_7_days',
      'medical_visit_within_7_days',
      'treatment_required_within_7_days',
      'msd_symptom_present',
      'msd_symptom_location',
      'msd_symptom_severity',
      'lost_workdays_7d',
      'direct_medical_cost_thb',
      'productivity_loss_thb',
      'label_confidence',
      'outcome_source',
      'reviewer_id',
      'reviewed_at',
      'notes',
    ];

    final rows = <List<Object?>>[headers];
    for (final group in _groupByFarmer(records).values) {
      final sorted = group.toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      if (sorted.length < 7) continue;
      for (var start = 0; start <= sorted.length - 7; start++) {
        final window = sorted.sublist(start, start + 7);
        final lastRecord = window.last;
        final profile =
            profilesByRecordId[lastRecord.id] ?? _profileFromRecord(lastRecord);
        final features = DailyInjuryPredictionService.featureValuesForWindow(
          window,
        );
        final windowId = _windowId(profile, window);
        rows.add([
          'app_export_unlabeled',
          windowId,
          _farmerId(profile, lastRecord),
          _farmerId(profile, lastRecord),
          _dateOnly(window.first.dateTime),
          _dateOnly(window.last.dateTime),
          7,
          window.map((record) => record.id).join(';'),
          _uniqueText(window.map((record) => record.activityName)),
          _uniqueText(window.map((record) {
            final breakdown = record.assessmentBreakdown;
            if (breakdown == null) return 'unknown';
            if (breakdown.primaryMethod == AssessmentMethod.rebaIsoCombined) {
              return 'REBA+ISO11228-1';
            }
            return breakdown.primaryMethod.name;
          })),
          for (final column in dailyFeatureColumns) features[column] ?? 0,
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          'app_export_pending_research_follow_up',
          '',
          '',
          thai
              ? 'กรอก outcome label หลังติดตามอาการ/การรักษา ใช้เพื่อวิจัย ไม่ใช่การวินิจฉัย'
              : 'Fill outcome labels after follow-up. Research use only, not diagnosis.',
        ]);
      }
    }
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static String buildXGBoostTrainingCsv({
    required List<EvaluationHistoryRecord> records,
    required Map<int, UserProfile> profilesByRecordId,
  }) {
    final featureColumns = xGBoostFeatureColumns;
    final headers = [
      'activity_id',
      'activity',
      'session_id',
      'source_path',
      'source_kind',
      'frame_timestamp_ms',
      'frame_index',
      'image_width',
      'image_height',
      'pose_score',
      'pose_status',
      'error',
      ...featureColumns,
      'label_source',
      'pseudo_reba_score',
      'pseudo_risk_level',
      'training_reba_score',
      'training_risk_level',
      'training_label_source',
      'training_label_match_type',
      'training_matched_session_id',
      'pseudo_reba_trunk_score',
      'pseudo_reba_neck_score',
      'pseudo_reba_leg_score',
      'pseudo_reba_upper_arm_score',
      'pseudo_reba_lower_arm_score',
      'pseudo_reba_wrist_score',
      'pseudo_reba_load_score',
      'pseudo_reba_coupling_score',
      'pseudo_reba_activity_score',
      'training_reba_component_score',
      'training_reba_component_risk_level',
      'training_iso11228_total_score',
      'training_iso11228_risk_level',
      'training_iso11228_label_source',
      'training_iso11228_match_type',
      'training_iso11228_matched_session_id',
      'app_record_id',
      'farmer_id',
      'assessment_date',
      'job_type',
      'primary_method',
      'iso_method',
      'combined_score_app',
      'combined_risk_app',
      'is_worst_pose',
      'motion_source_kind',
      'video_duration_ms',
      'video_sampled_frame_count',
      'video_readable_frame_count',
      'video_sample_rate_fps',
      'video_high_risk_frame_ratio',
      'video_any_segment_risk_frame_ratio',
      'video_estimated_segment_risk_seconds',
      'video_dominant_risk_body_part',
      'video_neck_risk_frame_ratio',
      'video_trunk_risk_frame_ratio',
      'video_upper_arm_risk_frame_ratio',
      'video_lower_arm_risk_frame_ratio',
      'video_wrist_risk_frame_ratio',
      'video_leg_risk_frame_ratio',
      'video_deep_trunk_flexion_ratio',
      'video_estimated_high_risk_seconds',
      'video_estimated_deep_trunk_seconds',
      'video_movement_change_count',
      'video_motion_pattern',
      'neck_flexion_deg',
      'trunk_flexion_deg',
      'upper_arm_flexion_deg',
      'lower_arm_angle_deg',
      'knee_angle_deg',
      'label_confidence',
      'reviewer_id',
      'notes',
    ];

    final rows = <List<Object?>>[headers];
    for (final record in records) {
      final breakdown = record.assessmentBreakdown;
      if (breakdown == null) continue;
      final profile =
          profilesByRecordId[record.id] ?? _profileFromRecord(record);
      final motion = breakdown.motionSummary;
      for (final frame in breakdown.poseFrames) {
        if (frame.jointFeatures.length != featureColumns.length) continue;
        rows.add([
          record.activity?.name ?? record.activityName,
          record.activityName,
          'app-record-${record.id}',
          'app_history_record:${record.id}/image:${frame.imageIndex}',
          motion?.sourceKind ?? 'app_history',
          frame.timestampMs ?? '',
          frame.imageIndex,
          '',
          '',
          _poseScore(frame.jointFeatures),
          'detected',
          '',
          ...frame.jointFeatures,
          'app_pseudo_label_pending_research_review',
          frame.rebaScore,
          frame.riskLevel.name,
          '',
          '',
          '',
          '',
          '',
          frame.rebaInput.trunkScore,
          frame.rebaInput.neckScore,
          frame.rebaInput.legScore,
          frame.rebaInput.upperArmScore,
          frame.rebaInput.lowerArmScore,
          frame.rebaInput.wristScore,
          frame.rebaInput.loadScore,
          frame.rebaInput.couplingScore,
          frame.rebaInput.activityScore,
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          record.id,
          _farmerId(profile, record),
          record.dateTime.toIso8601String(),
          breakdown.ergoInput.jobType.name,
          breakdown.primaryMethod.name,
          breakdown.isoMethod?.name ?? '',
          record.scoreBefore,
          record.riskBefore.name,
          frame.imageIndex == breakdown.worstPoseImageIndex ? 1 : 0,
          motion?.sourceKind ?? '',
          motion?.durationMs ?? '',
          motion?.sampledFrameCount ?? '',
          motion?.readableFrameCount ?? '',
          motion?.sampleRateFps ?? '',
          motion?.highRiskFrameRatio ?? '',
          motion?.anySegmentRiskFrameRatio ?? '',
          motion?.estimatedSegmentRiskSeconds ?? '',
          motion?.dominantRiskBodyPart ?? '',
          motion?.neckRiskFrameRatio ?? '',
          motion?.trunkRiskFrameRatio ?? '',
          motion?.upperArmRiskFrameRatio ?? '',
          motion?.lowerArmRiskFrameRatio ?? '',
          motion?.wristRiskFrameRatio ?? '',
          motion?.legRiskFrameRatio ?? '',
          motion?.deepTrunkFlexionRatio ?? '',
          motion?.estimatedHighRiskSeconds ?? '',
          motion?.estimatedDeepTrunkSeconds ?? '',
          motion?.movementChangeCount ?? '',
          motion?.pattern.name ?? '',
          frame.neckFlexionDeg ?? '',
          frame.trunkFlexionDeg ?? '',
          frame.upperArmFlexionDeg ?? '',
          frame.lowerArmAngleDeg ?? '',
          frame.kneeAngleDeg ?? '',
          '',
          '',
          'Researcher should fill training_* labels before retraining.',
        ]);
      }
    }
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static Map<String, List<EvaluationHistoryRecord>> _groupByFarmer(
    List<EvaluationHistoryRecord> records,
  ) {
    final grouped = <String, List<EvaluationHistoryRecord>>{};
    for (final record in records) {
      final key = record.farmerProfileId ??
          record.farmerId ??
          record.farmerName ??
          'unknown_farmer';
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return grouped;
  }

  static UserProfile _profileFromRecord(EvaluationHistoryRecord record) {
    return UserProfile(
      profileId: record.farmerProfileId ?? '',
      farmerId: record.farmerId ?? '',
      name: record.farmerName ?? '',
      role: record.farmerRole ?? '',
      location: record.farmerLocation ?? '',
    );
  }

  static String _windowId(
    UserProfile profile,
    List<EvaluationHistoryRecord> window,
  ) {
    final farmerId = _farmerId(profile, window.last).replaceAll(' ', '_');
    return '${farmerId}_${_dateOnly(window.first.dateTime)}_'
        '${_dateOnly(window.last.dateTime)}_${window.first.id}-${window.last.id}';
  }

  static String _farmerId(
    UserProfile profile,
    EvaluationHistoryRecord record,
  ) {
    if (profile.farmerId.isNotEmpty) return profile.farmerId;
    if ((record.farmerId ?? '').isNotEmpty) return record.farmerId!;
    if (profile.profileId.isNotEmpty) return profile.profileId;
    if ((record.farmerProfileId ?? '').isNotEmpty) {
      return record.farmerProfileId!;
    }
    return 'unknown_farmer';
  }

  static String _uniqueText(Iterable<String> values) {
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) seen.add(trimmed);
    }
    return seen.isEmpty ? '-' : seen.join(';');
  }

  static String _dateOnly(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  static Object _poseScore(List<double> features) {
    if (features.length < 3) return '';
    final scores = <double>[];
    for (var index = 2; index < features.length; index += 3) {
      scores.add(features[index]);
    }
    if (scores.isEmpty) return '';
    final average =
        scores.fold<double>(0, (sum, value) => sum + value) / scores.length;
    return average.toStringAsFixed(4);
  }

  static String _csvRow(List<Object?> row) {
    return row.map((value) {
      final text = (value ?? '').toString();
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }
}
