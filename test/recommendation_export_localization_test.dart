import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/assessment_export_service.dart';

void main() {
  test('English user export contains approved English recommendations only',
      () {
    final recordWithSelectionKeys = EvaluationHistoryRecord(
      id: 1,
      activity: SooktaActivity.fertilizing,
      activityName: 'การใส่ปุ๋ย',
      dateTime: DateTime(2026, 7, 29, 10),
      scoreBefore: 8,
      scoreAfter: 6,
      riskBefore: RiskLevel.high,
      riskAfter: RiskLevel.medium,
      economicLoss: 1000,
      moneySaved: 280,
      selectedSuggestionKeys: const ['act_fert_split_load'],
      selectedSuggestions: const ['แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'],
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
    );

    final csv = AssessmentExportService.buildHistoryRecordCsv(
      record: recordWithSelectionKeys,
      profile: const UserProfile(),
      thai: false,
    );

    expect(csv, contains('Selected recommendations'));
    expect(csv, contains('"Activity","Fertilizing"'));
    expect(RegExp(r'[ก-๙]').hasMatch(csv), isFalse);
  });

  test('Thai user export contains approved Thai recommendations', () {
    final csv = AssessmentExportService.buildHistoryRecordCsv(
      record: _record(
        selectedSuggestionKeys: const ['act_fert_split_load'],
        selectedSuggestions: const ['obsolete legacy display'],
      ),
      profile: const UserProfile(),
      thai: true,
    );

    expect(csv, contains('คำแนะนำที่เลือก'));
    expect(csv, contains('แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'));
    expect(csv, isNot(contains('obsolete legacy display')));
  });

  test('unknown Thai legacy text is not emitted by English user export', () {
    final csv = AssessmentExportService.buildHistoryRecordCsv(
      record: _record(
        selectedSuggestions: const ['คำแนะนำเก่าที่ไม่รู้จัก'],
      ),
      profile: const UserProfile(),
      thai: false,
    );

    expect(
      csv,
      contains(
        'A saved recommendation could not be matched to the current approved catalog.',
      ),
    );
    expect(RegExp(r'[ก-๙]').hasMatch(csv), isFalse);
  });

  test('research export keeps legacy recommendation traceability', () {
    final record = _record(
      selectedSuggestionKeys: const ['act_fert_split_load'],
      selectedSuggestions: const ['คำแนะนำเดิมสำหรับงานวิจัย'],
    );

    final csv = AssessmentExportService.buildAllHistoryCsv(
      records: [record],
      profilesByRecordId: const {1: UserProfile()},
      thai: false,
    );

    expect(csv, contains('"User Feedback Notes"'));
    expect(csv, contains('คำแนะนำเดิมสำหรับงานวิจัย'));
  });
}

EvaluationHistoryRecord _record({
  List<String> selectedSuggestionKeys = const [],
  required List<String> selectedSuggestions,
}) {
  return EvaluationHistoryRecord(
    id: 1,
    activityName: 'Fertilizing',
    dateTime: DateTime(2026, 7, 29, 10),
    scoreBefore: 8,
    scoreAfter: 6,
    riskBefore: RiskLevel.high,
    riskAfter: RiskLevel.medium,
    economicLoss: 1000,
    moneySaved: 280,
    selectedSuggestionKeys: selectedSuggestionKeys,
    selectedSuggestions: selectedSuggestions,
    bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
  );
}
