import 'dart:async';

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
import 'package:fsookta/screens/main/contact_screen.dart';
import 'package:fsookta/screens/main/daily_prediction_screen.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/farmer_manager_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/help_screen.dart';
import 'package:fsookta/screens/main/history_detail_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';
import 'package:fsookta/screens/main/main_tabs_screen.dart';
import 'package:fsookta/screens/onboarding/avatar_selection_screen.dart';
import 'package:fsookta/screens/onboarding/language_selection_screen.dart';
import 'package:fsookta/screens/onboarding/setup_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS full-page smoke renders every primary screen',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErrors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(const SooktaApp());
    await _pumpFor(tester, const Duration(seconds: 2));

    final context = tester.element(find.byType(MaterialApp));
    final state = AppStateScope.of(context);
    final nav = tester.state<NavigatorState>(find.byType(Navigator));

    await _waitForHydration(tester, state);
    _seedState(state);

    await _expectHealthy(tester, flutterErrors, 'launch and seed');

    await _walkLocalizedScreens(
      tester: tester,
      nav: nav,
      state: state,
      language: AppLanguage.th,
      flutterErrors: flutterErrors,
    );

    await _walkLocalizedScreens(
      tester: tester,
      nav: nav,
      state: state,
      language: AppLanguage.en,
      flutterErrors: flutterErrors,
    );
  });
}

Future<void> _walkLocalizedScreens({
  required WidgetTester tester,
  required NavigatorState nav,
  required SooktaAppState state,
  required AppLanguage language,
  required List<FlutterErrorDetails> flutterErrors,
}) async {
  final thai = language == AppLanguage.th;
  state.setLanguage(language);
  await _pumpFor(tester);

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: language first run',
    LanguageSelectionScreen.routeName,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: language edit',
    LanguageSelectionScreen.routeName,
    arguments: true,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: setup first run',
    SetupScreen.routeName,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: setup edit',
    SetupScreen.routeName,
    arguments: true,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: avatar',
    AvatarSelectionScreen.routeName,
  );

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: main tabs home',
    MainTabsScreen.routeName,
  );
  await _tapIfFound(tester, thai ? 'ผลตรวจ' : 'History');
  await _pumpFor(tester);
  await _expectHealthy(tester, flutterErrors, '${language.name}: history tab');
  await _tapIfFound(tester, thai ? 'ข้อมูลส่วนตัว' : 'Profile');
  await _pumpFor(tester);
  await _expectHealthy(tester, flutterErrors, '${language.name}: profile tab');

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: farmer manager',
    FarmerManagerScreen.routeName,
    exercise: () => _exerciseFarmerDialogs(tester, thai),
  );

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: evaluation menu',
    EvaluationMenuScreen.routeName,
  );

  for (final activity in SooktaActivity.values) {
    await _visit(
      tester,
      nav,
      flutterErrors,
      '${language.name}: evaluation form ${activity.name}',
      EvaluationFormScreen.routeName,
      arguments: activity,
      exercise: () => _exerciseEvaluationForm(tester, thai),
    );
  }

  final before = _beforeResult();
  final after = _afterResult(before);
  final breakdown = _breakdown(before);

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: initial risk',
    InitialRiskScreen.routeName,
    arguments: InitialRiskPayload(
      activity: SooktaActivity.harvesting,
      activityName: SooktaActivity.harvesting.label(thai: thai),
      jobType: JobType.reba,
      before: before,
      ergoInput: _ergoInput(),
      rebaInput: _rebaInput(),
      breakdown: breakdown,
    ),
    exercise: () async {
      await _toggleFirstCheckbox(tester);
      await _ensureTextIfFound(
        tester,
        thai ? 'ดูผลหลังปรับปรุง' : 'View Improved Result',
      );
    },
  );

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: final result',
    FinalResultScreen.routeName,
    arguments: AssessmentBundle(
      activity: SooktaActivity.harvesting,
      activityName: SooktaActivity.harvesting.label(thai: thai),
      jobType: JobType.reba,
      before: before,
      after: after,
      selectedSuggestionKeys: const [
        'act_avoid_bend',
        'act_raise_bed',
      ],
      breakdown: breakdown,
    ),
    exercise: () async {
      await _ensureTextIfFound(
        tester,
        thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
      );
      await _ensureTextIfFound(
        tester,
        thai
            ? 'ส่งออกไฟล์ Excel สำหรับเจ้าหน้าที่'
            : 'Export Excel file for staff',
      );
    },
  );

  final recordId = state.history.isNotEmpty ? state.history.first.id : 1;
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: history detail',
    HistoryDetailScreen.routeName,
    arguments: recordId,
    exercise: () => _ensureTextIfFound(
      tester,
      thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
    ),
  );

  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: daily prediction',
    DailyPredictionScreen.routeName,
    extraPump: const Duration(seconds: 2),
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: help',
    HelpScreen.routeName,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: references',
    ReferencesScreen.routeName,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: terms',
    TermsScreen.routeName,
  );
  await _visit(
    tester,
    nav,
    flutterErrors,
    '${language.name}: contact',
    ContactScreen.routeName,
  );

  debugPrint('IOS_FULL_UAT_LANGUAGE_PASS: ${language.name}');
}

