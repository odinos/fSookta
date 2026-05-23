import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/app_text.dart';
import 'package:fsookta/app/assets.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';
import 'package:fsookta/core/theme/sookta_theme.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/history_detail_screen.dart';
import 'package:fsookta/screens/main/history_tab.dart';
import 'package:fsookta/screens/main/home_tab.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';
import 'package:fsookta/screens/main/profile_tab.dart';
import 'package:fsookta/screens/onboarding/avatar_selection_screen.dart';
import 'package:fsookta/screens/onboarding/language_selection_screen.dart';
import 'package:fsookta/screens/onboarding/setup_screen.dart';
import 'package:fsookta/widgets/responsive_content.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _disableDebugPaint();
  RendererBinding.instance.addPersistentFrameCallback((_) {
    _disableDebugPaint();
  });
  runApp(const ScreenshotHarnessApp());
}

void _disableDebugPaint() {
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintPointersEnabled = false;
  debugPaintSizeEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;
}

const _stressText = bool.fromEnvironment('SOOKTA_QA_STRESS_TEXT');
final _textScale =
    double.tryParse(const String.fromEnvironment('SOOKTA_QA_TEXT_SCALE')) ?? 1;

class ScreenshotHarnessApp extends StatefulWidget {
  const ScreenshotHarnessApp({super.key});

  @override
  State<ScreenshotHarnessApp> createState() => _ScreenshotHarnessAppState();
}

class _ScreenshotHarnessAppState extends State<ScreenshotHarnessApp> {
  final appState = SooktaAppState();
  late final ErgoResult before;
  late final ErgoResult after;
  late final EvaluationHistoryRecord record;
  var index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    before = ErgoCalculator.calculateRebaRisk(_rebaInput());
    after = before.copyWith(
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
    appState
      ..setLanguage(AppLanguage.th)
      ..saveProfile(
        const UserProfile(
          name: _stressText
              ? 'คุณสมหญิง กาแฟสวนดอยตัวอย่างชื่อยาวมาก'
              : 'Sookta QA',
          age: '45',
          gender: 'Female',
          weight: '55',
          height: '158',
          incomePerYear: _stressText ? '123456789' : '120000',
        ),
      )
      ..saveAvatarAndFinish(SooktaAssets.female01);
    record = appState.saveEvaluation(
      activityName: SooktaActivity.harvesting.label(thai: true),
      before: before,
      after: after,
      selectedSuggestions: const [
        if (_stressText)
          'หลีกเลี่ยงการก้มหลังค้างนาน และเปลี่ยนเป็นการย่อเข่าพร้อมพักเป็นช่วงสั้น ๆ'
        else
          'หลีกเลี่ยงการก้มหลังค้างนาน',
        if (_stressText)
          'ลดการยกแขนเหนือไหล่โดยปรับระดับงานให้ใกล้ลำตัวมากขึ้น'
        else
          'ลดการยกแขนเหนือไหล่',
      ],
    );
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _disableDebugPaint();
      if (!mounted) return;
      setState(() => index = (index + 1) % _screens.length);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    appState.dispose();
    super.dispose();
  }

  List<_HarnessScreen> get _screens {
    final text = const AppText(AppLanguage.th);
    return [
      const _HarnessScreen(
        '02_language_first_run',
        LanguageSelectionScreen(),
      ),
      const _HarnessScreen(
        '03_setup_first_run',
        SetupScreen(),
      ),
      const _HarnessScreen(
        '04_avatar_first_run',
        AvatarSelectionScreen(),
      ),
      _HarnessScreen(
        '05_home_avatar_asset',
        HomeTab(text: text, profile: appState.profile),
      ),
      _HarnessScreen(
        '06_profile',
        ProfileTab(text: text, profile: appState.profile),
      ),
      const _HarnessScreen(
        '07_profile_edit_setup',
        SetupScreen(editMode: true),
      ),
      const _HarnessScreen(
        '08_profile_change_language',
        LanguageSelectionScreen(editMode: true),
      ),
      const _HarnessScreen(
        '09_evaluation_menu',
        EvaluationMenuScreen(),
      ),
      const _HarnessScreen(
        '10_evaluation_form_top',
        EvaluationFormScreen(activity: SooktaActivity.fertilizing),
      ),
      _HarnessScreen(
        '11_initial_risk_top',
        InitialRiskScreen(
          payload: InitialRiskPayload(
            activity: SooktaActivity.harvesting,
            activityName: SooktaActivity.harvesting.label(thai: true),
            jobType: JobType.reba,
            before: before,
            ergoInput: const ErgoInputData(jobType: JobType.reba),
            rebaInput: _rebaInput(),
          ),
        ),
      ),
      _HarnessScreen(
        '12_final_result_top',
        FinalResultScreen(
          bundle: AssessmentBundle(
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
        ),
      ),
      _HarnessScreen(
        '13_history_list',
        HistoryTab(text: text, key: ValueKey(record.id)),
      ),
      _HarnessScreen(
        '14_history_detail_top',
        HistoryDetailScreen(historyId: record.id),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _disableDebugPaint();
    final screen = _screens[index];
    return AppStateScope(
      state: appState,
      child: MaterialApp(
        title: screen.name,
        debugShowCheckedModeBanner: false,
        theme: buildSooktaTheme(),
        builder: (context, child) {
          if (_textScale == 1) return child ?? const SizedBox.shrink();
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(_textScale)),
            child: ClampedTextScale(child: child ?? const SizedBox.shrink()),
          );
        },
        home: Stack(
          children: [
            screen.child,
            Positioned(
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.noScaling,
                      ),
                      child: Text(
                        screen.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarnessScreen {
  const _HarnessScreen(this.name, this.child);

  final String name;
  final Widget child;
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
