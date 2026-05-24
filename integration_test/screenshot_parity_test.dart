import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/assets.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/history_detail_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';
import 'package:fsookta/screens/main/main_tabs_screen.dart';
import 'package:fsookta/screens/onboarding/avatar_selection_screen.dart';
import 'package:fsookta/screens/onboarding/language_selection_screen.dart';
import 'package:fsookta/screens/onboarding/setup_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures iPhone screenshot parity screens', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await tester.pumpWidget(const SooktaApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.convertFlutterSurfaceToImage();

    await _shot(binding, tester, '02_language_first_run');

    final context = tester.element(find.byType(MaterialApp));
    final state = AppStateScope.of(context);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    final before = _beforeResult();
    final after = _afterResult(before);

    state.setLanguage(AppLanguage.th);
    await _replace(nav, tester, SetupScreen.routeName);
    await _shot(binding, tester, '03_setup_first_run');

    state.saveProfile(
      const UserProfile(
        name: 'Sookta QA',
        age: '45',
        gender: 'Female',
        weight: '55',
        height: '158',
        incomePerYear: '120000',
      ),
    );
    await _replace(nav, tester, AvatarSelectionScreen.routeName);
    await _shot(binding, tester, '04_avatar_first_run');

    state.saveAvatarAndFinish(SooktaAssets.female01);
    await _replace(nav, tester, MainTabsScreen.routeName);
    await _shot(binding, tester, '05_home_avatar_asset');

    await _tapText(tester, 'ข้อมูลส่วนตัว');
    await _shot(binding, tester, '06_profile');

    await nav.pushNamed(SetupScreen.routeName, arguments: true);
    await _settle(tester);
    await _shot(binding, tester, '07_profile_edit_setup');
    nav.pop();
    await _settle(tester);

    await nav.pushNamed(LanguageSelectionScreen.routeName, arguments: true);
    await _settle(tester);
    await _shot(binding, tester, '08_profile_change_language');
    nav.pop();
    await _settle(tester);

    await _tapText(tester, 'หน้าแรก');
    await nav.pushNamed(EvaluationMenuScreen.routeName);
    await _settle(tester);
    await _shot(binding, tester, '09_evaluation_menu');

    await nav.pushNamed(
      EvaluationFormScreen.routeName,
      arguments: SooktaActivity.fertilizing,
    );
    await _settle(tester);
    await _shot(binding, tester, '10_evaluation_form_top');
    await _dragUntilVisible(tester, find.text('เริ่มวิเคราะห์ความเสี่ยง'));
    await _shot(binding, tester, '10_evaluation_form_bottom');

    await nav.pushNamed(
      InitialRiskScreen.routeName,
      arguments: InitialRiskPayload(
        activity: SooktaActivity.harvesting,
        activityName: SooktaActivity.harvesting.label(thai: true),
        jobType: JobType.reba,
        before: before,
        ergoInput: const ErgoInputData(jobType: JobType.reba),
        rebaInput: _rebaInput(),
      ),
    );
    await _settle(tester);
    await _shot(binding, tester, '11_initial_risk_top');
    await _dragUntilVisible(tester, find.textContaining('ตำแหน่งที่เสี่ยง'));
    await _shot(binding, tester, '11_initial_risk_body_map');
    await _dragUntilVisible(tester, find.text('สรุปผลการปรับปรุง'));
    await _shot(binding, tester, '11_initial_risk_suggestions');

    await nav.pushNamed(
      FinalResultScreen.routeName,
      arguments: AssessmentBundle(
        activity: SooktaActivity.harvesting,
        activityName: SooktaActivity.harvesting.label(thai: true),
        jobType: JobType.reba,
        before: before,
        after: after,
        selectedSuggestionKeys: const [
          'act_avoid_bend',
          'act_reduce_arm_raise',
        ],
      ),
    );
    await _settle(tester);
    await _shot(binding, tester, '12_final_result_top');
    await _dragUntilVisible(tester, find.text('จุดเสี่ยงที่พบ'));
    await _shot(binding, tester, '12_final_result_body_map');

    final record = state.saveEvaluation(
      activityName: SooktaActivity.harvesting.label(thai: true),
      before: before,
      after: after,
      selectedSuggestions: const [
        'หลีกเลี่ยงการก้มหลังค้างนาน',
        'ลดการยกแขนเหนือไหล่',
      ],
    );

    await _replace(nav, tester, MainTabsScreen.routeName);
    await _tapText(tester, 'ผลตรวจ');
    await _shot(binding, tester, '13_history_list');

    await nav.pushNamed(HistoryDetailScreen.routeName, arguments: record.id);
    await _settle(tester);
    await _shot(binding, tester, '14_history_detail_top');
    await _dragUntilVisible(tester, find.text('จุดเสี่ยงที่พบ'));
    await _shot(binding, tester, '14_history_detail_body_map');
  });
}

RebaInputData _rebaInput() {
  return const RebaInputData(
    dailyIncome: 350,
    trunkScore: 4,
    neckScore: 2,
    legScore: 2,
    upperArmScore: 4,
    lowerArmScore: 2,
    wristScore: 2,
    trunkTwist: true,
    trunkSideFlex: true,
    wristTwist: true,
    loadScore: 1,
    couplingScore: 1,
    activityScore: 2,
  );
}

ErgoResult _beforeResult() {
  return ErgoCalculator.calculateRebaRisk(_rebaInput());
}

ErgoResult _afterResult(ErgoResult before) {
  return before.copyWith(
    riskLevel: RiskLevel.medium,
    techScore: 6,
    userScore: 5,
    userScoreColor: 0xFFFFF176,
    economicLoss: (before.economicLoss * 0.45).round(),
    bodyPartRisks: const {
      BodyPart.neck: RiskLevel.medium,
      BodyPart.trunk: RiskLevel.medium,
      BodyPart.legs: RiskLevel.medium,
      BodyPart.arms: RiskLevel.medium,
      BodyPart.wrists: RiskLevel.medium,
    },
  );
}

Future<void> _replace(
  NavigatorState nav,
  WidgetTester tester,
  String routeName, {
  Object? arguments,
}) async {
  await nav.pushNamedAndRemoveUntil(
    routeName,
    (_) => false,
    arguments: arguments,
  );
  await _settle(tester);
}

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
  await binding.takeScreenshot(name);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _dragUntilVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).last,
    const Offset(0, -320),
    maxIteration: 12,
  );
  await _settle(tester);
}
