import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';

void main() {
  testWidgets('shows the latest draft and resumes its activity',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedToolId: 'basket_mid_10_15kg',
        rebaInput: RebaInputData(trunkScore: 4),
      ),
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const EvaluationMenuScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == EvaluationFormScreen.routeName) {
              final activity = settings.arguments as SooktaActivity;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => EvaluationFormScreen(activity: activity),
              );
            }
            return null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('แบบร่างล่าสุด'), findsOneWidget);
    expect(find.textContaining('การเก็บเกี่ยว'), findsWidgets);
    expect(find.text('กลับไปทำแบบร่างต่อ'), findsOneWidget);

    await tester.tap(find.text('กลับไปทำแบบร่างต่อ'));
    await tester.pumpAndSettle();

    expect(find.text('กิจกรรม: การเก็บเกี่ยว'), findsOneWidget);
    expect(find.text('นำข้อมูลแบบร่างกลับมาแล้ว'), findsOneWidget);
  });

  testWidgets('restores draft details into the evaluation form',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);

    await state.saveEvaluationDraft(
      const EvaluationDraft(
        activity: SooktaActivity.pesticide,
        jobType: JobType.pushPull,
        selectedToolId: 'sprayer_10_15kg',
        durationHours: 4,
        frequency: 6.5,
        staticHoldLevel: 2,
        workDaysPerWeek: 6,
        pushPullDistance: 30,
        initialForce: 20,
        sustainForce: 12,
        horizontalDistanceText: '44',
        verticalHeightText: '88',
        transportDistanceText: '12',
        showAdvancedDetails: true,
        rebaInput: RebaInputData(trunkScore: 5, couplingScore: 2),
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
          home: EvaluationFormScreen(activity: SooktaActivity.pesticide),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('นำข้อมูลแบบร่างกลับมาแล้ว'), findsOneWidget);
    expect(
        find.text('แรงเริ่มต้นดัน/ลาก', skipOffstage: false), findsOneWidget);
    expect(
      find.text('ค่าเริ่มต้นงานขนย้าย (20 N)', skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.text('ค่าเริ่มต้นงานขนย้าย (12 N)', skipOffstage: false),
      findsWidgets,
    );
  });
}
