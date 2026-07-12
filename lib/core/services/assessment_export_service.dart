import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/app_state.dart';
import '../../app/build_info.dart';
import '../models/assessment_session.dart';
import '../models/assessment_reference_sources.dart';
import '../models/economic_impact_models.dart';
import '../models/evaluation_models.dart';
import 'economic_impact_service.dart';
import 'ergo_calculator.dart';

class AssessmentExportService {
  const AssessmentExportService._();

  static Future<File> exportExcelCsv({
    required AssessmentBundle bundle,
    required UserProfile profile,
    required List<String> selectedSuggestions,
    required EconomicImpactBreakdown beforeImpact,
    required EconomicImpactBreakdown afterImpact,
    EvaluationHistoryRecord? record,
    bool thai = true,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final file = File('${directory.path}/sookta_assessment_$timestamp.csv');
    return file.writeAsString(
      buildExcelCsv(
        bundle: bundle,
        profile: profile,
        selectedSuggestions: selectedSuggestions,
        beforeImpact: beforeImpact,
        afterImpact: afterImpact,
        record: record,
        thai: thai,
      ),
      flush: true,
    );
  }

  static Future<File> exportHistoryRecordCsv({
    required EvaluationHistoryRecord record,
    required UserProfile profile,
    bool thai = true,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final file =
        File('${directory.path}/sookta_history_${record.id}_$timestamp.csv');
    return file.writeAsString(
      buildHistoryRecordCsv(record: record, profile: profile, thai: thai),
      flush: true,
    );
  }

  static Future<File> exportAllHistoryCsv({
    required List<EvaluationHistoryRecord> records,
    required Map<int, UserProfile> profilesByRecordId,
    bool thai = true,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '');
    final file = File('${directory.path}/sookta_all_farmers_$timestamp.csv');
    return file.writeAsString(
      buildAllHistoryCsv(
        records: records,
        profilesByRecordId: profilesByRecordId,
        thai: thai,
      ),
      flush: true,
    );
  }

  static String buildExcelCsv({
    required AssessmentBundle bundle,
    required UserProfile profile,
    required List<String> selectedSuggestions,
    required EconomicImpactBreakdown beforeImpact,
    required EconomicImpactBreakdown afterImpact,
    EvaluationHistoryRecord? record,
    bool thai = true,
  }) {
    final generatedAt = DateTime.now();
    final impactComparison = EconomicImpactService.compareBeforeAfter(
      beforeImpact: beforeImpact.totalCost,
      beforeScore: bundle.before.userScore,
      afterScore: bundle.after.userScore,
    );
    final rows = <List<Object?>>[
      [thai ? 'หัวข้อ' : 'Field', thai ? 'ข้อมูล' : 'Value'],
      [thai ? 'เลขประเมิน' : 'Record ID', record?.id ?? '-'],
      [
        thai ? 'วันที่สร้างไฟล์' : 'File generated at',
        generatedAt.toIso8601String()
      ],
      [
        thai ? 'วันที่ประเมิน' : 'Assessment date',
        (record?.dateTime ?? DateTime.now()).toIso8601String(),
      ],
      [
        thai ? 'เวอร์ชันแอปที่ใช้ประเมิน' : 'Assessment app version',
        record?.appVersion ?? SooktaBuildInfo.label,
      ],
      [thai ? 'รหัสผู้เข้าร่วมวิจัย' : 'Farmer ID', profile.farmerId],
      [thai ? 'กิจกรรม' : 'Activity', bundle.activityName],
      [
        thai ? 'ช่วงงาน' : 'Activity stage',
        bundle.activity.stageLabel(thai: thai),
      ],
      [thai ? 'ประเภทงาน' : 'Job type', bundle.jobType.name],
      [thai ? 'ชื่อผู้ใช้' : 'Name', profile.name],
      [thai ? 'บทบาท/หน้าที่' : 'Role', profile.role],
      [thai ? 'พื้นที่ทำงาน' : 'Work Space', profile.location],
      [thai ? 'อายุ' : 'Age', profile.age],
      [thai ? 'เพศ' : 'Gender', profile.gender],
      [thai ? 'น้ำหนัก' : 'Weight', profile.weight],
      [thai ? 'ส่วนสูง' : 'Height', profile.height],
      ['BMI', _bmiDisplay(profile, record, thai)],
      [thai ? 'หมวด BMI' : 'BMI category', _bmiCategory(profile, record, thai)],
      [thai ? 'รายได้เฉลี่ยต่อปี' : 'Annual income', profile.incomePerYear],
      [],
      [thai ? 'ผลก่อนและหลัง' : 'Before and after'],
      [thai ? 'คะแนนก่อนปรับ' : 'Before score', bundle.before.userScore],
      [
        thai ? 'ระดับก่อนปรับ' : 'Before risk',
        _risk(bundle.before.riskLevel, thai)
      ],
      [thai ? 'คะแนนหลังปรับ' : 'After score', bundle.after.userScore],
      [
        thai ? 'ระดับหลังปรับ' : 'After risk',
        _risk(bundle.after.riskLevel, thai)
      ],
      ..._worksheetRows(
        farmerId: profile.farmerId,
        dateTime: record?.dateTime ?? DateTime.now(),
        activityStage: bundle.activity.stageLabel(thai: false),
        specificTask: bundle.activityName,
        breakdown: bundle.breakdown,
        bodyPartRisks: bundle.before.bodyPartRisks,
        impact: beforeImpact,
        selectedSuggestions: selectedSuggestions,
        thai: thai,
      ),
      ..._assessmentBreakdownRows(bundle.breakdown, thai),
      [
        thai ? 'ผลกระทบก่อนปรับ (บาท)' : 'Before impact (THB)',
        impactComparison.beforeImpact,
      ],
      [
        thai ? 'ผลกระทบหลังปรับ (บาท)' : 'After impact (THB)',
        impactComparison.afterImpact,
      ],
      [
        thai ? 'ผลกระทบที่ลดลง (บาท)' : 'Reduced impact (THB)',
        impactComparison.savedAmount,
      ],
      [
        thai ? 'สูตรคำนวณผลกระทบหลังปรับ' : 'After-impact formula',
        thai
            ? 'ผลกระทบหลังปรับ = ผลกระทบก่อนปรับ × (1 - 0.28 × คะแนนที่ลดลง), คะแนนที่ลดลงในไฟล์นี้ ${impactComparison.effectiveScoreReduction} จุด'
            : 'After impact = before impact × (1 - 0.28 × score reduction), score reduction in this file ${impactComparison.effectiveScoreReduction} point(s)',
      ],
      [],
      [thai ? 'รายละเอียดค่าใช้จ่าย' : 'Economic impact details'],
      [
        thai ? 'รายการ' : 'Item',
        thai ? 'ก่อนปรับ' : 'Before',
        thai ? 'หลังปรับ' : 'After'
      ],
      [
        thai ? 'ค่ารักษาตามส่วนร่างกาย' : 'Body-area treatment cost',
        beforeImpact.bodyTreatmentCost,
        afterImpact.bodyTreatmentCost,
      ],
      [
        thai ? 'ค่าพบแพทย์/คลินิก' : 'Medical visit cost',
        beforeImpact.medicalVisitCost,
        afterImpact.medicalVisitCost,
      ],
      [
        thai ? 'ค่ายาและเวชภัณฑ์' : 'Medicine and supplies',
        beforeImpact.medicineAndSuppliesCost,
        afterImpact.medicineAndSuppliesCost,
      ],
      [
        thai ? 'ค่าเดินทาง' : 'Travel',
        beforeImpact.travelCost,
        afterImpact.travelCost
      ],
      [
        thai ? 'รายได้ที่สูญเสีย' : 'Lost income',
        beforeImpact.lostIncome,
        afterImpact.lostIncome,
      ],
      [
        thai ? 'รายได้ที่ลดลง' : 'Reduced income',
        beforeImpact.reducedIncome,
        afterImpact.reducedIncome,
      ],
      [],
      [thai ? 'ตำแหน่งร่างกายที่เสี่ยง' : 'Risky body parts'],
      [thai ? 'ส่วนร่างกาย' : 'Body part', thai ? 'ระดับ' : 'Risk level'],
      ...bundle.before.bodyPartRisks.entries.map(
        (entry) => [_bodyPart(entry.key, thai), _risk(entry.value, thai)],
      ),
      [],
      [thai ? 'คำแนะนำที่เลือก' : 'Selected recommendations'],
      ...selectedSuggestions.map((suggestion) => [suggestion]),
      [],
      [
        thai ? 'หมายเหตุ' : 'Note',
        thai
            ? 'ไฟล์นี้เป็น CSV ที่เปิดด้วย Excel ได้ ใช้เพื่อการติดตามงานวิจัย ไม่ใช่ใบรับรองทางการแพทย์'
            : 'This CSV opens in Excel and is for research follow-up, not medical certification.',
      ],
      ...AssessmentReferenceSources.csvRows(thai: thai),
    ];
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static String buildHistoryRecordCsv({
    required EvaluationHistoryRecord record,
    required UserProfile profile,
    bool thai = true,
  }) {
    final generatedAt = DateTime.now();
    final impactComparison = EconomicImpactService.compareBeforeAfter(
      beforeImpact: record.economicLoss,
      beforeScore: record.scoreBefore,
      afterScore: record.scoreAfter,
    );
    final beforeImpact = EconomicImpactService.estimate(
      overallRisk: record.riskBefore,
      dailyIncome: _dailyIncome(profile),
      bodyPartRisks: record.bodyPartRisks,
    );
    final rows = <List<Object?>>[
      [thai ? 'หัวข้อ' : 'Field', thai ? 'ข้อมูล' : 'Value'],
      [thai ? 'เลขประเมิน' : 'Record ID', record.id],
      [
        thai ? 'วันที่สร้างไฟล์' : 'File generated at',
        generatedAt.toIso8601String()
      ],
      [
        thai ? 'วันที่ประเมิน' : 'Assessment date',
        record.dateTime.toIso8601String()
      ],
      [
        thai ? 'เวอร์ชันแอปที่ใช้ประเมิน' : 'Assessment app version',
        record.appVersion ?? '-',
      ],
      [thai ? 'รหัสผู้เข้าร่วมวิจัย' : 'Farmer ID', profile.farmerId],
      [thai ? 'กิจกรรม' : 'Activity', record.activityName],
      [
        thai ? 'ช่วงงาน' : 'Activity stage',
        record.activity?.stageLabel(thai: thai) ?? '-',
      ],
      [thai ? 'ชื่อผู้ใช้' : 'Name', profile.name],
      [thai ? 'บทบาท/หน้าที่' : 'Role', profile.role],
      [thai ? 'พื้นที่ทำงาน' : 'Work Space', profile.location],
      [thai ? 'อายุ' : 'Age', profile.age],
      [thai ? 'เพศ' : 'Gender', profile.gender],
      [thai ? 'น้ำหนัก' : 'Weight', profile.weight],
      [thai ? 'ส่วนสูง' : 'Height', profile.height],
      ['BMI', _bmiDisplay(profile, record, thai)],
      [thai ? 'หมวด BMI' : 'BMI category', _bmiCategory(profile, record, thai)],
      [thai ? 'รายได้เฉลี่ยต่อปี' : 'Annual income', profile.incomePerYear],
      [],
      [thai ? 'ผลก่อนและหลัง' : 'Before and after'],
      [thai ? 'คะแนนก่อนปรับ' : 'Before score', record.scoreBefore],
      [thai ? 'ระดับก่อนปรับ' : 'Before risk', _risk(record.riskBefore, thai)],
      [thai ? 'คะแนนหลังปรับ' : 'After score', record.scoreAfter],
      [thai ? 'ระดับหลังปรับ' : 'After risk', _risk(record.riskAfter, thai)],
      [
        thai ? 'ผลกระทบก่อนปรับ (บาท)' : 'Before impact (THB)',
        record.economicLoss,
      ],
      [
        thai
            ? 'ผลกระทบหลังปรับโดยประมาณ (บาท)'
            : 'Estimated after impact (THB)',
        impactComparison.afterImpact,
      ],
      [
        thai ? 'ผลกระทบที่ลดลง (บาท)' : 'Reduced impact (THB)',
        impactComparison.savedAmount,
      ],
      [
        thai ? 'สูตรคำนวณผลกระทบหลังปรับ' : 'After-impact formula',
        thai
            ? 'ผลกระทบหลังปรับ = ผลกระทบก่อนปรับ × (1 - 0.28 × คะแนนที่ลดลง), คะแนนที่ลดลงในไฟล์นี้ ${impactComparison.effectiveScoreReduction} จุด'
            : 'After impact = before impact × (1 - 0.28 × score reduction), score reduction in this file ${impactComparison.effectiveScoreReduction} point(s)',
      ],
      ..._worksheetRows(
        farmerId: profile.farmerId,
        dateTime: record.dateTime,
        activityStage: record.activity?.stageLabel(thai: false) ?? '-',
        specificTask: record.activityName,
        breakdown: record.assessmentBreakdown,
        bodyPartRisks: record.bodyPartRisks,
        impact: beforeImpact,
        selectedSuggestions: record.selectedSuggestions,
        thai: thai,
      ),
      if (record.aiRiskPercent != null) ...[
        [],
        [thai ? 'สัญญาณช่วยเฝ้าระวัง' : 'Posture awareness signal'],
        [thai ? 'เปอร์เซ็นต์' : 'Percent', record.aiRiskPercent],
        [thai ? 'ระดับ AI' : 'AI level', record.aiAlertLevel?.name ?? '-'],
        [thai ? 'แหล่งโมเดล' : 'Model source', record.aiModelSource ?? '-'],
      ],
      ..._assessmentBreakdownRows(record.assessmentBreakdown, thai),
      [],
      [thai ? 'ตำแหน่งร่างกายที่เสี่ยง' : 'Risky body parts'],
      [thai ? 'ส่วนร่างกาย' : 'Body part', thai ? 'ระดับ' : 'Risk level'],
      ...record.bodyPartRisks.entries.map(
        (entry) => [_bodyPart(entry.key, thai), _risk(entry.value, thai)],
      ),
      [],
      [thai ? 'คำแนะนำที่เลือก' : 'Selected recommendations'],
      ...record.selectedSuggestions.map((suggestion) => [suggestion]),
      [],
      [
        thai ? 'หมายเหตุ' : 'Note',
        thai
            ? 'ไฟล์นี้ส่งออกจากหน้าประวัติ เป็น CSV ที่เปิดด้วย Excel ได้ ใช้เพื่อการติดตามงานวิจัย ไม่ใช่ใบรับรองทางการแพทย์'
            : 'This history export is a CSV that opens in Excel and is for research follow-up, not medical certification.',
      ],
      ...AssessmentReferenceSources.csvRows(thai: thai),
    ];
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static String buildAllHistoryCsv({
    required List<EvaluationHistoryRecord> records,
    required Map<int, UserProfile> profilesByRecordId,
    bool thai = true,
  }) {
    final generatedAt = DateTime.now().toIso8601String();
    final rows = <List<Object?>>[
      [
        'Export Generated At',
        'export_schema_version',
        'assessment_reference_sources',
        'assessment_scope_note',
        'calculation_standard_note',
        'Record ID',
        'App Version',
        'Farmer ID',
        thai ? 'ชื่อผู้ใช้' : 'Name',
        thai ? 'บทบาท/หน้าที่' : 'Role',
        thai ? 'พื้นที่ทำงาน' : 'Work Space',
        'Age',
        'Gender',
        'Weight (kg)',
        'Height (cm)',
        'BMI',
        'BMI Category',
        'Date of data entry',
        'Activity Stage',
        'Specific Task',
        'Posture Description',
        'REBA Score',
        'ISO 11228 Risk Level',
        'Tool Used',
        'Tool Weight (kg)',
        'Tool Weight Code',
        'Manual Handling Weight (kg)',
        'Manual Handling Distance (m)',
        'Frequency per hour',
        'Duration (minutes)',
        'Work days per week',
        'MSD Symptom Location',
        'MSD Symptom Severity',
        'Medical Cost (THB)',
        'Lost Workdays',
        'Productivity Loss (THB)',
        'Before Score',
        'After Score',
        'Before Risk',
        'After Risk',
        'Before Impact (THB)',
        'After Impact (THB)',
        'Estimated Saved (THB)',
        'Economic Impact Formula',
        'User Feedback Notes',
        'transaction_id',
        'user_id',
        'assessment_date',
        'assessment_time',
        'task_type',
        'REBA_before',
        'REBA_risk_before',
        'ISO_before',
        'ISO_risk_before',
        'load_before',
        'frequency_before',
        'duration_before',
        'REBA_after',
        'REBA_risk_after',
        'ISO_after',
        'ISO_risk_after',
        'REBA_reduction',
        'REBA_reduction_percent',
        'trend_REBA_average',
        'trend_REBA_maximum',
        'trend_high_risk_count',
        'trend_level',
        'trend_direction',
        'neck_risk',
        'shoulder_risk',
        'upper_limb_risk',
        'wrist_risk',
        'back_risk',
        'knee_risk',
        'photo_id',
        'photo_timestamp',
        'time_on_task_seconds',
        'completion_status',
        'assistance_required',
        'error_count',
        'expert_REBA',
        'expert_risk_level',
        'expert_assessment_date',
        'expert_comments',
      ],
      for (final record in records)
        _worksheetFlatRow(
          record: record,
          profile: profilesByRecordId[record.id] ?? const UserProfile(),
          thai: thai,
          generatedAt: generatedAt,
          allRecords: records,
          profilesByRecordId: profilesByRecordId,
        ),
    ];
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static String _csvRow(List<Object?> row) {
    return row.map((value) {
      final text = (value ?? '').toString();
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }).join(',');
  }

  static String _risk(RiskLevel risk, bool thai) {
    if (thai) return risk.label;
    return switch (risk) {
      RiskLevel.low => 'Low',
      RiskLevel.medium => 'Medium',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'Very high',
    };
  }

  static List<List<Object?>> _worksheetRows({
    required String farmerId,
    required DateTime dateTime,
    required String activityStage,
    required String specificTask,
    required AssessmentBreakdown? breakdown,
    required Map<BodyPart, RiskLevel> bodyPartRisks,
    required EconomicImpactBreakdown impact,
    required List<String> selectedSuggestions,
    required bool thai,
  }) {
    final rebaScore = breakdown?.rebaResult.userScore;
    final isoRisk = breakdown?.isoResult?.riskLevel;
    final ergoInput = breakdown?.ergoInput;
    final riskLocation = _bodyPartList(bodyPartRisks, thai);
    final symptomSeverity = _risk(_highestRisk(bodyPartRisks), thai);
    final medicalCost = impact.bodyTreatmentCost +
        impact.medicalVisitCost +
        impact.medicineAndSuppliesCost;
    final productivityLoss = impact.lostIncome + impact.reducedIncome;
    final userNotes =
        selectedSuggestions.isEmpty ? '-' : selectedSuggestions.join(' | ');

    return [
      [],
      [
        thai
            ? 'Worksheet Template Data Input for Application'
            : 'Worksheet Template Data Input for Application'
      ],
      ['Field Name', 'Description / Example Entry'],
      ['Farmer ID', farmerId.isEmpty ? '-' : farmerId],
      ['Date of data entry', _dateOnly(dateTime)],
      ['Activity Stage', activityStage],
      ['Specific Task', specificTask],
      ['Posture Description', _postureDescription(breakdown, thai)],
      ['REBA Score', rebaScore ?? '-'],
      ['ISO 11228 Risk Level', isoRisk == null ? '-' : _risk(isoRisk, thai)],
      [
        'Tool Used',
        ergoInput == null ? '-' : _toolLabel(ergoInput, thai),
      ],
      [
        'Tool Weight (kg)',
        ergoInput == null ? '-' : _toolWeight(ergoInput),
      ],
      ['Tool Weight Code', ergoInput?.toolWeightBandCode ?? '-'],
      ['Manual Handling Weight (kg)', ergoInput?.loadWeight ?? '-'],
      ['Manual Handling Distance (m)', ergoInput?.transportDistance ?? '-'],
      [
        'Frequency per hour',
        ergoInput == null ? '-' : _num(ergoInput.liftFrequency * 60),
      ],
      [
        'Duration (minutes)',
        ergoInput == null ? '-' : _num(ergoInput.durationHours * 60),
      ],
      [
        thai ? 'Work days per week' : 'Work days per week',
        ergoInput == null ? '-' : _num(ergoInput.workDaysPerWeek),
      ],
      ['MSD Symptom Location', riskLocation],
      ['MSD Symptom Severity', symptomSeverity],
      ['Medical Cost (THB)', medicalCost],
      [
        'Lost Workdays',
        EconomicImpactService.estimatedLostWorkDays(
            _highestRisk(bodyPartRisks)),
      ],
      ['Productivity Loss (THB)', productivityLoss],
      ['User Feedback Notes', userNotes],
    ];
  }

  static List<Object?> _worksheetFlatRow({
    required EvaluationHistoryRecord record,
    required UserProfile profile,
    required bool thai,
    required String generatedAt,
    required List<EvaluationHistoryRecord> allRecords,
    required Map<int, UserProfile> profilesByRecordId,
  }) {
    final impact = EconomicImpactService.estimate(
      overallRisk: record.riskBefore,
      dailyIncome: _dailyIncome(profile),
      bodyPartRisks: record.bodyPartRisks,
    );
    final impactComparison = EconomicImpactService.compareBeforeAfter(
      beforeImpact: record.economicLoss,
      beforeScore: record.scoreBefore,
      afterScore: record.scoreAfter,
    );
    final breakdown = record.assessmentBreakdown;
    final afterBreakdown = record.afterAssessmentBreakdown;
    final ergoInput = breakdown?.ergoInput;
    final highestRisk = _highestRisk(record.bodyPartRisks);
    final medicalCost = impact.bodyTreatmentCost +
        impact.medicalVisitCost +
        impact.medicineAndSuppliesCost;
    final trend = _trendFieldsForRecord(
      record: record,
      profile: profile,
      allRecords: allRecords,
      profilesByRecordId: profilesByRecordId,
    );
    final userId = _resolvedFarmerId(record, profile);
    final isoScore = breakdown?.isoResult?.userScore;
    final isoRisk = breakdown?.isoResult?.riskLevel;
    final rebaBeforeScore = breakdown?.rebaResult.userScore;
    final rebaBeforeRisk = breakdown?.rebaResult.riskLevel;
    final rebaAfterScore = afterBreakdown?.rebaResult.userScore;
    final rebaAfterRisk = afterBreakdown?.rebaResult.riskLevel;
    final isoAfterScore = afterBreakdown?.isoResult?.userScore;
    final isoAfterRisk = afterBreakdown?.isoResult?.riskLevel;
    final rebaReduction = rebaBeforeScore == null || rebaAfterScore == null
        ? null
        : rebaBeforeScore - rebaAfterScore;
    final rebaReductionPercent =
        rebaBeforeScore == null || rebaBeforeScore <= 0 || rebaReduction == null
            ? null
            : rebaReduction / rebaBeforeScore;
    return [
      generatedAt,
      AssessmentReferenceSources.exportSchemaVersion,
      AssessmentReferenceSources.joinedReferences(),
      AssessmentReferenceSources.scopeNoteEn,
      AssessmentReferenceSources.calculationStandardNoteEn,
      record.id,
      record.appVersion ?? '-',
      userId,
      profile.name.isEmpty ? (record.farmerName ?? '-') : profile.name,
      profile.role.isEmpty ? (record.farmerRole ?? '-') : profile.role,
      profile.location.isEmpty
          ? (record.farmerLocation ?? '-')
          : profile.location,
      profile.age.isEmpty ? (record.farmerAge ?? '-') : profile.age,
      profile.gender.isEmpty ? (record.farmerGender ?? '-') : profile.gender,
      profile.weight.isEmpty ? (record.farmerWeight ?? '-') : profile.weight,
      profile.height.isEmpty ? (record.farmerHeight ?? '-') : profile.height,
      _bmiDisplay(profile, record, thai),
      _bmiCategory(profile, record, thai),
      _dateOnly(record.dateTime),
      record.activity?.stageLabel(thai: false) ?? '-',
      record.activityName,
      _postureDescription(breakdown, thai),
      breakdown?.rebaResult.userScore ?? '-',
      breakdown?.isoResult == null
          ? '-'
          : _risk(breakdown!.isoResult!.riskLevel, thai),
      ergoInput == null ? '-' : _toolLabel(ergoInput, thai),
      ergoInput == null ? '-' : _toolWeight(ergoInput),
      ergoInput?.toolWeightBandCode == 0
          ? '-'
          : ergoInput?.toolWeightBandCode ?? '-',
      ergoInput?.loadWeight ?? '-',
      ergoInput?.transportDistance ?? '-',
      ergoInput == null ? '-' : _num(ergoInput.liftFrequency * 60),
      ergoInput == null ? '-' : _num(ergoInput.durationHours * 60),
      ergoInput == null ? '-' : _num(ergoInput.workDaysPerWeek),
      _bodyPartList(record.bodyPartRisks, thai),
      _risk(highestRisk, thai),
      medicalCost,
      EconomicImpactService.estimatedLostWorkDays(highestRisk),
      impact.lostIncome + impact.reducedIncome,
      record.scoreBefore,
      record.scoreAfter,
      _risk(record.riskBefore, thai),
      _risk(record.riskAfter, thai),
      impactComparison.beforeImpact,
      impactComparison.afterImpact,
      impactComparison.savedAmount,
      'After impact = before impact × (1 - 0.28 × score reduction); score reduction ${impactComparison.effectiveScoreReduction}',
      record.selectedSuggestions.isEmpty
          ? '-'
          : record.selectedSuggestions.join(' | '),
      record.id,
      userId,
      _dateOnly(record.dateTime),
      _timeOnly(record.dateTime),
      record.activity?.name ?? record.activityName,
      rebaBeforeScore ?? record.scoreBefore,
      _risk(rebaBeforeRisk ?? record.riskBefore, thai),
      isoScore ?? '-',
      isoRisk == null ? '-' : _risk(isoRisk, thai),
      ergoInput?.loadWeight ?? '-',
      ergoInput == null ? '-' : _num(ergoInput.liftFrequency * 60),
      ergoInput == null ? '-' : _num(ergoInput.durationHours * 60),
      rebaAfterScore ?? '-',
      rebaAfterRisk == null ? '-' : _risk(rebaAfterRisk, thai),
      isoAfterScore ?? '-',
      isoAfterRisk == null ? '-' : _risk(isoAfterRisk, thai),
      rebaReduction ?? '-',
      rebaReductionPercent == null ? '-' : _percent(rebaReductionPercent),
      _num(trend.average),
      trend.maximum,
      trend.highRiskCount,
      _trendLevel(trend.highRiskCount, thai),
      trend.direction,
      _risk(record.bodyPartRisks[BodyPart.neck] ?? RiskLevel.low, thai),
      _risk(record.bodyPartRisks[BodyPart.arms] ?? RiskLevel.low, thai),
      _risk(_upperLimbRisk(record.bodyPartRisks), thai),
      _risk(record.bodyPartRisks[BodyPart.wrists] ?? RiskLevel.low, thai),
      _risk(record.bodyPartRisks[BodyPart.trunk] ?? RiskLevel.low, thai),
      _risk(record.bodyPartRisks[BodyPart.legs] ?? RiskLevel.low, thai),
      _photoId(record, breakdown),
      _photoTimestamp(record, breakdown),
      record.timeOnTaskSeconds ?? '',
      record.completionStatus ?? '',
      record.assistanceRequired?.toString() ?? '',
      record.errorCount ?? '',
      record.expertReba == null ? '' : _num(record.expertReba!),
      record.expertRiskLevel == null
          ? ''
          : _risk(record.expertRiskLevel!, thai),
      record.expertAssessmentDate?.toIso8601String() ?? '',
      record.expertComments ?? '',
    ];
  }

  static RiskLevel _upperLimbRisk(Map<BodyPart, RiskLevel> bodyPartRisks) {
    final arms = bodyPartRisks[BodyPart.arms] ?? RiskLevel.low;
    final wrists = bodyPartRisks[BodyPart.wrists] ?? RiskLevel.low;
    return arms.index >= wrists.index ? arms : wrists;
  }

  static String _photoId(
    EvaluationHistoryRecord record,
    AssessmentBreakdown? breakdown,
  ) {
    final persistedId = record.photoId;
    if (persistedId != null && persistedId.isNotEmpty) return persistedId;
    if (breakdown == null || breakdown.poseFrames.isEmpty) return '-';
    final imageIndex =
        breakdown.worstPoseImageIndex ?? breakdown.poseFrames.first.imageIndex;
    return 'transaction_${record.id}_photo_$imageIndex';
  }

  static String _photoTimestamp(
    EvaluationHistoryRecord record,
    AssessmentBreakdown? breakdown,
  ) {
    final persistedTimestamp = record.photoTimestamp;
    if (persistedTimestamp != null) return persistedTimestamp.toIso8601String();
    if (breakdown == null || breakdown.poseFrames.isEmpty) return '-';
    return record.dateTime.toIso8601String();
  }

  static String _trendLevel(int highRiskCount, bool thai) {
    final level = highRiskCount >= 6
        ? RiskLevel.veryHigh
        : highRiskCount >= 4
            ? RiskLevel.high
            : highRiskCount >= 2
                ? RiskLevel.medium
                : RiskLevel.low;
    return _risk(level, thai);
  }

  static ({
    double average,
    int maximum,
    int highRiskCount,
    String direction,
  }) _trendFieldsForRecord({
    required EvaluationHistoryRecord record,
    required UserProfile profile,
    required List<EvaluationHistoryRecord> allRecords,
    required Map<int, UserProfile> profilesByRecordId,
  }) {
    final userId = _resolvedFarmerId(record, profile);
    final sameFarmer = allRecords.where((candidate) {
      final candidateProfile =
          profilesByRecordId[candidate.id] ?? const UserProfile();
      return _resolvedFarmerId(candidate, candidateProfile) == userId &&
          !candidate.dateTime.isAfter(record.dateTime);
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final window = sameFarmer.length <= 7
        ? sameFarmer
        : sameFarmer.sublist(sameFarmer.length - 7);
    final scores = window.map((item) => item.scoreBefore).toList();
    if (scores.isEmpty) {
      return (average: 0, maximum: 0, highRiskCount: 0, direction: 'stable');
    }
    final average =
        scores.fold<double>(0, (sum, value) => sum + value) / scores.length;
    final maximum = scores.reduce((a, b) => a > b ? a : b);
    final highRiskCount = window
        .where((item) => item.riskBefore.index >= RiskLevel.high.index)
        .length;
    final slope = scores.last - scores.first;
    final direction = slope >= 1
        ? 'increasing'
        : slope <= -1
            ? 'decreasing'
            : 'stable';
    return (
      average: average,
      maximum: maximum,
      highRiskCount: highRiskCount,
      direction: direction,
    );
  }

  static String _resolvedFarmerId(
    EvaluationHistoryRecord record,
    UserProfile profile,
  ) {
    if (profile.farmerId.isNotEmpty) return profile.farmerId;
    if ((record.farmerId ?? '').isNotEmpty) return record.farmerId!;
    if ((record.farmerProfileId ?? '').isNotEmpty) {
      return record.farmerProfileId!;
    }
    if (profile.profileId.isNotEmpty) return profile.profileId;
    return 'record-${record.id}';
  }

  static List<List<Object?>> _assessmentBreakdownRows(
    AssessmentBreakdown? breakdown,
    bool thai,
  ) {
    if (breakdown == null) {
      return [
        [],
        [thai ? 'รายละเอียดการประเมิน REBA/ISO11228' : 'REBA/ISO11228 details'],
        [
          thai
              ? 'ไม่มีรายละเอียดภายในสำหรับประวัติเก่านี้'
              : 'No internal assessment details are available for this record.'
        ],
      ];
    }
    final rows = <List<Object?>>[
      [],
      [thai ? 'รายละเอียดการประเมิน REBA/ISO11228' : 'REBA/ISO11228 details'],
      [
        thai ? 'มิติการประเมิน' : 'Assessment dimension',
        thai ? 'วิธี' : 'Method',
        thai ? 'ใช้เป็นผลหลัก' : 'Primary',
        thai ? 'คะแนนผู้ใช้' : 'User score',
        thai ? 'ระดับ' : 'Risk level',
        thai ? 'คะแนนเทคนิค/ดัชนี' : 'Technical score/index',
        thai ? 'ค่าขีดจำกัด' : 'Limit/reference',
      ],
      if (breakdown.primaryMethod == AssessmentMethod.rebaIsoCombined)
        [
          thai ? 'ผลรวม' : 'Combined',
          _method(AssessmentMethod.rebaIsoCombined, thai),
          _yesNo(true, thai),
          '-',
          '-',
          '-',
          '-',
        ],
      [
        'REBA',
        _method(AssessmentMethod.reba, thai),
        _yesNo(breakdown.primaryMethod == AssessmentMethod.reba, thai),
        breakdown.rebaResult.userScore,
        _risk(breakdown.rebaResult.riskLevel, thai),
        _num(breakdown.rebaResult.techScore),
        _num(breakdown.rebaResult.limitValue),
      ],
    ];

    final rebaScoreBreakdown =
        ErgoCalculator.calculateRebaScoreBreakdown(breakdown.rebaInput);
    final isoMethod = breakdown.isoMethod;
    final isoResult = breakdown.isoResult;
    if (isoMethod != null && isoResult != null) {
      rows.add([
        'ISO11228',
        _method(isoMethod, thai),
        _yesNo(breakdown.primaryMethod == isoMethod, thai),
        isoResult.userScore,
        _risk(isoResult.riskLevel, thai),
        _num(isoResult.techScore),
        _num(isoResult.limitValue),
      ]);
    } else {
      rows.add([
        'ISO11228',
        thai
            ? 'ไม่ได้คำนวณในรอบนี้ เพราะกิจกรรมนี้ใช้ REBA เป็นผลหลัก'
            : 'Not calculated in this run because this activity used REBA as primary',
        _yesNo(false, thai),
        '-',
        '-',
        '-',
        '-',
      ]);
    }

    rows.addAll([
      [],
      [thai ? 'ข้อมูลย่อย REBA' : 'REBA component inputs'],
      [thai ? 'รายการ' : 'Field', thai ? 'ค่า' : 'Value'],
      [thai ? 'ลำตัว' : 'Trunk score', breakdown.rebaInput.trunkScore],
      [
        thai ? 'ลำตัวหลังปรับบิด/เอียง' : 'Adjusted trunk score',
        breakdown.rebaInput.adjustedTrunkScore,
      ],
      [thai ? 'คอ' : 'Neck score', breakdown.rebaInput.neckScore],
      [thai ? 'ขา' : 'Leg score', breakdown.rebaInput.legScore],
      [thai ? 'ต้นแขน' : 'Upper arm score', breakdown.rebaInput.upperArmScore],
      [thai ? 'ปลายแขน' : 'Lower arm score', breakdown.rebaInput.lowerArmScore],
      [thai ? 'ข้อมือ' : 'Wrist score', breakdown.rebaInput.wristScore],
      [
        thai ? 'ข้อมือหลังปรับบิด' : 'Adjusted wrist score',
        breakdown.rebaInput.adjustedWristScore,
      ],
      [thai ? 'ลำตัวบิด' : 'Trunk twist', breakdown.rebaInput.trunkTwist],
      [
        thai ? 'ลำตัวเอียงข้าง' : 'Trunk side flexion',
        breakdown.rebaInput.trunkSideFlex,
      ],
      [thai ? 'ข้อมือบิด' : 'Wrist twist', breakdown.rebaInput.wristTwist],
      [thai ? 'ภาระ/แรง' : 'Load score', breakdown.rebaInput.loadScore],
      [
        thai ? 'การจับยึด' : 'Coupling score',
        breakdown.rebaInput.couplingScore
      ],
      [
        thai ? 'กิจกรรมซ้ำ/ค้าง' : 'Activity score',
        breakdown.rebaInput.activityScore
      ],
      [],
      [thai ? 'ตารางคะแนน REBA' : 'REBA score tables'],
      [thai ? 'รายการ' : 'Field', thai ? 'ค่า' : 'Value'],
      ['Table A', rebaScoreBreakdown.tableAScore],
      ['Score A', rebaScoreBreakdown.scoreA],
      ['Table B', rebaScoreBreakdown.tableBScore],
      ['Score B', rebaScoreBreakdown.scoreB],
      ['Score C', rebaScoreBreakdown.scoreC],
      [
        thai ? 'Activity Score' : 'Activity Score',
        rebaScoreBreakdown.activityScore,
      ],
      ['Final REBA', rebaScoreBreakdown.finalScore],
      [
        thai ? 'ระดับ REBA' : 'REBA risk level',
        _risk(rebaScoreBreakdown.riskLevel, thai),
      ],
      [],
      [thai ? 'เกณฑ์ REBA ที่ใช้' : 'REBA criteria used'],
      [
        thai ? 'ลำตัว' : 'Trunk',
        thai
            ? '0-5°=1, 5-20°=2, 20-60°=3, >60°=4'
            : '0-5°=1, 5-20°=2, 20-60°=3, >60°=4',
      ],
      [
        thai ? 'คอ' : 'Neck',
        thai
            ? '<=20°=1, >20°=2, เพิ่มเมื่อบิด/เอียง'
            : '<=20°=1, >20°=2, plus twist/side-bend modifier',
      ],
      [
        thai ? 'ต้นแขน' : 'Upper arm',
        thai
            ? '<=20°=1, 20-45°=2, 45-90°=3, >90°=4'
            : '<=20°=1, 20-45°=2, 45-90°=3, >90°=4',
      ],
      [
        thai ? 'ปลายแขน/ขา' : 'Lower arm/legs',
        thai
            ? 'ปลายแขน 60-100°=1 นอกช่วง=2; ขาไม่สมดุล/งอมาก=2'
            : 'Lower arm 60-100°=1 outside=2; non-neutral legs=2',
      ],
      if (breakdown.motionSummary != null &&
          breakdown.motionSummary!.isVideo) ...[
        [],
        [thai ? 'สรุปการเคลื่อนไหวจากวิดีโอ' : 'Video-derived motion summary'],
        [thai ? 'รายการ' : 'Field', thai ? 'ค่า' : 'Value'],
        [
          thai ? 'แหล่งวิดีโอ' : 'Video source',
          breakdown.motionSummary!.sourceKind,
        ],
        [
          thai ? 'ความยาววิดีโอ (วินาที)' : 'Video duration (seconds)',
          _num(breakdown.motionSummary!.durationMs / 1000),
        ],
        [
          thai ? 'เฟรมที่สุ่ม' : 'Sampled frames',
          breakdown.motionSummary!.sampledFrameCount,
        ],
        [
          thai ? 'เฟรมที่อ่านท่าทางได้' : 'Readable frames',
          breakdown.motionSummary!.readableFrameCount,
        ],
        [
          thai ? 'อัตราเฟรมเสี่ยงสูง' : 'High-risk frame ratio',
          _percent(breakdown.motionSummary!.highRiskFrameRatio),
        ],
        [
          thai ? 'อัตราเฟรมที่มีส่วนร่างกายเสี่ยง' : 'Segment-risk frame ratio',
          _percent(breakdown.motionSummary!.anySegmentRiskFrameRatio),
        ],
        [
          thai ? 'ส่วนร่างกายเด่น' : 'Dominant body segment',
          _bodySegment(breakdown.motionSummary!.dominantRiskBodyPart, thai),
        ],
        [
          thai
              ? 'เวลาช่วงเสี่ยงรายส่วนโดยประมาณ (วินาที)'
              : 'Estimated segment-risk time (s)',
          _num(breakdown.motionSummary!.estimatedSegmentRiskSeconds),
        ],
        [
          thai
              ? 'อัตราเฟรมก้มลำตัวลึก (metric เสริม)'
              : 'Deep-trunk-flexion frame ratio (supporting metric)',
          _percent(breakdown.motionSummary!.deepTrunkFlexionRatio),
        ],
        [
          thai
              ? 'เวลาช่วงเสี่ยงรวมโดยประมาณ (วินาที)'
              : 'Estimated high-risk time (s)',
          _num(breakdown.motionSummary!.estimatedHighRiskSeconds),
        ],
        [
          thai
              ? 'เวลาก้มลำตัวลึกโดยประมาณ (วินาที)'
              : 'Estimated deep-trunk time (s)',
          _num(breakdown.motionSummary!.estimatedDeepTrunkSeconds),
        ],
        [
          thai ? 'จำนวนครั้งที่ท่าเปลี่ยนชัดเจน' : 'Clear posture changes',
          breakdown.motionSummary!.movementChangeCount,
        ],
        [
          thai ? 'รูปแบบการเคลื่อนไหว' : 'Motion pattern',
          _motionPattern(breakdown.motionSummary!.pattern, thai),
        ],
        [
          thai ? 'สัดส่วนคอเสี่ยง' : 'Neck-risk frame ratio',
          _percent(breakdown.motionSummary!.neckRiskFrameRatio),
        ],
        [
          thai ? 'สัดส่วนลำตัวเสี่ยง' : 'Trunk-risk frame ratio',
          _percent(breakdown.motionSummary!.trunkRiskFrameRatio),
        ],
        [
          thai ? 'สัดส่วนต้นแขนเสี่ยง' : 'Upper-arm-risk frame ratio',
          _percent(breakdown.motionSummary!.upperArmRiskFrameRatio),
        ],
        [
          thai ? 'สัดส่วนปลายแขนเสี่ยง' : 'Lower-arm-risk frame ratio',
          _percent(breakdown.motionSummary!.lowerArmRiskFrameRatio),
        ],
        [
          thai ? 'สัดส่วนข้อมือเสี่ยง' : 'Wrist-risk frame ratio',
          _percent(breakdown.motionSummary!.wristRiskFrameRatio),
        ],
        [
          thai ? 'สัดส่วนขา/เข่าเสี่ยง' : 'Leg-risk frame ratio',
          _percent(breakdown.motionSummary!.legRiskFrameRatio),
        ],
        [
          thai ? 'มุมลำตัวสูงสุด' : 'Max trunk flexion',
          _angle(breakdown.motionSummary!.maxTrunkFlexionDeg),
        ],
        [
          thai ? 'มุมลำตัวเฉลี่ย' : 'Avg trunk flexion',
          _angle(breakdown.motionSummary!.avgTrunkFlexionDeg),
        ],
      ],
      if (breakdown.poseFrames.isNotEmpty) ...[
        [],
        [thai ? 'ผลวิเคราะห์รายภาพ' : 'Per-photo posture analysis'],
        [
          thai ? 'ภาพ' : 'Photo',
          'Neck flexion',
          'Trunk flexion',
          'Upper arm',
          'Lower arm',
          'Knee',
          'Timestamp (ms)',
          'REBA',
          'Worst posture',
        ],
        ...breakdown.poseFrames.map(
          (frame) => [
            frame.imageIndex,
            _angle(frame.neckFlexionDeg),
            _angle(frame.trunkFlexionDeg),
            _angle(frame.upperArmFlexionDeg),
            _angle(frame.lowerArmAngleDeg),
            _angle(frame.kneeAngleDeg),
            frame.timestampMs ?? '-',
            frame.rebaScore,
            _yesNo(frame.imageIndex == breakdown.worstPoseImageIndex, thai),
          ],
        ),
      ],
      [],
      [thai ? 'ข้อมูลย่อย ISO11228' : 'ISO11228 component inputs'],
      [thai ? 'รายการ' : 'Field', thai ? 'ค่า' : 'Value'],
      [thai ? 'ประเภทงาน' : 'Job type', breakdown.ergoInput.jobType.name],
      [
        thai ? 'เครื่องมือ/น้ำหนักที่ใช้' : 'Tool / load used',
        _toolLabel(breakdown.ergoInput, thai)
      ],
      [
        thai
            ? 'น้ำหนักเครื่องมือ/ภาระตามตัวเลือก (กก.)'
            : 'Tool/load option kg',
        _toolWeight(breakdown.ergoInput)
      ],
      [
        thai ? 'รหัสช่วงน้ำหนัก' : 'Weight band code',
        breakdown.ergoInput.toolWeightBandCode == 0
            ? '-'
            : breakdown.ergoInput.toolWeightBandCode,
      ],
      [
        thai ? 'น้ำหนักที่ยก/ขน (กก.)' : 'Load weight (kg)',
        breakdown.ergoInput.loadWeight
      ],
      [
        thai ? 'ระยะห่างแนวนอน (ซม.)' : 'Horizontal distance (cm)',
        breakdown.ergoInput.horizontalDist,
      ],
      [
        thai ? 'ความสูงแนวตั้ง (ซม.)' : 'Vertical height (cm)',
        breakdown.ergoInput.verticalHeight,
      ],
      [
        thai ? 'ความถี่การยก (ครั้ง/นาที)' : 'Lift frequency (lifts/min)',
        breakdown.ergoInput.liftFrequency,
      ],
      [
        thai ? 'ระยะเวลาทำงาน (ชม.)' : 'Duration (hours)',
        breakdown.ergoInput.durationHours
      ],
      [
        thai ? 'วันทำงานต่อสัปดาห์' : 'Work days per week',
        breakdown.ergoInput.workDaysPerWeek,
      ],
      [
        thai ? 'ระยะทางขนย้าย (ม.)' : 'Transport distance (m)',
        breakdown.ergoInput.transportDistance,
      ],
      [
        thai ? 'แรงเริ่มต้นดัน/ลาก (นิวตัน)' : 'Initial push/pull force (N)',
        breakdown.ergoInput.initialForce,
      ],
      [
        thai ? 'แรงต่อเนื่องดัน/ลาก (นิวตัน)' : 'Sustained push/pull force (N)',
        breakdown.ergoInput.sustainForce,
      ],
    ]);
    return rows;
  }

  static String _method(AssessmentMethod method, bool thai) {
    if (thai) {
      return switch (method) {
        AssessmentMethod.rebaIsoCombined =>
          'REBA + ISO11228: รวมความเสี่ยงตามงานจริง',
        AssessmentMethod.reba => 'REBA: ท่าทางและส่วนร่างกาย',
        AssessmentMethod.iso11228Lifting => 'ISO11228-1: ยก/ขนย้าย',
        AssessmentMethod.iso11228PushPull => 'ISO11228-2: ดัน/ลาก',
      };
    }
    return switch (method) {
      AssessmentMethod.rebaIsoCombined =>
        'REBA + ISO11228: combined real-task risk',
      AssessmentMethod.reba => 'REBA: posture and body segments',
      AssessmentMethod.iso11228Lifting => 'ISO11228-1: lifting/carrying',
      AssessmentMethod.iso11228PushPull => 'ISO11228-2: pushing/pulling',
    };
  }

  static String _yesNo(bool value, bool thai) {
    if (thai) return value ? 'ใช่' : 'ไม่ใช่';
    return value ? 'Yes' : 'No';
  }

  static String _toolLabel(ErgoInputData input, bool thai) {
    final label = thai ? input.toolLabelTh : input.toolLabelEn;
    if (label.trim().isNotEmpty) return label;
    if (input.toolLabelTh.trim().isNotEmpty) return input.toolLabelTh;
    if (input.toolLabelEn.trim().isNotEmpty) return input.toolLabelEn;
    return '-';
  }

  static Object _toolWeight(ErgoInputData input) {
    final weight =
        input.toolWeightKg > 0 ? input.toolWeightKg : input.loadWeight;
    return _num(weight);
  }

  static String _bmiDisplay(
    UserProfile profile,
    EvaluationHistoryRecord? record,
    bool thai,
  ) {
    final value = profile.bmi ?? record?.farmerBmi ?? _bmiFromRecord(record);
    if (value == null) return '-';
    return value.toStringAsFixed(1);
  }

  static String _bmiCategory(
    UserProfile profile,
    EvaluationHistoryRecord? record,
    bool thai,
  ) {
    final key = profile.bmi == null
        ? (record?.farmerBmiCategory ?? _bmiCategoryKey(_bmiFromRecord(record)))
        : profile.bmiCategoryKey;
    return switch (key) {
      'underweight' => thai ? 'น้ำหนักต่ำกว่าเกณฑ์' : 'Underweight',
      'normal' => thai ? 'น้ำหนักปกติ' : 'Normal weight',
      'overweight' => thai ? 'น้ำหนักมากกว่าเกณฑ์' : 'Above Asian BMI range',
      _ => '-',
    };
  }

  static double? _bmiFromRecord(EvaluationHistoryRecord? record) {
    if (record == null) return null;
    final weight = _parseNumber(record.farmerWeight);
    final height = _parseNumber(record.farmerHeight);
    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return null;
    }
    final meters = height / 100;
    return weight / (meters * meters);
  }

  static String _bmiCategoryKey(double? bmi) {
    if (bmi == null) return 'unknown';
    if (bmi < 18.5) return 'underweight';
    if (bmi < 23) return 'normal';
    return 'overweight';
  }

  static double? _parseNumber(String? raw) {
    final value = raw?.trim().replaceAll(',', '.');
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  static Object _num(double value) {
    if (value == value.roundToDouble()) return value.round();
    return value.toStringAsFixed(2);
  }

  static Object _angle(double? value) {
    if (value == null || value.isNaN) return '-';
    return '${value.round()}°';
  }

  static String _percent(double ratio) => '${(ratio * 100).round()}%';

  static String _motionPattern(MotionPattern pattern, bool thai) {
    if (thai) {
      return switch (pattern) {
        MotionPattern.stableLowRisk => 'ท่าทางค่อนข้างคงที่และเสี่ยงต่ำ',
        MotionPattern.intermittentWorstPosture => 'มีช่วงท่าเสี่ยงเป็นบางจุด',
        MotionPattern.repeatedRiskMovement => 'มีการเคลื่อนไหวเสี่ยงซ้ำ',
        MotionPattern.staticHighRiskHold => 'ค้างท่าเสี่ยงสูงหลายช่วง',
      };
    }
    return switch (pattern) {
      MotionPattern.stableLowRisk => 'stable lower-risk posture',
      MotionPattern.intermittentWorstPosture => 'intermittent worst posture',
      MotionPattern.repeatedRiskMovement => 'repeated risk movement',
      MotionPattern.staticHighRiskHold => 'static high-risk hold',
    };
  }

  static String _bodySegment(String? key, bool thai) {
    if (key == null) return thai ? 'ไม่พบส่วนเด่น' : 'none';
    if (thai) {
      return switch (key) {
        'neck' => 'คอ',
        'trunk' => 'ลำตัว/หลัง',
        'upper_arm' => 'ต้นแขน/ไหล่',
        'lower_arm' => 'ปลายแขน',
        'wrist' => 'ข้อมือ',
        'legs' => 'ขา/เข่า',
        _ => key,
      };
    }
    return switch (key) {
      'neck' => 'neck',
      'trunk' => 'trunk/back',
      'upper_arm' => 'upper arm/shoulder',
      'lower_arm' => 'lower arm',
      'wrist' => 'wrist',
      'legs' => 'legs/knees',
      _ => key,
    };
  }

  static String _dateOnly(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  static String _timeOnly(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  static String _postureDescription(AssessmentBreakdown? breakdown, bool thai) {
    if (breakdown == null) return '-';
    final reba = breakdown.rebaInput;
    final primary = _method(breakdown.primaryMethod, thai);
    return thai
        ? '$primary | ลำตัว ${reba.trunkScore}, คอ ${reba.neckScore}, ขา ${reba.legScore}, ต้นแขน ${reba.upperArmScore}, ปลายแขน ${reba.lowerArmScore}, ข้อมือ ${reba.wristScore}'
        : '$primary | trunk ${reba.trunkScore}, neck ${reba.neckScore}, legs ${reba.legScore}, upper arm ${reba.upperArmScore}, lower arm ${reba.lowerArmScore}, wrist ${reba.wristScore}';
  }

  static String _bodyPartList(
      Map<BodyPart, RiskLevel> bodyPartRisks, bool thai) {
    final riskyParts = bodyPartRisks.entries
        .where((entry) => entry.value != RiskLevel.low)
        .map((entry) => _bodyPart(entry.key, thai))
        .toList();
    if (riskyParts.isEmpty) return '-';
    return riskyParts.join(', ');
  }

  static RiskLevel _highestRisk(Map<BodyPart, RiskLevel> bodyPartRisks) {
    if (bodyPartRisks.isEmpty) return RiskLevel.low;
    return bodyPartRisks.values.reduce(
      (current, next) => next.index > current.index ? next : current,
    );
  }

  static double _dailyIncome(UserProfile profile) {
    final yearlyIncome = double.tryParse(profile.incomePerYear);
    if (yearlyIncome != null && yearlyIncome > 0) return yearlyIncome / 365;
    return 350;
  }

  static String _bodyPart(BodyPart part, bool thai) {
    if (thai) {
      return switch (part) {
        BodyPart.neck => 'คอ',
        BodyPart.trunk => 'หลัง/ลำตัว',
        BodyPart.legs => 'ขา/เข่า',
        BodyPart.arms => 'แขน/ไหล่',
        BodyPart.wrists => 'ข้อมือ',
      };
    }
    return switch (part) {
      BodyPart.neck => 'Neck',
      BodyPart.trunk => 'Back/trunk',
      BodyPart.legs => 'Legs/knees',
      BodyPart.arms => 'Arms/shoulders',
      BodyPart.wrists => 'Wrists',
    };
  }
}
