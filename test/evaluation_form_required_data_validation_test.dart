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

  testWidgets('shows required data issues before assessment', (tester) async {
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.fertilizing,
        jobType: JobType.lifting,
        selectedImagePaths: ['photo-a.jpg'],
        selectedToolId: 'fertilizer_15_20kg',
        horizontalDistanceText: 'abc',
        verticalHeightText: '0',
        transportDistanceText: '',
        showAdvancedDetails: true,
      ),
    );

    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: const MaterialApp(
          home: EvaluationFormScreen(activity: SooktaActivity.fertilizing),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('กรุณาตรวจข้อมูลก่อนประเมิน'), findsOneWidget);
    expect(
      find.textContaining('ระยะห่าง H ต้องเป็นตัวเลขมากกว่า 0'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ความสูง V ต้องเป็นตัวเลขมากกว่า 0'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ระยะทางขนย้าย ต้องเป็นตัวเลขมากกว่า 0'),
      findsOneWidget,
    );
  });
}
