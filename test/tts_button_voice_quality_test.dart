import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/history_detail_screen.dart';
import 'package:fsookta/widgets/tts_button.dart';

void main() {
  final calls = <MethodCall>[];
  final spokenTexts = <String>[];

  setUp(() {
    calls.clear();
    spokenTexts.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        calls.add(call);
        switch (call.method) {
          case 'getVoices':
            return <Map<String, Object?>>[
              {
                'name': 'Kanya',
                'locale': 'th-TH',
                'quality': 'Default',
                'identifier': 'com.apple.ttsbundle.Kanya-compact',
              },
              {
                'name': 'Kanya',
                'locale': 'th-TH',
                'quality': 'Enhanced',
                'identifier': 'com.apple.ttsbundle.Kanya-enhanced',
              },
            ];
          case 'getLanguages':
            return <String>['th-TH', 'en-US'];
          case 'getDefaultVoice':
            return <String, Object?>{};
          case 'speak':
            spokenTexts.add(call.arguments.toString());
            return 1;
          default:
            return 1;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('uses natural Thai speech speed and readable phrasing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SooktaTtsButton(
            thai: true,
            text: '''
สรุปผลประเมิน: ก่อนปรับ คะแนน 8 ความเสี่ยงสูง
• หลังปรับ คะแนน 4 ความเสี่ยงปานกลาง
REBA / ISO11228 ลดลง 50% ใช้น้ำหนัก 10 kg''',
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();

    final speechRateCall =
        calls.singleWhere((call) => call.method == 'setSpeechRate');
    final pitchCall = calls.singleWhere((call) => call.method == 'setPitch');
    final voiceCall = calls.singleWhere((call) => call.method == 'setVoice');

    expect(speechRateCall.arguments, 0.46);
    expect(pitchCall.arguments, 0.97);
    expect(
      voiceCall.arguments.toString(),
      contains('com.apple.ttsbundle.Kanya-enhanced'),
    );
    expect(spokenTexts, hasLength(1));
    expect(spokenTexts.single, contains('สรุปผลประเมิน. ก่อนปรับ'));
    expect(spokenTexts.single, contains('หลังปรับ คะแนน 4'));
    expect(spokenTexts.single,
        contains('รีบา และ ไอ เอส โอ หนึ่ง หนึ่ง สอง สอง แปด'));
    expect(spokenTexts.single, contains('ร้อยละ 50'));
    expect(spokenTexts.single, contains('10 กิโลกรัม'));
  });

  testWidgets('history TTS receives the same localized recommendation shown',
      (tester) async {
    const localizedRecommendation =
        'Split fertilizer into smaller loads per round.';
    final record = EvaluationHistoryRecord(
      id: 1,
      activityName: 'Fertilizing',
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
    SharedPreferences.setMockInitialValues({
      'sookta.language': 'en',
      'sookta.history': jsonEncode([record.toJson()]),
    });
    final state = SooktaAppState();
    await state.restore();
    addTearDown(state.dispose);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: HistoryDetailScreen(historyId: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Selected Improvements'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(localizedRecommendation), findsOneWidget);

    final recommendationRow = find.ancestor(
      of: find.text(localizedRecommendation),
      matching: find.byType(Row),
    );
    final recommendationTtsButton = find.descendant(
      of: recommendationRow.first,
      matching: find.byIcon(Icons.volume_up),
    );
    await tester.ensureVisible(recommendationTtsButton);
    await tester.pump();
    await tester.tap(recommendationTtsButton);
    await tester.pump();

    expect(spokenTexts, [localizedRecommendation]);
  });
}
