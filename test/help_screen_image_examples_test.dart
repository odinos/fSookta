import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/screens/main/help_screen.dart';

void main() {
  testWidgets('help screen shows activity-specific examples and full preview',
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

    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          routes: {
            ReferencesScreen.routeName: (_) => const ReferencesScreen(),
          },
          home: const HelpScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('คู่มือการใช้งาน'), findsOneWidget);
    expect(find.text('อ่านจากคู่มือ PDF ฉบับเต็ม'), findsOneWidget);
    expect(find.byKey(const ValueKey('manual_pdf_page_1')), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    expect(find.text('ตัวอย่างภาพที่ควรถ่ายตามหมวดงาน'), findsOneWidget);
    for (final activity in SooktaActivity.values) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('help_activity_example_${activity.name}')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('help_activity_example_${activity.name}')),
          findsOneWidget);
      expect(
        find.image(AssetImage(activity.readablePoseExampleAsset)),
        findsWidgets,
      );
    }

    final fertilizingExample =
        find.byKey(const ValueKey('help_activity_example_fertilizing'));
    await tester.ensureVisible(fertilizingExample);
    await tester.pumpAndSettle();
    await tester.tap(fertilizingExample);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('asset_image_full_preview')), findsOneWidget);
    expect(find.text('การใส่ปุ๋ย'), findsWidgets);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
