import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';

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
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  for (final language in const <AppLanguage>[
    AppLanguage.th,
    AppLanguage.en,
  ]) {
    for (final screen in _screens(thai: language == AppLanguage.th)) {
      testWidgets(
        '${screen.name}/${language.name} has the same iPhone and Android contract',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final captures = <String, _CapturedContract>{};

          try {
            for (final viewport in const <_Viewport>[
              _Viewport('ios', Size(390, 844), TargetPlatform.iOS),
              _Viewport('android', Size(412, 915), TargetPlatform.android),
            ]) {
              debugDefaultTargetPlatformOverride = viewport.platform;
              tester.view.physicalSize = viewport.size;
              tester.view.devicePixelRatio = 1;

              final state = SooktaAppState()..setLanguage(language);
              await tester.pumpWidget(
                AppStateScope(
                  state: state,
                  child: MaterialApp(home: screen.build()),
                ),
              );
              await tester.pump();

              final capture = await _captureEntireScreen(
                tester,
                requiredKeys: screen.requiredKeys,
              );
              for (final expected in screen.requiredText) {
                expect(
                  capture.texts,
                  contains(expected),
                  reason: '${screen.name}/${language.name}/${viewport.name}',
                );
              }
              expect(
                capture.keys,
                containsAll(screen.requiredKeys),
                reason: '${screen.name}/${language.name}/${viewport.name}',
              );
              expect(tester.takeException(), isNull);
              captures[viewport.name] = capture;

              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
              state.dispose();
            }
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }

          expect(captures['android']?.texts, equals(captures['ios']?.texts));
          expect(captures['android']?.keys, equals(captures['ios']?.keys));
        },
      );
    }
  }
}

class _Viewport {
  const _Viewport(this.name, this.size, this.platform);

  final String name;
  final Size size;
  final TargetPlatform platform;
}

class _CapturedContract {
  const _CapturedContract({
    required this.texts,
    required this.keys,
  });

  final Set<String> texts;
  final Set<String> keys;
}

Future<_CapturedContract> _captureEntireScreen(
  WidgetTester tester, {
  required List<String> requiredKeys,
}) async {
  final texts = <String>{};
  final keys = <String>{};

  void captureBuiltWidgets() {
    texts.addAll(
      tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .where((text) => text.trim().isNotEmpty),
    );
    for (final key in requiredKeys) {
      if (find.byKey(ValueKey<String>(key)).evaluate().isNotEmpty) {
        keys.add(key);
      }
    }
  }

  captureBuiltWidgets();
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    return _CapturedContract(texts: texts, keys: keys);
  }

  final primaryScrollable = scrollables.first;
  for (var attempt = 0; attempt < 60; attempt += 1) {
    final position = tester.state<ScrollableState>(primaryScrollable).position;
    if (position.extentAfter <= 0) break;
    final previousPixels = position.pixels;
    await tester.drag(primaryScrollable, const Offset(0, -560));
    await tester.pump();
    expect(tester.takeException(), isNull);
    captureBuiltWidgets();
    final currentPixels =
        tester.state<ScrollableState>(primaryScrollable).position.pixels;
    if (currentPixels == previousPixels) break;
  }

  return _CapturedContract(texts: texts, keys: keys);
}

class _ScreenContract {
  const _ScreenContract({
    required this.name,
    required this.build,
    required this.requiredText,
    this.requiredKeys = const <String>[],
  });

  final String name;
  final Widget Function() build;
  final List<String> requiredText;
  final List<String> requiredKeys;
}

