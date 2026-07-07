import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('shows four named image angles with complete and missing states',
      (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths: ['photo-a.jpg', 'photo-b.jpg'],
        selectedToolId: 'basket_mid_10_15kg',
      ),
    );

    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: EvaluationFormScreen(activity: SooktaActivity.harvesting),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ภาพครบ 2 จาก 4 มุม'), findsOneWidget);
    expect(find.text('มุมที่ 1: เห็นท่าทางหลัก'), findsOneWidget);
    expect(find.text('มุมที่ 2: ด้านข้างซ้าย'), findsOneWidget);
    expect(find.text('มุมที่ 3: ด้านข้างขวา'), findsOneWidget);
    expect(find.text('มุมที่ 4: มุมที่เห็นงานจริงชัดที่สุด'), findsOneWidget);
    expect(find.text('มีภาพแล้ว'), findsNWidgets(2));
    expect(find.text('ยังไม่มีภาพ'), findsNWidgets(2));
    expect(find.text('เปลี่ยนภาพ'), findsNWidgets(2));
  });

  testWidgets('shows missing image guidance before assessment', (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths: ['photo-a.jpg', 'photo-b.jpg'],
        selectedToolId: 'basket_mid_10_15kg',
      ),
    );

    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: EvaluationFormScreen(activity: SooktaActivity.harvesting),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ตรวจภาพก่อนประเมิน'), findsOneWidget);
    expect(find.textContaining('ยังขาดอีก 2 มุม'), findsOneWidget);
    expect(find.textContaining('ถ่ายเพิ่มให้ครบ 4 มุม'), findsOneWidget);
  });

  testWidgets('shows retake guidance when selected images are not ready',
      (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths: [
          'photo-a.jpg',
          'photo-b.jpg',
          'photo-c.jpg',
          'photo-d.jpg',
        ],
        selectedToolId: 'basket_mid_10_15kg',
      ),
    );

    tester.view.physicalSize = const Size(1080, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: EvaluationFormScreen(activity: SooktaActivity.harvesting),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ตรวจภาพก่อนประเมิน'), findsOneWidget);
    expect(find.textContaining('ยังอ่านท่าทางไม่ได้'), findsOneWidget);
    expect(find.textContaining('ถ่ายใหม่ให้เห็นศีรษะ หลัง แขน มือ ขา และเท้า'),
        findsOneWidget);
  });
}
