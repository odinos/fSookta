import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/app_text.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/history_tab.dart';

void main() {
  testWidgets('shows history trend summary and filters high-risk records',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()
      ..setLanguage(AppLanguage.th)
      ..saveProfile(
        const UserProfile(
          profileId: 'profile-history',
          farmerId: 'FARM-HISTORY',
          name: 'ชาวสวนทดสอบ',
        ),
      );
    addTearDown(state.dispose);

    await _saveRecord(
      state,
      activity: SooktaActivity.fertilizing,
      activityName: 'การใส่ปุ๋ย',
      beforeScore: 8,
      afterScore: 4,
      beforeRisk: RiskLevel.high,
      afterRisk: RiskLevel.medium,
    );
    await _saveRecord(
      state,
      activity: SooktaActivity.transplanting,
      activityName: 'การปลูกกล้า',
      beforeScore: 7,
      afterScore: 3,
      beforeRisk: RiskLevel.high,
      afterRisk: RiskLevel.low,
    );
    await _saveRecord(
      state,
      activity: SooktaActivity.pruning,
      activityName: 'การตัดแต่งกิ่ง',
      beforeScore: 4,
      afterScore: 3,
      beforeRisk: RiskLevel.medium,
      afterRisk: RiskLevel.low,
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: HistoryTab(text: AppText(AppLanguage.th)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('สรุปประวัติและแนวโน้ม'), findsOneWidget);
    expect(find.textContaining('ทั้งหมด 3 ครั้ง'), findsOneWidget);
    expect(find.textContaining('คะแนนก่อนเฉลี่ย 6.3'), findsOneWidget);
    expect(find.textContaining('คะแนนหลังเฉลี่ย 3.3'), findsOneWidget);
    expect(find.textContaining('ความเสี่ยงสูง 2 ครั้ง'), findsOneWidget);
    expect(find.textContaining('ชาวสวนทดสอบ • การตัดแต่งกิ่ง'), findsOneWidget);

    await tester.tap(find.text('เสี่ยงสูง'));
    await tester.pumpAndSettle();

    expect(find.textContaining('แสดง 2 จาก 3 ครั้ง'), findsOneWidget);
    expect(find.textContaining('ชาวสวนทดสอบ • การใส่ปุ๋ย'), findsOneWidget);
    expect(find.textContaining('ชาวสวนทดสอบ • การปลูกกล้า'), findsOneWidget);
    expect(find.textContaining('ชาวสวนทดสอบ • การตัดแต่งกิ่ง'), findsNothing);
    expect(
      find.byTooltip('ส่งออกประวัติที่แสดงอยู่ 2 รายการ'),
      findsOneWidget,
    );
  });

  testWidgets('shows empty filtered state and disables filtered export',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()
      ..setLanguage(AppLanguage.th)
      ..saveProfile(
        const UserProfile(
          profileId: 'profile-history-empty-filter',
          farmerId: 'FARM-HISTORY-EMPTY',
          name: 'ชาวสวนทดสอบ',
        ),
      );
    addTearDown(state.dispose);

    await _saveRecord(
      state,
      activity: SooktaActivity.pruning,
      activityName: 'การตัดแต่งกิ่ง',
      beforeScore: 4,
      afterScore: 3,
      beforeRisk: RiskLevel.medium,
      afterRisk: RiskLevel.low,
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: HistoryTab(text: AppText(AppLanguage.th)),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('เสี่ยงสูง'));
    await tester.pumpAndSettle();

    expect(find.textContaining('แสดง 0 จาก 1 ครั้ง'), findsOneWidget);
    expect(find.text('ไม่พบประวัติตามตัวกรองนี้'), findsOneWidget);
    expect(
      find.textContaining('ชาวสวนทดสอบ • การตัดแต่งกิ่ง'),
      findsNothing,
    );

    final exportButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.download_outlined),
    );
    expect(exportButton.onPressed, isNull);
  });
}

Future<void> _saveRecord(
  SooktaAppState state, {
  required SooktaActivity activity,
  required String activityName,
  required int beforeScore,
  required int afterScore,
  required RiskLevel beforeRisk,
  required RiskLevel afterRisk,
}) {
  return state.saveEvaluation(
    activity: activity,
    activityName: activityName,
    before: ErgoResult(
      riskLevel: beforeRisk,
      techScore: beforeScore.toDouble(),
      userScore: beforeScore,
      userScoreColor: beforeRisk.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_reba_high',
      economicLoss: beforeScore * 1000,
      bodyPartRisks: {BodyPart.trunk: beforeRisk},
    ),
    after: ErgoResult(
      riskLevel: afterRisk,
      techScore: afterScore.toDouble(),
      userScore: afterScore,
      userScoreColor: afterRisk.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_reba_med',
      economicLoss: afterScore * 1000,
      bodyPartRisks: {BodyPart.trunk: afterRisk},
    ),
    selectedSuggestionKeys: const [],
    selectedSuggestions: const ['ปรับท่าทาง'],
  );
}
