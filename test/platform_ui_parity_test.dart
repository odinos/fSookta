import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';
import 'package:fsookta/core/services/recommendation_catalog_service.dart';
import 'package:fsookta/core/services/risk_recommendation_service.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/evaluation_menu_screen.dart';
import 'package:fsookta/screens/main/final_result_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';
import 'package:fsookta/widgets/tts_button.dart';

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
                recommendation: screen.recommendation,
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
              final expectedRecommendation = screen.recommendation;
              if (expectedRecommendation != null) {
                final resolved = _resolvedRecommendationContract(language);
                expect(
                  resolved.selectionKeys,
                  expectedRecommendation.selectionKeys,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/selection keys',
                );
                expect(
                  resolved.displayItemIds,
                  expectedRecommendation.displayItemIds,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/display-item IDs',
                );
                expect(
                  resolved.categoryOrder,
                  expectedRecommendation.categoryOrder,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/resolved category order',
                );
                if (screen.selectionKeysVisible) {
                  expect(
                    capture.selectionKeys,
                    expectedRecommendation.selectionKeys,
                    reason:
                        '${screen.name}/${language.name}/${viewport.name}/visible selection keys',
                  );
                }
                expect(
                  capture.categoryOrder,
                  expectedRecommendation.categoryOrder,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/visible category order',
                );
                expect(
                  capture.displayTexts,
                  expectedRecommendation.displayTexts,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/display text',
                );
                expect(
                  capture.ttsInputs,
                  expectedRecommendation.ttsInputs,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/TTS input',
                );
                expect(
                  capture.scores,
                  expectedRecommendation.scores,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/numeric scores',
                );
              }
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
          expect(
            captures['android']?.selectionKeys,
            equals(captures['ios']?.selectionKeys),
          );
          expect(
            captures['android']?.categoryOrder,
            equals(captures['ios']?.categoryOrder),
          );
          expect(
            captures['android']?.displayTexts,
            equals(captures['ios']?.displayTexts),
          );
          expect(
            captures['android']?.ttsInputs,
            equals(captures['ios']?.ttsInputs),
          );
          expect(
            captures['android']?.scores,
            equals(captures['ios']?.scores),
          );
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
    required this.selectionKeys,
    required this.categoryOrder,
    required this.displayTexts,
    required this.ttsInputs,
    required this.scores,
  });

  final Set<String> texts;
  final Set<String> keys;
  final List<String> selectionKeys;
  final List<String> categoryOrder;
  final List<String> displayTexts;
  final List<String> ttsInputs;
  final List<int> scores;
}

Future<_CapturedContract> _captureEntireScreen(
  WidgetTester tester, {
  required List<String> requiredKeys,
  required _ExpectedRecommendationContract? recommendation,
}) async {
  final texts = <String>{};
  final keys = <String>{};
  final selectionKeys = <String>[];
  final categoryOrder = <String>[];
  final displayTexts = <String>[];
  final ttsInputs = <String>[];
  final scores = <int>[];

  void addOnce<T>(List<T> values, T value) {
    if (!values.contains(value)) values.add(value);
  }

  void captureBuiltWidgets() {
    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toList(growable: false);
    texts.addAll(visibleTexts);
    for (final key in requiredKeys) {
      if (find.byKey(ValueKey<String>(key)).evaluate().isNotEmpty) {
        keys.add(key);
      }
    }
    if (recommendation == null) return;

    for (final widget in tester.allWidgets) {
      final key = widget.key;
      if (key is! ValueKey<String>) continue;
      final value = key.value;
      if (value.startsWith('risk-action-act_')) {
        addOnce(
          selectionKeys,
          value.substring('risk-action-'.length),
        );
      }
      for (final prefix in const <String>[
        'risk-action-group-',
        'recommendation-group-',
      ]) {
        if (value.startsWith(prefix)) {
          addOnce(categoryOrder, value.substring(prefix.length));
        }
      }
      if (value.startsWith('recommendation-action-')) {
        final itemTexts = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Text),
              ),
            )
            .map((text) => text.data)
            .whereType<String>();
        for (final text in itemTexts) {
          if (recommendation.displayTexts.contains(text)) {
            addOnce(displayTexts, text);
          }
        }
      }
    }

    for (final tile in tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    )) {
      final title = tile.title;
      if (title is Text && title.data != null) {
        final text = title.data!;
        if (recommendation.displayTexts.contains(text)) {
          addOnce(displayTexts, text);
        }
      }
    }

    for (final rootKey in const <String>[
      'risk-action-groups',
      'farmer-guidance-card',
    ]) {
      final root = find.byKey(ValueKey<String>(rootKey));
      if (root.evaluate().isEmpty) continue;
      for (final button in tester.widgetList<SooktaTtsButton>(
        find.descendant(of: root, matching: find.byType(SooktaTtsButton)),
      )) {
        if (recommendation.ttsInputs.contains(button.text)) {
          addOnce(ttsInputs, button.text);
        }
      }
    }

    for (final text in visibleTexts) {
      final score = int.tryParse(text);
      if (score != null && recommendation.scores.contains(score)) {
        addOnce(scores, score);
      }
    }
  }

  captureBuiltWidgets();
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    return _CapturedContract(
      texts: texts,
      keys: keys,
      selectionKeys: selectionKeys,
      categoryOrder: categoryOrder,
      displayTexts: displayTexts,
      ttsInputs: ttsInputs,
      scores: scores,
    );
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

  return _CapturedContract(
    texts: texts,
    keys: keys,
    selectionKeys: selectionKeys,
    categoryOrder: categoryOrder,
    displayTexts: displayTexts,
    ttsInputs: ttsInputs,
    scores: scores,
  );
}