Future<void> _visit(
  WidgetTester tester,
  NavigatorState nav,
  List<FlutterErrorDetails> flutterErrors,
  String label,
  String routeName, {
  Object? arguments,
  Future<void> Function()? exercise,
  Duration extraPump = Duration.zero,
}) async {
  // Use print instead of debugPrint so long real-device runs expose the
  // current route even if Flutter throttles debug logs.
  // ignore: avoid_print
  print('IOS_FULL_UAT_SCREEN_START: $label');
  unawaited(nav.pushNamedAndRemoveUntil(
    routeName,
    (_) => false,
    arguments: arguments,
  ));
  await _pumpFor(tester, const Duration(milliseconds: 900));
  if (extraPump > Duration.zero) await _pumpFor(tester, extraPump);
  if (exercise != null) {
    await exercise();
    await _pumpFor(tester);
  }
  await _expectHealthy(tester, flutterErrors, label);
  // ignore: avoid_print
  print('IOS_FULL_UAT_SCREEN_PASS: $label');
}

Future<void> _exerciseFarmerDialogs(WidgetTester tester, bool thai) async {
  await _tapIfFound(tester, thai ? 'เพิ่มคน' : 'Add');
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ยกเลิก' : 'Cancel');
  await _pumpFor(tester);

  await _tapIconIfFound(tester, Icons.edit_outlined);
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ยกเลิก' : 'Cancel');
  await _pumpFor(tester);

  await _tapIconIfFound(tester, Icons.delete_outline);
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ยกเลิก' : 'Cancel');
}

Future<void> _exerciseEvaluationForm(WidgetTester tester, bool thai) async {
  await _tapIfFound(
    tester,
    thai ? 'ปรับรายละเอียด ถ้าทราบ' : 'Adjust Details if Known',
  );
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ยก/แบก' : 'Lift');
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ดัน/ดึง' : 'Push');
  await _pumpFor(tester);
  await _tapIfFound(tester, thai ? 'ท่าทาง' : 'Posture');
  await _ensureTextIfFound(
    tester,
    thai ? 'ดูผลประเมิน' : 'View Assessment',
  );
}

Future<void> _toggleFirstCheckbox(WidgetTester tester) async {
  final checkbox = find.byType(CheckboxListTile);
  if (checkbox.evaluate().isEmpty) return;
  await tester.ensureVisible(checkbox.first);
  await tester.tap(checkbox.first);
}

Future<void> _tapIfFound(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder.last);
  await tester.tap(finder.last);
}

Future<void> _ensureTextIfFound(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder.last);
  await _pumpFor(tester, const Duration(milliseconds: 120));
}

Future<void> _tapIconIfFound(WidgetTester tester, IconData icon) async {
  final finder = find.byIcon(icon);
  if (finder.evaluate().isEmpty) return;
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
}

Future<void> _expectHealthy(
  WidgetTester tester,
  List<FlutterErrorDetails> flutterErrors,
  String label,
) async {
  final exception = tester.takeException();
  expect(exception, isNull, reason: 'Unexpected widget exception on $label');
  final suspicious = flutterErrors.where((details) {
    final text = '${details.exception}\n${details.stack}';
    return text.contains('overflowed') ||
        text.contains('NoSuchMethod') ||
        text.contains('setState() called after dispose') ||
        text.contains('RenderFlex') ||
        text.contains('Assertion failed');
  }).toList();
  expect(
    suspicious,
    isEmpty,
    reason:
        'Flutter layout/runtime errors were captured while rendering $label',
  );
  flutterErrors.clear();
}

Future<void> _pumpFor(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 350),
]) async {
  const frame = Duration(milliseconds: 50);
  var elapsed = Duration.zero;
  await tester.pump();
  while (elapsed < duration) {
    await tester.pump(frame);
    elapsed += frame;
  }
}

Future<void> _waitForHydration(
  WidgetTester tester,
  SooktaAppState state,
) async {
  for (var i = 0; i < 30 && !state.hydrated; i += 1) {
    await _pumpFor(tester, const Duration(milliseconds: 100));
  }
}

void _seedState(SooktaAppState state) {
  const primary = UserProfile(
    farmerId: 'FSK-UAT-IOS-001',
    name: 'Sookta QA iOS',
    role: 'ชาวสวน',
    location: 'สวนทดสอบ',
    age: '45',
    gender: 'Female',
    weight: '55',
    height: '158',
    incomePerYear: '120000',
    avatarAsset: SooktaAssets.female01,
  );
  const secondary = UserProfile(
    farmerId: 'FSK-UAT-IOS-002',
    name: 'Research Staff',
    role: 'เจ้าหน้าที่',
    location: 'UAT Field',
    age: '34',
    gender: 'Male',
    weight: '70',
    height: '170',
    incomePerYear: '150000',
    avatarAsset: SooktaAssets.male01,
  );

  state
    ..setLanguage(AppLanguage.th)
    ..addFarmer(primary)
    ..addFarmer(secondary);
  state.selectFarmer(state.farmers.first.profileId);
  state.saveAvatarAndFinish(SooktaAssets.female01);

  final before = _beforeResult();
  final after = _afterResult(before);
  final activities = SooktaActivity.values;
  for (var index = 0; index < 7; index += 1) {
    final activity = activities[index % activities.length];
    state.saveEvaluation(
      activity: activity,
      activityName: activity.label(thai: true),
      before: before,
      after: after,
      selectedSuggestions: const [
        'ยกแปลงหรือวางงานให้สูงขึ้น',
        'พักและยืดเหยียดเป็นระยะ',
      ],
      assessmentBreakdown: _breakdown(before),
    );
  }
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

ErgoInputData _ergoInput() {
  return const ErgoInputData(
    jobType: JobType.reba,
    gender: 'female',
    dailyIncome: 350,
    durationHours: 4,
    liftFrequency: 6.5,
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

AssessmentBreakdown _breakdown(ErgoResult before) {
  return AssessmentBreakdown(
    primaryMethod: AssessmentMethod.reba,
    rebaInput: _rebaInput(),
    rebaResult: before,
    ergoInput: _ergoInput(),
  );
}
