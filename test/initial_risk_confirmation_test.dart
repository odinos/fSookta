import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';

void main() {
  testWidgets('requires activity and posture confirmation before final result',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: InitialRiskScreen(
            payload: InitialRiskPayload(
              activity: SooktaActivity.fertilizing,
              activityName: 'การใส่ปุ๋ย',
              jobType: JobType.lifting,
              before: ErgoResult(
                riskLevel: RiskLevel.high,
                techScore: 8,
                userScore: 8,
                userScoreColor: 0xFFFF5252,
                limitValue: 9,
                suggestionKey: 'sugg_reba_high',
                economicLoss: 12000,
                bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
              ),
              ergoInput: ErgoInputData(jobType: JobType.lifting),
              rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final category in const [
      'posture',
      'riskReduction',
      'restRotation',
      'workloadSupport',
    ]) {
      expect(
        find.byKey(ValueKey('risk-action-group-$category')),
        findsOneWidget,
      );
    }
    expect(
      find.textContaining('ลดน้ำหนักปุ๋ยต่อครั้ง ใช้สายพาน'),
      findsNothing,
    );
    final actionTitles = tester
        .widgetList<Text>(find.descendant(
          of: find.byKey(const ValueKey('risk-action-groups')),
          matching: find.byType(Text),
        ))
        .map((widget) => widget.data ?? '')
        .where((text) => text.isNotEmpty);
    expect(actionTitles.every((text) => text.length <= 70), isTrue);

    expect(find.text('ตรวจสอบข้อมูลก่อนบันทึก'), findsOneWidget);
    expect(
      find.textContaining('การใส่ปุ๋ย', skipOffstage: false),
      findsWidgets,
    );
    expect(find.text('ยก/แบก', skipOffstage: false), findsWidgets);
    expect(
      find.text('แก้ท่าทาง/รายละเอียดประเมิน', skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text('เลือกกิจกรรมใหม่', skipOffstage: false),
      findsOneWidget,
    );

    final finalButton = find.widgetWithText(FilledButton, 'ดูผลหลังปรับปรุง');
    expect(tester.widget<FilledButton>(finalButton).onPressed, isNull);

    await tester.tap(find.text('ยืนยันข้อมูลถูกต้องก่อนบันทึก'));
    await tester.pump();

    expect(tester.widget<FilledButton>(finalButton).onPressed, isNotNull);
  });
}
