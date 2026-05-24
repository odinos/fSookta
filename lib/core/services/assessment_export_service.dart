import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../app/app_state.dart';
import '../models/assessment_session.dart';
import '../models/economic_impact_models.dart';
import '../models/evaluation_models.dart';

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

  static String buildExcelCsv({
    required AssessmentBundle bundle,
    required UserProfile profile,
    required List<String> selectedSuggestions,
    required EconomicImpactBreakdown beforeImpact,
    required EconomicImpactBreakdown afterImpact,
    EvaluationHistoryRecord? record,
    bool thai = true,
  }) {
    final rows = <List<Object?>>[
      [thai ? 'หัวข้อ' : 'Field', thai ? 'ข้อมูล' : 'Value'],
      [thai ? 'เลขประเมิน' : 'Record ID', record?.id ?? '-'],
      [
        thai ? 'วันที่ประเมิน' : 'Assessment date',
        (record?.dateTime ?? DateTime.now()).toIso8601String(),
      ],
      [thai ? 'กิจกรรม' : 'Activity', bundle.activityName],
      [thai ? 'ประเภทงาน' : 'Job type', bundle.jobType.name],
      [thai ? 'ชื่อผู้ใช้' : 'Name', profile.name],
      [thai ? 'อายุ' : 'Age', profile.age],
      [thai ? 'เพศ' : 'Gender', profile.gender],
      [thai ? 'น้ำหนัก' : 'Weight', profile.weight],
      [thai ? 'ส่วนสูง' : 'Height', profile.height],
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
      [
        thai ? 'ผลกระทบก่อนปรับ (บาท)' : 'Before impact (THB)',
        beforeImpact.totalCost,
      ],
      [
        thai ? 'ผลกระทบหลังปรับ (บาท)' : 'After impact (THB)',
        afterImpact.totalCost,
      ],
      [
        thai ? 'ผลกระทบที่ลดลง (บาท)' : 'Reduced impact (THB)',
        (beforeImpact.totalCost - afterImpact.totalCost).clamp(0, 999999),
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
    ];
    return '\uFEFF${rows.map(_csvRow).join('\n')}\n';
  }

  static String buildHistoryRecordCsv({
    required EvaluationHistoryRecord record,
    required UserProfile profile,
    bool thai = true,
  }) {
    final estimatedAfterImpact =
        (record.economicLoss - record.moneySaved).clamp(0, 999999);
    final rows = <List<Object?>>[
      [thai ? 'หัวข้อ' : 'Field', thai ? 'ข้อมูล' : 'Value'],
      [thai ? 'เลขประเมิน' : 'Record ID', record.id],
      [
        thai ? 'วันที่ประเมิน' : 'Assessment date',
        record.dateTime.toIso8601String()
      ],
      [thai ? 'กิจกรรม' : 'Activity', record.activityName],
      [thai ? 'ชื่อผู้ใช้' : 'Name', profile.name],
      [thai ? 'อายุ' : 'Age', profile.age],
      [thai ? 'เพศ' : 'Gender', profile.gender],
      [thai ? 'น้ำหนัก' : 'Weight', profile.weight],
      [thai ? 'ส่วนสูง' : 'Height', profile.height],
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
        estimatedAfterImpact,
      ],
      [
        thai ? 'ผลกระทบที่ลดลง (บาท)' : 'Reduced impact (THB)',
        record.moneySaved,
      ],
      if (record.aiRiskPercent != null) ...[
        [],
        [thai ? 'สัญญาณช่วยเฝ้าระวัง' : 'Posture awareness signal'],
        [thai ? 'เปอร์เซ็นต์' : 'Percent', record.aiRiskPercent],
        [thai ? 'ระดับ AI' : 'AI level', record.aiAlertLevel?.name ?? '-'],
        [thai ? 'แหล่งโมเดล' : 'Model source', record.aiModelSource ?? '-'],
      ],
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
