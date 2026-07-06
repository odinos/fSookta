import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/theme/sookta_theme.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';

void main() {
  testWidgets('evaluation form uses a readable example for each activity',
      (tester) async {
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

    for (final activity in SooktaActivity.values) {
      final state = SooktaAppState()..setLanguage(AppLanguage.th);
      addTearDown(state.dispose);

      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        AppStateScope(
          state: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildSooktaTheme(),
            home: EvaluationFormScreen(activity: activity),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('ตัวอย่างภาพ: ${activity.label(thai: true)}'),
        findsOneWidget,
      );
      expect(
        find.image(AssetImage(activity.readablePoseExampleAsset)),
        findsOneWidget,
      );
    }
  });
}
