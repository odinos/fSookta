import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/economic_impact_models.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/assessment_export_service.dart';

void main() {
  test('builds Excel-compatible CSV with Thai summary fields', () {
    const before = ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: 8,
      userScore: 8,
      userScoreColor: 0xFFFF5252,
      limitValue: 15,
      suggestionKey: 'sugg_reba_high',
      economicLoss: 12000,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
    );
    const after = ErgoResult(
      riskLevel: RiskLevel.medium,
      techScore: 6,
      userScore: 6,
      userScoreColor: 0xFFFFF176,
      limitValue: 15,
      suggestionKey: 'sugg_reba_med',
      economicLoss: 8000,
      bodyPartRisks: {BodyPart.trunk: RiskLevel.medium},
    );

    final csv = AssessmentExportService.buildExcelCsv(
      bundle: const AssessmentBundle(
        activity: SooktaActivity.harvesting,
        activityName: 'การเก็บเกี่ยว',
        jobType: JobType.reba,
        before: before,
        after: after,
        selectedSuggestionKeys: ['act_avoid_bend'],
        breakdown: AssessmentBreakdown(
          primaryMethod: AssessmentMethod.reba,
          rebaInput: RebaInputData(
            trunkScore: 4,
            neckScore: 2,
            legScore: 2,
            upperArmScore: 3,
            lowerArmScore: 2,
            wristScore: 2,
            trunkTwist: true,
            loadScore: 1,
            couplingScore: 1,
            activityScore: 1,
          ),
          rebaResult: before,
          ergoInput: ErgoInputData(
            jobType: JobType.reba,
            toolId: 'basket_mid_10_15kg',
            toolLabelTh: 'ตะกร้ากลาง 10-15 กก.',
            toolLabelEn: 'Medium basket 10-15 kg',
            toolWeightKg: 12.5,
            toolWeightBandCode: 3,
            loadWeight: 12.5,
          ),
          poseFrames: [
            PoseRebaFrameAnalysis(
              imageIndex: 1,
              timestampMs: 1200,
              rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
              rebaScore: 8,
              riskLevel: RiskLevel.high,
              trunkFlexionDeg: 66,
            ),
          ],
          worstPoseImageIndex: 1,
          motionSummary: MotionAnalysisSummary(
            sourceKind: 'video_gallery',
            durationMs: 9000,
            sampledFrameCount: 8,
            readableFrameCount: 8,
            sampleRateFps: 0.89,
            highRiskFrameCount: 5,
            highRiskFrameRatio: 0.625,
            deepTrunkFlexionFrameCount: 4,
            deepTrunkFlexionRatio: 0.5,
            estimatedHighRiskSeconds: 5.625,
            estimatedDeepTrunkSeconds: 4.5,
            movementChangeCount: 2,
            pattern: MotionPattern.repeatedRiskMovement,
            anySegmentRiskFrameCount: 6,
            anySegmentRiskFrameRatio: 0.75,
            estimatedSegmentRiskSeconds: 6.75,
            neckRiskFrameCount: 2,
            neckRiskFrameRatio: 0.25,
            trunkRiskFrameCount: 6,
            trunkRiskFrameRatio: 0.75,
            upperArmRiskFrameCount: 3,
            upperArmRiskFrameRatio: 0.375,
            lowerArmRiskFrameCount: 1,
            lowerArmRiskFrameRatio: 0.125,
            wristRiskFrameCount: 1,
            wristRiskFrameRatio: 0.125,
            legRiskFrameCount: 2,
            legRiskFrameRatio: 0.25,
            dominantRiskBodyPart: 'trunk',
            maxTrunkFlexionDeg: 66,
            avgTrunkFlexionDeg: 44,
          ),
        ),
      ),
      profile: const UserProfile(
        farmerId: 'FARM-001',
        name: 'สมหญิง',
        role: 'ชาวสวน',
        location: 'สวนตัวอย่าง',
        weight: '62',
        height: '158',
        incomePerYear: '120000',
      ),
      selectedSuggestions: const ['หลีกเลี่ยงการก้มหลังค้างนาน'],
      beforeImpact: const EconomicImpactBreakdown(
        bodyTreatmentCost: 100,
        medicalVisitCost: 200,
        medicineAndSuppliesCost: 300,
        travelCost: 400,
        lostIncome: 500,
        reducedIncome: 600,
        compensationCost: 0,
        bodyImpacts: [],
      ),
      afterImpact: const EconomicImpactBreakdown(
        bodyTreatmentCost: 50,
        medicalVisitCost: 100,
        medicineAndSuppliesCost: 150,
        travelCost: 200,
        lostIncome: 250,
        reducedIncome: 300,
        compensationCost: 0,
        bodyImpacts: [],
      ),
    );

    expect(csv.startsWith('\uFEFF'), isTrue);
    expect(csv, contains('การเก็บเกี่ยว'));
    expect(csv, contains('Worksheet Template Data Input for Application'));
    expect(csv, contains('Farmer ID'));
    expect(csv, contains('FARM-001'));
    expect(csv, contains('REBA Score'));
    expect(csv, contains('ISO 11228 Risk Level'));
    expect(csv, contains('BMI'));
    expect(csv, contains('น้ำหนักมากกว่าเกณฑ์'));
    expect(csv, contains('Tool Used'));
    expect(csv, contains('ตะกร้ากลาง 10-15 กก.'));
    expect(csv, contains('Productivity Loss (THB)'));
    expect(csv, contains('ค่าพบแพทย์/คลินิก'));
    expect(csv, contains('รายละเอียดการประเมิน REBA/ISO11228'));
    expect(csv, contains('สรุปการเคลื่อนไหวจากวิดีโอ'));
    expect(csv, contains('video_gallery'));
    expect(csv, contains('ส่วนร่างกายเด่น'));
    expect(csv, contains('ลำตัว/หลัง'));
    expect(csv, contains('สัดส่วนต้นแขนเสี่ยง'));
    expect(csv, contains('Timestamp (ms)'));
    expect(csv, contains('ข้อมูลย่อย REBA'));
    expect(csv, contains('ข้อมูลย่อย ISO11228'));
    expect(csv, contains('หลีกเลี่ยงการก้มหลังค้างนาน'));
  });

  test('builds history export CSV from saved record', () {
    final csv = AssessmentExportService.buildHistoryRecordCsv(
      record: EvaluationHistoryRecord(
        id: 7,
        activity: SooktaActivity.pruning,
        activityName: 'การตัดแต่งกิ่ง',
        dateTime: DateTime(2026, 5, 24, 8, 30),
        scoreBefore: 8,
        scoreAfter: 6,
        riskBefore: RiskLevel.high,
        riskAfter: RiskLevel.medium,
        economicLoss: 12000,
        moneySaved: 4000,
        selectedSuggestions: const ['ใช้ด้ามต่อเพื่อลดการยกแขนสูง'],
        bodyPartRisks: const {BodyPart.arms: RiskLevel.high},
        assessmentBreakdown: const AssessmentBreakdown(
          primaryMethod: AssessmentMethod.iso11228PushPull,
          rebaInput: RebaInputData(),
          rebaResult: ErgoResult(
            riskLevel: RiskLevel.medium,
            techScore: 6,
            userScore: 6,
            userScoreColor: 0xFFFFF176,
            limitValue: 15,
            suggestionKey: 'sugg_reba_med',
          ),
          ergoInput: ErgoInputData(
            jobType: JobType.pushPull,
            toolId: 'machete_0_320kg',
            toolLabelTh: 'มีด/พร้า (0.320 กก.)',
            toolLabelEn: 'Machete (0.320 kg)',
            toolWeightKg: 0.320,
            toolWeightBandCode: 1,
            initialForce: 30,
            sustainForce: 12,
          ),
          isoMethod: AssessmentMethod.iso11228PushPull,
          isoResult: ErgoResult(
            riskLevel: RiskLevel.high,
            techScore: 1.5,
            userScore: 8,
            userScoreColor: 0xFFFF5252,
            limitValue: 20,
            suggestionKey: 'sugg_push_pull_high',
          ),
        ),
      ),
      profile: const UserProfile(
        farmerId: 'FARM-002',
        name: 'สมชาย',
        role: 'เจ้าของสวน',
        location: 'แปลงเหนือ',
      ),
    );

    expect(csv, contains('เลขประเมิน'));
    expect(csv, contains('การตัดแต่งกิ่ง'));
    expect(csv, contains('FARM-002'));
    expect(csv, contains('Maintenance / Pruning'));
    expect(csv, contains('ผลกระทบหลังปรับโดยประมาณ'));
    expect(csv, contains('ISO11228-2'));
    expect(csv, contains('มีด/พร้า (0.320 กก.)'));
    expect(csv, contains('แรงเริ่มต้นดัน/ลาก'));
    expect(csv, contains('5280'));
    expect(csv, contains('สูตรคำนวณผลกระทบหลังปรับ'));
  });

  test('builds all-farmer worksheet CSV for research staff', () {
    final record = EvaluationHistoryRecord(
      id: 9,
      farmerProfileId: 'profile-a',
      farmerId: 'FARM-009',
      farmerName: 'สมปอง',
      farmerRole: 'ผู้ช่วยเก็บเกี่ยว',
      farmerLocation: 'แปลงใต้',
      farmerAge: '51',
      farmerGender: 'Male',
      farmerWeight: '70',
      farmerHeight: '165',
      farmerBmi: 25.7,
      farmerBmiCategory: 'overweight',
      activity: SooktaActivity.transport,
      activityName: 'การขนย้ายผลผลิต',
      dateTime: DateTime(2026, 5, 24),
      scoreBefore: 7,
      scoreAfter: 5,
      riskBefore: RiskLevel.high,
      riskAfter: RiskLevel.medium,
      economicLoss: 9000,
      moneySaved: 2500,
      selectedSuggestions: const ['ใช้รถเข็น'],
      bodyPartRisks: const {
        BodyPart.trunk: RiskLevel.high,
        BodyPart.wrists: RiskLevel.high,
      },
      assessmentBreakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.iso11228Lifting,
        rebaInput: RebaInputData(trunkScore: 3),
        rebaResult: ErgoResult(
          riskLevel: RiskLevel.medium,
          techScore: 5,
          userScore: 5,
          userScoreColor: 0xFFFFF176,
          limitValue: 15,
          suggestionKey: 'sugg_reba_med',
        ),
        ergoInput: ErgoInputData(
          jobType: JobType.lifting,
          toolId: 'basket_25_27kg',
          toolLabelTh: 'ตะกร้าผลผลิต 25-27 กก.',
          toolLabelEn: 'Produce basket 25-27 kg',
          toolWeightKg: 26,
          toolWeightBandCode: 6,
          loadWeight: 15,
          transportDistance: 8,
          liftFrequency: 2,
          durationHours: 1.5,
        ),
        isoMethod: AssessmentMethod.iso11228Lifting,
        isoResult: ErgoResult(
          riskLevel: RiskLevel.high,
          techScore: 1.4,
          userScore: 7,
          userScoreColor: 0xFFFF5252,
          limitValue: 10,
          suggestionKey: 'sugg_lifting_high',
        ),
      ),
    );

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: [record],
      profilesByRecordId: const {
        9: UserProfile(
          profileId: 'profile-a',
          farmerId: 'FARM-009',
          name: 'สมปอง',
          role: 'ผู้ช่วยเก็บเกี่ยว',
          location: 'แปลงใต้',
          weight: '70',
          height: '165',
        ),
      },
    );

    expect(csv, contains('Record ID'));
    expect(csv, contains('FARM-009'));
    expect(csv, contains('การขนย้ายผลผลิต'));
    expect(csv, contains('BMI Category'));
    expect(csv, contains('ตะกร้าผลผลิต 25-27 กก.'));
    expect(csv, contains('Manual Handling Weight (kg)'));
    expect(csv, contains('ใช้รถเข็น'));
    expect(csv, contains('time_on_task_seconds'));
    expect(csv, contains('completion_status'));
    expect(csv, contains('assistance_required'));
    expect(csv, contains('error_count'));
    expect(csv, contains('expert_REBA'));
    expect(csv, contains('expert_risk_level'));
    expect(csv, contains('expert_assessment_date'));
    expect(csv, contains('expert_comments'));

    final row = _firstAllHistoryDataRow(csv);
    expect(row['wrist_risk'], 'ความเสี่ยงสูง');
    expect(
      row['upper_limb_risk'],
      'ความเสี่ยงสูง',
      reason:
          'Upper limb risk must include wrist risk for NMQ body-region export.',
    );
  });

  test('exports trend level from the latest seven before-improvement records',
      () {
    final records = [
      for (var index = 1; index <= 7; index += 1)
        EvaluationHistoryRecord(
          id: index,
          farmerProfileId: 'profile-trend',
          farmerId: 'FARM-TREND',
          activity: SooktaActivity.harvesting,
          activityName: 'Harvesting',
          dateTime: DateTime(2026, 6, index, 8),
          scoreBefore: index <= 5 ? 8 : 5,
          scoreAfter: index <= 4 ? 7 : 4,
          riskBefore: index <= 5 ? RiskLevel.high : RiskLevel.medium,
          riskAfter: index <= 4 ? RiskLevel.high : RiskLevel.medium,
          economicLoss: 10000,
          moneySaved: 2000,
          selectedSuggestions: const ['Use cart'],
          bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
        ),
    ];

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: records,
      profilesByRecordId: const {
        7: UserProfile(
          profileId: 'profile-trend',
          farmerId: 'FARM-TREND',
          name: 'Trend Farmer',
        ),
      },
      thai: false,
    );

    final row = _allHistoryDataRows(csv).last;
    expect(row['trend_high_risk_count'], '5');
    expect(row['trend_level'], 'High');
  });

  test('exports persisted usability and expert-assessment values', () {
    final record = EvaluationHistoryRecord.fromJson({
      'id': 42,
      'farmerProfileId': 'profile-expert',
      'farmerId': 'FARM-042',
      'activity': 'harvesting',
      'activityName': 'Harvesting',
      'dateTime': '2026-06-24T10:30:00',
      'scoreBefore': 8,
      'scoreAfter': 6,
      'riskBefore': 'high',
      'riskAfter': 'medium',
      'economicLoss': 12000,
      'moneySaved': 4000,
      'selectedSuggestions': ['Use cart'],
      'bodyPartRisks': {'trunk': 'high'},
      'timeOnTaskSeconds': 184,
      'completionStatus': 'completed',
      'assistanceRequired': true,
      'errorCount': 1,
      'expertReba': 9,
      'expertRiskLevel': 'veryHigh',
      'expertAssessmentDate': '2026-06-24T14:15:00',
      'expertComments': 'Expert reviewed from field photo',
      'photoId': 'photo-42-main',
      'photoTimestamp': '2026-06-24T10:29:58',
    });

    expect(record.toJson()['photoId'], 'photo-42-main');
    expect(
      record.toJson()['photoTimestamp'],
      '2026-06-24T10:29:58.000',
    );

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: [record],
      profilesByRecordId: const {
        42: UserProfile(
          profileId: 'profile-expert',
          farmerId: 'FARM-042',
          name: 'Expert Farmer',
        ),
      },
      thai: false,
    );

    final row = _firstAllHistoryDataRow(csv);
    expect(row['time_on_task_seconds'], '184');
    expect(row['completion_status'], 'completed');
    expect(row['assistance_required'], 'true');
    expect(row['error_count'], '1');
    expect(row['expert_REBA'], '9');
    expect(row['expert_risk_level'], 'Very high');
    expect(row['expert_assessment_date'], '2026-06-24T14:15:00.000');
    expect(row['expert_comments'], 'Expert reviewed from field photo');
    expect(row['photo_id'], 'photo-42-main');
    expect(row['photo_timestamp'], '2026-06-24T10:29:58.000');
  });

  test('exports separate REBA and ISO after scores from after breakdown', () {
    final record = EvaluationHistoryRecord(
      id: 88,
      farmerProfileId: 'profile-after',
      farmerId: 'FARM-AFTER',
      activity: SooktaActivity.transport,
      activityName: 'Transport',
      dateTime: DateTime(2026, 6, 25, 9),
      scoreBefore: 9,
      scoreAfter: 5,
      riskBefore: RiskLevel.veryHigh,
      riskAfter: RiskLevel.medium,
      economicLoss: 15000,
      moneySaved: 5000,
      selectedSuggestions: const ['Use cart'],
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.veryHigh},
      assessmentBreakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.rebaIsoCombined,
        rebaInput: RebaInputData(),
        rebaResult: ErgoResult(
          riskLevel: RiskLevel.veryHigh,
          techScore: 9,
          userScore: 9,
          userScoreColor: 0xFFFF5252,
          limitValue: 15,
          suggestionKey: 'sugg_reba_high',
        ),
        ergoInput: ErgoInputData(jobType: JobType.lifting),
        isoMethod: AssessmentMethod.iso11228Lifting,
        isoResult: ErgoResult(
          riskLevel: RiskLevel.high,
          techScore: 8,
          userScore: 8,
          userScoreColor: 0xFFFF8A65,
          limitValue: 25,
          suggestionKey: 'sugg_iso_high',
        ),
      ),
      afterAssessmentBreakdown: const AssessmentBreakdown(
        primaryMethod: AssessmentMethod.rebaIsoCombined,
        rebaInput: RebaInputData(),
        rebaResult: ErgoResult(
          riskLevel: RiskLevel.medium,
          techScore: 4,
          userScore: 4,
          userScoreColor: 0xFFFFF176,
          limitValue: 15,
          suggestionKey: 'sugg_reba_med',
        ),
        ergoInput: ErgoInputData(jobType: JobType.lifting),
        isoMethod: AssessmentMethod.iso11228Lifting,
        isoResult: ErgoResult(
          riskLevel: RiskLevel.low,
          techScore: 3,
          userScore: 3,
          userScoreColor: 0xFF8BC34A,
          limitValue: 25,
          suggestionKey: 'sugg_iso_low',
        ),
      ),
    );

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: [record],
      profilesByRecordId: const {
        88: UserProfile(
          profileId: 'profile-after',
          farmerId: 'FARM-AFTER',
          name: 'After Farmer',
        ),
      },
      thai: false,
    );

    final row = _firstAllHistoryDataRow(csv);
    expect(row['REBA_before'], '9');
    expect(row['ISO_before'], '8');
    expect(row['REBA_after'], '4');
    expect(row['REBA_risk_after'], 'Medium');
    expect(row['ISO_after'], '3');
    expect(row['ISO_risk_after'], 'Low');
    expect(row['REBA_reduction'], '5');
    expect(row['REBA_reduction_percent'], '56%');
  });
}

Map<String, String> _firstAllHistoryDataRow(String csv) {
  return _allHistoryDataRows(csv).first;
}

List<Map<String, String>> _allHistoryDataRows(String csv) {
  final rows = csv
      .replaceFirst('\uFEFF', '')
      .trimRight()
      .split('\n')
      .map(_parseCsvLine)
      .toList();
  final headers = rows.first;
  return rows.skip(1).map((row) {
    return {
      for (var index = 0; index < headers.length; index += 1)
        headers[index]: index < row.length ? row[index] : '',
    };
  }).toList();
}

List<String> _parseCsvLine(String line) {
  final cells = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var index = 0; index < line.length; index += 1) {
    final char = line[index];
    if (char == '"') {
      final nextIsQuote = index + 1 < line.length && line[index + 1] == '"';
      if (quoted && nextIsQuote) {
        buffer.write('"');
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      cells.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  cells.add(buffer.toString());
  return cells;
}