class _ScreenContract {
  const _ScreenContract({
    required this.name,
    required this.build,
    required this.requiredText,
    this.requiredKeys = const <String>[],
    this.recommendation,
    this.selectionKeysVisible = false,
  });

  final String name;
  final Widget Function() build;
  final List<String> requiredText;
  final List<String> requiredKeys;
  final _ExpectedRecommendationContract? recommendation;
  final bool selectionKeysVisible;
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
      recommendation: _approvedRecommendationContract(
        thai: thai,
        scores: const <int>[8],
      ),
      selectionKeysVisible: true,
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
      recommendation: _approvedRecommendationContract(
        thai: thai,
        scores: const <int>[8, 4],
      ),
    ),
  ];
}

class _ExpectedRecommendationContract {
  const _ExpectedRecommendationContract({
    required this.selectionKeys,
    required this.displayItemIds,
    required this.categoryOrder,
    required this.displayTexts,
    required this.ttsInputs,
    required this.scores,
  });

  final List<String> selectionKeys;
  final List<String> displayItemIds;
  final List<String> categoryOrder;
  final List<String> displayTexts;
  final List<String> ttsInputs;
  final List<int> scores;
}

class _ResolvedRecommendationContract {
  const _ResolvedRecommendationContract({
    required this.selectionKeys,
    required this.displayItemIds,
    required this.categoryOrder,
  });

  final List<String> selectionKeys;
  final List<String> displayItemIds;
  final List<String> categoryOrder;
}

_ExpectedRecommendationContract _approvedRecommendationContract({
  required bool thai,
  required List<int> scores,
}) {
  // These literals are copied from the approved translation review baseline:
  // data/recommendations/translation_review.csv.
  final displayTexts = thai
      ? const <String>[
          'ใช้แรงจากขาในการออกแรง ไม่ใช่หลัง',
          'หลีกเลี่ยงการบิดลำตัวหรือเอียงตัวขณะทำงาน',
          'แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ',
          'ควรพักเบรกเพื่อยืดเหยียดกล้ามเนื้อ',
          'ใช้รถเข็นบรรทุกกระสอบปุ๋ยแทนการแบก',
        ]
      : const <String>[
          'Use force from the legs, not the back.',
          'Avoid twisting or side bending while working.',
          'Split fertilizer into smaller loads per round.',
          'Take breaks to stretch muscles.',
          'Use a cart to carry fertilizer sacks instead of carrying them on the body.',
        ];
  return _ExpectedRecommendationContract(
    selectionKeys: const <String>[
      'act_use_legs',
      'act_avoid_twist',
      'act_fert_split_load',
      'act_rest_stretch',
      'act_extra_fert_cart',
    ],
    displayItemIds: const <String>[
      'act_use_legs.01',
      'act_avoid_twist.01',
      'act_fert_split_load.01',
      'act_rest_stretch.01',
      'act_extra_fert_cart.01',
    ],
    categoryOrder: const <String>[
      'posture',
      'riskReduction',
      'restRotation',
      'workloadSupport',
    ],
    displayTexts: displayTexts,
    ttsInputs: displayTexts,
    scores: scores,
  );
}

_ResolvedRecommendationContract _resolvedRecommendationContract(
  AppLanguage language,
) {
  final recommendations = RiskRecommendationService.farmerRecommendations(
    activity: SooktaActivity.fertilizing,
    riskLevel: RiskLevel.high,
    bodyPartRisks: const <BodyPart, RiskLevel>{
      BodyPart.trunk: RiskLevel.high,
    },
    thai: language == AppLanguage.th,
  );
  final grouped = <FarmerRecommendation>[
    for (final category in FarmerRecommendationCategory.values)
      ...recommendations.where((item) => item.category == category),
  ];
  final catalogLanguage = language == AppLanguage.th
      ? RecommendationLanguage.th
      : RecommendationLanguage.en;
  final displayItemIds = <String>[
    for (final recommendation in grouped)
      ...RecommendationCatalogService.resolve(
        selectionKey: recommendation.sourceKey,
        language: catalogLanguage,
        activity: SooktaActivity.fertilizing.name,
        bodyPart: BodyPart.trunk.name,
        riskLevel: RiskLevel.high.name,
      ).map((item) => item.id),
  ];
  return _ResolvedRecommendationContract(
    selectionKeys:
        grouped.map((recommendation) => recommendation.sourceKey).toList(),
    displayItemIds: displayItemIds,
    categoryOrder: FarmerRecommendationCategory.values
        .where(
          (category) => grouped
              .any((recommendation) => recommendation.category == category),
        )
        .map((category) => category.name)
        .toList(),
  );
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
