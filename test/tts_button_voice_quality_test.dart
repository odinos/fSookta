import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/widgets/tts_button.dart';

void main() {
  final calls = <MethodCall>[];
  final spokenTexts = <String>[];

  setUp(() {
    calls.clear();
    spokenTexts.clear();
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
    expect(spokenTexts.single, contains('รีบา และ ไอ เอส โอ หนึ่ง หนึ่ง สอง สอง แปด'));
    expect(spokenTexts.single, contains('ร้อยละ 50'));
    expect(spokenTexts.single, contains('10 กิโลกรัม'));
  });
}