List<_ScreenContract> _screens({required bool thai}) {
  return <_ScreenContract>[
    _ScreenContract(
      name: 'farmer workflow entry',
      build: EvaluationMenuScreen.new,
      requiredText: thai
          ? const <String>[
              'เลือกประเภทงาน',
              'โปรดเลือกกิจกรรมที่ต้องการประเมิน',
              'การปลูกกล้า',
              'การใส่ปุ๋ย',
            ]
          : const <String>[
              'Select Job Type',
              'Please select an activity to evaluate',
              'Planting',
              'Fertilizing',
            ],
    ),
    _ScreenContract(
      name: 'evaluation form',
      build: () => const EvaluationFormScreen(
        activity: SooktaActivity.fertilizing,
      ),
      requiredText: thai
          ? const <String>[
              'แบบฟอร์มประเมิน',
              'กิจกรรม: การใส่ปุ๋ย',
              'ดูผลประเมิน',
            ]
          : const <String>[
              'Evaluation Form',
              'Activity: Fertilizing',
              'View Assessment',
            ],
    ),
    _ScreenContract(
      name: 'risk reduction selection',
      build: () => InitialRiskScreen(payload: _initialPayload(thai: thai)),
      requiredText: thai
          ? const <String>[
              'ผลการประเมินเบื้องต้น',
              'เลือกวิธีลดความเสี่ยง',
              'ดูผลหลังปรับปรุง',
            ]
          : const <String>[
              'Initial Assessment',
              'Choose risk-reduction actions',
              'View Improved Result',
            ],
      requiredKeys: const <String>[
        'risk-action-group-posture',
        'risk-action-group-riskReduction',
        'risk-action-group-restRotation',
        'risk-action-group-workloadSupport',
      ],
    ),
    _ScreenContract(
      name: 'final farmer result',
      build: () => FinalResultScreen(bundle: _bundle(thai: thai)),
      requiredText: thai
          ? const <String>[
              'สรุปสำหรับเกษตรกร',
              'คำแนะนำตามกิจกรรมและความเสี่ยง',
            ]
          : const <String>[
              'Farmer summary',
              'Recommendations by activity and risk',
            ],
      requiredKeys: const <String>[
        'recommendation-group-posture',
        'recommendation-group-riskReduction',
        'recommendation-group-restRotation',
        'recommendation-group-workloadSupport',
      ],
    ),
  ];
}

InitialRiskPayload _initialPayload({required bool thai}) {
  return InitialRiskPayload(
    activity: SooktaActivity.fertilizing,
    activityName: SooktaActivity.fertilizing.label(thai: thai),
    jobType: JobType.lifting,
    before: _before,
    ergoInput: const ErgoInputData(jobType: JobType.lifting),
    rebaInput: const RebaInputData(trunkScore: 4, neckScore: 2),
  );
}

AssessmentBundle _bundle({required bool thai}) {
  return AssessmentBundle(
    activity: SooktaActivity.fertilizing,
    activityName: SooktaActivity.fertilizing.label(thai: thai),
    jobType: JobType.lifting,
    before: _before,
    after: _after,
    selectedSuggestionKeys: const <String>['act_fert_split_load'],
    breakdown: const AssessmentBreakdown(
      primaryMethod: AssessmentMethod.reba,
      rebaInput: RebaInputData(trunkScore: 4, neckScore: 2),
      rebaResult: _before,
      ergoInput: ErgoInputData(jobType: JobType.lifting),
    ),
  );
}

const _before = ErgoResult(
  riskLevel: RiskLevel.high,
  techScore: 8,
  userScore: 8,
  userScoreColor: 0xFFFF5252,
  limitValue: 9,
  suggestionKey: 'sugg_reba_high',
  economicLoss: 12000,
  bodyPartRisks: <BodyPart, RiskLevel>{BodyPart.trunk: RiskLevel.high},
);

const _after = ErgoResult(
  riskLevel: RiskLevel.medium,
  techScore: 4,
  userScore: 4,
  userScoreColor: 0xFFFFC107,
  limitValue: 9,
  suggestionKey: 'sugg_reba_medium',
  economicLoss: 6000,
  bodyPartRisks: <BodyPart, RiskLevel>{BodyPart.trunk: RiskLevel.medium},
);
