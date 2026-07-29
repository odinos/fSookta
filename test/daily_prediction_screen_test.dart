import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/daily_prediction_screen.dart';
import 'package:fsookta/screens/main/risk_reduction_potential_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('trend screen shows actual risk only and links improvement page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await _stateWithSevenRecords();
    addTearDown(state.dispose);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          routes: {
            RiskReductionPotentialScreen.routeName: (_) =>
                const RiskReductionPotentialScreen(),
          },
          home: const DailyPredictionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('แนวโน้มความเสี่ยงจาก 7 ครั้งล่าสุด'), findsOneWidget);
    expect(find.textContaining('แนวโน้มก่อนและหลังปรับปรุง'), findsWidgets);
    expect(find.textContaining('REBA ก่อนปรับปรุง'), findsWidgets);
    expect(find.textContaining('REBA หลังปรับปรุง'), findsWidgets);
    expect(find.textContaining('ISO11228 ก่อนปรับปรุง'), findsWidgets);
    expect(find.textContaining('ISO11228 หลังปรับปรุง'), findsWidgets);
    expect(
      find.textContaining('คะแนนก่อน/หลังปรับปรุง 7 ครั้งล่าสุด'),
      findsWidgets,
    );
    expect(find.textContaining('ระดับแนวโน้มด้านล่าง'), findsWidgets);
    expect(find.textContaining('ลดลงเฉลี่ย'), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('REBA ล่าสุด'),
      240,
    );
    expect(find.textContaining('REBA ล่าสุด'), findsWidgets);
    expect(find.textContaining('REBA เฉลี่ย 7 ครั้งล่าสุด'), findsWidgets);
    expect(find.textContaining('REBA สูงสุด'), findsWidgets);
    expect(find.textContaining('ความเสี่ยงสูง'), findsWidgets);
    expect(find.textContaining('ISO11228'), findsWidgets);
    expect(find.textContaining('ทำตามคำแนะนำแล้วดีขึ้น'), findsNothing);

    await tester.scrollUntilVisible(
      find.textContaining('ค่าจริงที่ใช้ดูแนวโน้ม'),
      240,
    );
    expect(
      find.textContaining('ระบบใช้ผลก่อนปรับปรุงเป็นฐานคำนวณระดับแนวโน้ม'),
      findsWidgets,
    );
    expect(
      find.textContaining('ผลหลังปรับปรุงถูกใช้เพื่อเปรียบเทียบ'),
      findsWidgets,
    );
    expect(
      find.textContaining('ยังไม่ใช่ผลทำนายจากข้อมูลอาการหรือการรักษาจริง'),
      findsWidgets,
    );
    await tester.scrollUntilVisible(
      find.textContaining('หมายเหตุ: หน้านี้ใช้เพื่อดูแนวโน้ม'),
      240,
    );
    expect(
      find.textContaining('โมเดล Logistic ปัจจุบันยังเป็นต้นแบบ'),
      findsOneWidget,
    );

    final improvementButton =
        find.widgetWithText(OutlinedButton, 'ดูศักยภาพการลดความเสี่ยง');
    await tester.scrollUntilVisible(
      improvementButton,
      240,
    );
    await tester.tap(improvementButton);
    await tester.pumpAndSettle();

    expect(find.text('ศักยภาพการลดความเสี่ยง'), findsWidgets);
    expect(find.text('REBA'), findsWidgets);
    expect(find.text('ISO11228'), findsWidgets);
    expect(find.textContaining('ก่อนประเมิน'), findsWidgets);
    expect(find.textContaining('หลังประเมิน'), findsWidgets);
    expect(find.textContaining('แนวโน้มก่อนและหลังปรับปรุง'), findsWidgets);
    expect(find.textContaining('REBA ก่อน'), findsWidgets);
    expect(find.textContaining('ISO หลัง'), findsWidgets);
  });
}

Future<SooktaAppState> _stateWithSevenRecords() async {
  final state = SooktaAppState()
    ..setLanguage(AppLanguage.th)
    ..saveProfile(
      const UserProfile(
        profileId: 'profile-trend',
        farmerId: 'FARM-TREND',
        name: 'ชาวสวนทดสอบ',
      ),
    );
  for (var day = 1; day <= 7; day += 1) {
    await state.saveEvaluation(
      activityName: 'การขนย้ายผลผลิต',
      activity: SooktaActivity.transport,
      before: ErgoResult(
        riskLevel: RiskLevel.high,
        techScore: 9,
        userScore: 9,
        userScoreColor: RiskLevel.high.colorHex,
        limitValue: 9,
        suggestionKey: 'sugg_high',
        bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
      ),
      after: ErgoResult(
        riskLevel: RiskLevel.medium,
        techScore: 4,
        userScore: 4,
        userScoreColor: RiskLevel.medium.colorHex,
        limitValue: 9,
        suggestionKey: 'sugg_after',
      ),
      selectedSuggestions: const ['ใช้รถเข็น'],
      assessmentBreakdown: _breakdown(day),
      afterAssessmentBreakdown: _afterBreakdown(day),
    );
  }
  return state;
}

AssessmentBreakdown _breakdown(int day) {
  return AssessmentBreakdown(
    primaryMethod: AssessmentMethod.rebaIsoCombined,
    rebaInput: const RebaInputData(trunkScore: 4, neckScore: 2),
    rebaResult: ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: day.isEven ? 8 : 9,
      userScore: day.isEven ? 8 : 9,
      userScoreColor: RiskLevel.high.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_reba_high',
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
    ),
    ergoInput: const ErgoInputData(
      jobType: JobType.lifting,
      toolWeightKg: 14,
      loadWeight: 14,
      liftFrequency: 22 / 60,
      durationHours: 2,
      transportDistance: 6,
    ),
    isoMethod: AssessmentMethod.iso11228Lifting,
    isoResult: ErgoResult(
      riskLevel: RiskLevel.high,
      techScore: day.isEven ? 7 : 8,
      userScore: day.isEven ? 7 : 8,
      userScoreColor: RiskLevel.high.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_iso_high',
    ),
  );
}

AssessmentBreakdown _afterBreakdown(int day) {
  return AssessmentBreakdown(
    primaryMethod: AssessmentMethod.rebaIsoCombined,
    rebaInput: const RebaInputData(trunkScore: 2, neckScore: 1),
    rebaResult: ErgoResult(
      riskLevel: RiskLevel.medium,
      techScore: day.isEven ? 4 : 5,
      userScore: day.isEven ? 4 : 5,
      userScoreColor: RiskLevel.medium.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_reba_med',
    ),
    ergoInput: const ErgoInputData(
      jobType: JobType.lifting,
      toolWeightKg: 8,
      loadWeight: 8,
      liftFrequency: 10 / 60,
      durationHours: 2,
      transportDistance: 4,
    ),
    isoMethod: AssessmentMethod.iso11228Lifting,
    isoResult: ErgoResult(
      riskLevel: RiskLevel.medium,
      techScore: day.isEven ? 3 : 4,
      userScore: day.isEven ? 3 : 4,
      userScoreColor: RiskLevel.medium.colorHex,
      limitValue: 9,
      suggestionKey: 'sugg_iso_med',
    ),
  );
}
