import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';

void main() {
  final spokenTexts = <String>[];

  setUp(() {
    spokenTexts.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        if (call.method == 'speak') {
          spokenTexts.add(call.arguments.toString());
          return 1;
        }
        return 1;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('shows farmer-first result summary before technical details',
      (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(home: FinalResultScreen(bundle: _bundle())),
      ),
    );
    await tester.pump();

    expect(find.text('สรุปสำหรับเกษตรกร'), findsOneWidget);
    expect(find.textContaining('ก่อนปรับ: ความเสี่ยงสูง'), findsOneWidget);
    expect(find.textContaining('หลังปรับ: ความเสี่ยงปานกลาง'), findsOneWidget);
    expect(find.textContaining('ควรทำต่อ'), findsOneWidget);
    expect(find.textContaining('รายละเอียดสำหรับเจ้าหน้าที่อยู่ด้านล่าง'),
        findsOneWidget);
    expect(
      tester.getTopLeft(find.text('สรุปสำหรับเกษตรกร')).dy,
      lessThan(tester.getTopLeft(find.text('เปรียบเทียบรายได้ที่สูญเสีย')).dy),
    );

    await tester.scrollUntilVisible(
      find.text('รายละเอียดสำหรับเจ้าหน้าที่และวิชาการ'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('วิธีประเมินที่ใช้'), findsNothing);

    await tester.tap(find.text('รายละเอียดสำหรับเจ้าหน้าที่และวิชาการ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('จุดเสี่ยงที่พบ'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('จุดเสี่ยงหลัก: หลัง/ลำตัว'), findsOneWidget);
    expect(find.textContaining('พบ 1 จุดเสี่ยง'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('วิธีประเมินที่ใช้'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('วิธีประเมินที่ใช้'), findsOneWidget);
  });

  testWidgets(
      'reads concise farmer guidance from the main result speech button',
      (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(home: FinalResultScreen(bundle: _bundle())),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.volume_up).first);
    await tester.pump();

    expect(spokenTexts, isNotEmpty);
    final speech = spokenTexts.single;
    expect(speech, contains('สรุปผลประเมิน'));
    expect(speech, contains('ก่อนปรับ คะแนน 8 ความเสี่ยงสูง'));
    expect(speech, contains('หลังปรับ คะแนน 4 ความเสี่ยงปานกลาง'));
    expect(speech, contains('ควรทำต่อ'));
    expect(speech, isNot(contains('ผลกระทบก่อนปรับ')));
    expect(speech.length, lessThanOrEqualTo(180));
  });
}

AssessmentBundle _bundle() {
  const before = ErgoResult(
    riskLevel: RiskLevel.high,
    techScore: 8,
    userScore: 8,
    userScoreColor: 0xFFFF5252,
    limitValue: 9,
    suggestionKey: 'sugg_reba_high',
    economicLoss: 12000,
    bodyPartRisks: {BodyPart.trunk: RiskLevel.high},
  );
  const after = ErgoResult(
    riskLevel: RiskLevel.medium,
    techScore: 4,
    userScore: 4,
    userScoreColor: 0xFFFFC107,
    limitValue: 9,
    suggestionKey: 'sugg_reba_medium',
    economicLoss: 6000,
    bodyPartRisks: {BodyPart.trunk: RiskLevel.medium},
  );
  return const AssessmentBundle(
    activity: SooktaActivity.fertilizing,
    activityName: 'การใส่ปุ๋ย',
    jobType: JobType.lifting,
    before: before,
    after: after,
    selectedSuggestionKeys: ['act_fert_split_load'],
    breakdown: AssessmentBreakdown(
      primaryMethod: AssessmentMethod.reba,
      rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
      rebaResult: before,
      ergoInput: ErgoInputData(jobType: JobType.lifting),
    ),
  );
}
