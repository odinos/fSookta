import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/recommendations/generated_recommendation_catalog.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';
import 'package:fsookta/core/services/recommendation_catalog_service.dart';
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
                recommendationContext: screen.recommendation == null
                    ? null
                    : _RecommendationCaptureContext(
                        language: language == AppLanguage.th
                            ? RecommendationLanguage.th
                            : RecommendationLanguage.en,
                      ),
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
                expect(
                  capture.categoryOrder,
                  expectedRecommendation.categoryOrder,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/ordered categories',
                );
                expect(
                  capture.recommendationItems,
                  expectedRecommendation.items,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/ordered recommendation items',
                );
                expect(
                  capture.scoreFields,
                  expectedRecommendation.scoreFields,
                  reason:
                      '${screen.name}/${language.name}/${viewport.name}/score fields',
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
            captures['android']?.categoryOrder,
            equals(captures['ios']?.categoryOrder),
          );
          expect(
            captures['android']?.recommendationItems,
            equals(captures['ios']?.recommendationItems),
          );
          expect(
            captures['android']?.scoreFields,
            equals(captures['ios']?.scoreFields),
          );
        },
      );
    }
  }

  testWidgets(
    'capture includes every structurally scoped recommendation output',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Column(
                  key: ValueKey<String>('risk-action-groups'),
                  children: [
                    Card(
                      key: ValueKey<String>('risk-action-group-posture'),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            key: ValueKey<String>(
                              'risk-action-act_use_legs',
                            ),
                            value: false,
                            onChanged: null,
                            title: Text('Approved recommendation'),
                            secondary: SooktaTtsButton(
                              text: 'Approved recommendation',
                              thai: false,
                            ),
                          ),
                          CheckboxListTile(
                            key: ValueKey<String>(
                              'risk-action-act_forbidden_extra',
                            ),
                            value: false,
                            onChanged: null,
                            title: Text('FORBIDDEN extra recommendation'),
                            secondary: SooktaTtsButton(
                              text: 'FORBIDDEN extra recommendation',
                              thai: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text('8'),
              ],
            ),
          ),
        ),
      );

      final capture = await _captureEntireScreen(
        tester,
        requiredKeys: const <String>[],
        recommendationContext: const _RecommendationCaptureContext(
          language: RecommendationLanguage.en,
        ),
      );

      expect(
        capture.recommendationItems,
        const <_RecommendationItemContract>[
          _RecommendationItemContract(
            categoryPosition: 0,
            category: 'posture',
            itemPosition: 0,
            selectionKey: 'act_use_legs',
            displayItemIds: <String>['act_use_legs.01'],
            displayTexts: <String>['Approved recommendation'],
            ttsInputs: <String>['Approved recommendation'],
          ),
          _RecommendationItemContract(
            categoryPosition: 0,
            category: 'posture',
            itemPosition: 1,
            selectionKey: 'act_forbidden_extra',
            displayItemIds: <String>[],
            displayTexts: <String>['FORBIDDEN extra recommendation'],
            ttsInputs: <String>['FORBIDDEN extra recommendation'],
          ),
        ],
      );
    },
  );
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
    required this.categoryOrder,
    required this.recommendationItems,
    required this.scoreFields,
  });

  final Set<String> texts;
  final Set<String> keys;
  final List<String> categoryOrder;
  final List<_RecommendationItemContract> recommendationItems;
  final List<_ScoreFieldContract> scoreFields;
}

class _RecommendationCaptureContext {
  const _RecommendationCaptureContext({
    required this.language,
  })  : activity = 'fertilizing',
        bodyPart = 'trunk',
        riskLevel = 'high';

  final RecommendationLanguage language;
  final String activity;
  final String bodyPart;
  final String riskLevel;
}

Future<_CapturedContract> _captureEntireScreen(
  WidgetTester tester, {
  required List<String> requiredKeys,
  required _RecommendationCaptureContext? recommendationContext,
}) async {
  final texts = <String>{};
  final keys = <String>{};
  final categoryOrder = <String>[];
  final recommendationItems = <String, _RecommendationItemContract>{};
  final scoreFields = <String, _ScoreFieldContract>{};

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
    if (recommendationContext == null) return;

    final groupWidgets = tester.allWidgets.where((widget) {
      final value = _stringKey(widget);
      return value?.startsWith('risk-action-group-') == true ||
          value?.startsWith('recommendation-group-') == true;
    });
    for (final groupWidget in groupWidgets) {
      final groupKey = _stringKey(groupWidget)!;
      final isSelectionGroup = groupKey.startsWith('risk-action-group-');
      final groupPrefix =
          isSelectionGroup ? 'risk-action-group-' : 'recommendation-group-';
      final category = groupKey.substring(groupPrefix.length);
      if (!categoryOrder.contains(category)) categoryOrder.add(category);
      final categoryPosition = categoryOrder.indexOf(category);
      final itemWidgets = tester.widgetList<Widget>(
        find.descendant(
          of: find.byWidget(groupWidget),
          matching: find.byWidgetPredicate((widget) {
            final value = _stringKey(widget);
            if (value == null) return false;
            return isSelectionGroup
                ? value.startsWith('risk-action-act_')
                : value.startsWith('recommendation-action-$category-');
          }),
        ),
      );

      for (final (encounteredPosition, itemWidget) in itemWidgets.indexed) {
        final itemKey = _stringKey(itemWidget)!;
        final itemPosition = isSelectionGroup
            ? encounteredPosition
            : int.parse(itemKey.split('-').last);
        final displayTexts = isSelectionGroup
            ? _checkboxTitleTexts(tester, itemWidget as CheckboxListTile)
            : _descendantTexts(tester, itemWidget);
        final ttsInputs = isSelectionGroup
            ? _checkboxTtsInputs(tester, itemWidget as CheckboxListTile)
            : _descendantTtsInputs(tester, itemWidget);
        final catalogIdentity = isSelectionGroup
            ? _resolveSelectionKey(
                itemKey.substring('risk-action-'.length),
                recommendationContext,
              )
            : _resolveRenderedTexts(displayTexts, recommendationContext);
        recommendationItems['$categoryPosition:$itemPosition:$itemKey'] =
            _RecommendationItemContract(
          categoryPosition: categoryPosition,
          category: category,
          itemPosition: itemPosition,
          selectionKey: catalogIdentity.selectionKey,
          displayItemIds: catalogIdentity.displayItemIds,
          displayTexts: displayTexts,
          ttsInputs: ttsInputs,
        );
      }
    }

    for (final widget in tester.allWidgets) {
      final type = widget.runtimeType.toString();
      if (type == '_RiskSummaryCard') {
        final dynamic scoreWidget = widget;
        final String label = scoreWidget.title as String;
        final ErgoResult result = scoreWidget.result as ErgoResult;
        scoreFields.putIfAbsent(
          'risk-summary:$label',
          () => _ScoreFieldContract(
            position: scoreFields.length,
            label: label,
            value: result.userScore,
          ),
        );
      } else if (type == '_ScoreBlock') {
        final dynamic scoreWidget = widget;
        final String label = scoreWidget.label as String;
        final int score = scoreWidget.score as int;
        scoreFields.putIfAbsent(
          'score-block:$label',
          () => _ScoreFieldContract(
            position: scoreFields.length,
            label: label,
            value: score,
          ),
        );
      }
    }
  }

  captureBuiltWidgets();
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) {
    return _CapturedContract(
      texts: texts,
      keys: keys,
      categoryOrder: categoryOrder,
      recommendationItems: _orderedRecommendationItems(recommendationItems),
      scoreFields: scoreFields.values.toList(growable: false),
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
    categoryOrder: categoryOrder,
    recommendationItems: _orderedRecommendationItems(recommendationItems),
    scoreFields: scoreFields.values.toList(growable: false),
  );
}

String? _stringKey(Widget widget) {
  final key = widget.key;
  return key is ValueKey<String> ? key.value : null;
}

List<String> _checkboxTitleTexts(
  WidgetTester tester,
  CheckboxListTile tile,
) {
  final title = tile.title;
  if (title == null) return const <String>[];
  if (title is Text) {
    final text = _textValue(title);
    return text == null ? const <String>[] : <String>[text];
  }
  return _descendantTexts(tester, title);
}

List<String> _checkboxTtsInputs(
  WidgetTester tester,
  CheckboxListTile tile,
) {
  final secondary = tile.secondary;
  if (secondary == null) return const <String>[];
  if (secondary is SooktaTtsButton) return <String>[secondary.text];
  return _descendantTtsInputs(tester, secondary);
}

List<String> _descendantTexts(WidgetTester tester, Widget root) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byWidget(root),
          matching: find.byType(Text),
        ),
      )
      .map(_textValue)
      .whereType<String>()
      .toList(growable: false);
}

String? _textValue(Text text) {
  final value = text.data ?? text.textSpan?.toPlainText();
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

List<String> _descendantTtsInputs(WidgetTester tester, Widget root) {
  return tester
      .widgetList<SooktaTtsButton>(
        find.descendant(
          of: find.byWidget(root),
          matching: find.byType(SooktaTtsButton),
        ),
      )
      .map((button) => button.text)
      .toList(growable: false);
}

List<_RecommendationItemContract> _orderedRecommendationItems(
  Map<String, _RecommendationItemContract> items,
) {
  final ordered = items.values.toList(growable: false)
    ..sort((left, right) {
      final categoryComparison =
          left.categoryPosition.compareTo(right.categoryPosition);
      return categoryComparison != 0
          ? categoryComparison
          : left.itemPosition.compareTo(right.itemPosition);
    });
  return ordered;
}

class _ResolvedCatalogIdentity {
  const _ResolvedCatalogIdentity({
    required this.selectionKey,
    required this.displayItemIds,
  });

  final String selectionKey;
  final List<String> displayItemIds;
}

_ResolvedCatalogIdentity _resolveSelectionKey(
  String selectionKey,
  _RecommendationCaptureContext context,
) {
  final items = RecommendationCatalogService.resolve(
    selectionKey: selectionKey,
    language: context.language,
    activity: context.activity,
    bodyPart: context.bodyPart,
    riskLevel: context.riskLevel,
  );
  return _ResolvedCatalogIdentity(
    selectionKey: selectionKey,
    displayItemIds: items.map((item) => item.id).toList(growable: false),
  );
}

_ResolvedCatalogIdentity _resolveRenderedTexts(
  List<String> renderedTexts,
  _RecommendationCaptureContext context,
) {
  final matches = <_ResolvedCatalogIdentity>[];
  final selectionKeys =
      generatedRecommendationCatalog.map((item) => item.selectionKey).toSet();
  for (final selectionKey in selectionKeys) {
    final items = RecommendationCatalogService.resolve(
      selectionKey: selectionKey,
      language: context.language,
      activity: context.activity,
      bodyPart: context.bodyPart,
      riskLevel: context.riskLevel,
    );
    if (items.isEmpty) continue;
    final joinedText =
        items.map((item) => item.text(context.language)).join('\n');
    if (!listEquals(renderedTexts, <String>[joinedText])) continue;
    matches.add(
      _ResolvedCatalogIdentity(
        selectionKey: selectionKey,
        displayItemIds: items.map((item) => item.id).toList(growable: false),
      ),
    );
  }
  if (matches.length == 1) return matches.single;
  final marker = matches.isEmpty
      ? '<unresolved-rendered-recommendation>'
      : '<ambiguous-rendered-recommendation>';
  return _ResolvedCatalogIdentity(
    selectionKey: marker,
    displayItemIds: const <String>[],
  );
}

class _ScreenContract {
  const _ScreenContract({
    required this.name,
    required this.build,
    required this.requiredText,
    this.requiredKeys = const <String>[],
    this.recommendation,
  });

  final String name;
  final Widget Function() build;
  final List<String> requiredText;
  final List<String> requiredKeys;
  final _ExpectedRecommendationContract? recommendation;
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
    required this.categoryOrder,
    required this.items,
    required this.scoreFields,
  });

  final List<String> categoryOrder;
  final List<_RecommendationItemContract> items;
  final List<_ScoreFieldContract> scoreFields;
}

class _RecommendationItemContract {
  const _RecommendationItemContract({
    required this.categoryPosition,
    required this.category,
    required this.itemPosition,
    required this.selectionKey,
    required this.displayItemIds,
    required this.displayTexts,
    required this.ttsInputs,
  });

  final int categoryPosition;
  final String category;
  final int itemPosition;
  final String selectionKey;
  final List<String> displayItemIds;
  final List<String> displayTexts;
  final List<String> ttsInputs;

  @override
  bool operator ==(Object other) {
    return other is _RecommendationItemContract &&
        categoryPosition == other.categoryPosition &&
        category == other.category &&
        itemPosition == other.itemPosition &&
        selectionKey == other.selectionKey &&
        listEquals(displayItemIds, other.displayItemIds) &&
        listEquals(displayTexts, other.displayTexts) &&
        listEquals(ttsInputs, other.ttsInputs);
  }

  @override
  int get hashCode => Object.hash(
        categoryPosition,
        category,
        itemPosition,
        selectionKey,
        Object.hashAll(displayItemIds),
        Object.hashAll(displayTexts),
        Object.hashAll(ttsInputs),
      );

  @override
  String toString() {
    return 'RecommendationItem(categoryPosition: $categoryPosition, '
        'category: $category, itemPosition: $itemPosition, '
        'selectionKey: $selectionKey, displayItemIds: $displayItemIds, '
        'displayTexts: $displayTexts, ttsInputs: $ttsInputs)';
  }
}

class _ScoreFieldContract {
  const _ScoreFieldContract({
    required this.position,
    required this.label,
    required this.value,
  });

  final int position;
  final String label;
  final int value;

  @override
  bool operator ==(Object other) {
    return other is _ScoreFieldContract &&
        position == other.position &&
        label == other.label &&
        value == other.value;
  }

  @override
  int get hashCode => Object.hash(position, label, value);

  @override
  String toString() {
    return 'ScoreField(position: $position, label: $label, value: $value)';
  }
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
    categoryOrder: const <String>[
      'posture',
      'riskReduction',
      'restRotation',
      'workloadSupport',
    ],
    items: <_RecommendationItemContract>[
      _RecommendationItemContract(
        categoryPosition: 0,
        category: 'posture',
        itemPosition: 0,
        selectionKey: 'act_use_legs',
        displayItemIds: const <String>['act_use_legs.01'],
        displayTexts: <String>[displayTexts[0]],
        ttsInputs: <String>[displayTexts[0]],
      ),
      _RecommendationItemContract(
        categoryPosition: 0,
        category: 'posture',
        itemPosition: 1,
        selectionKey: 'act_avoid_twist',
        displayItemIds: const <String>['act_avoid_twist.01'],
        displayTexts: <String>[displayTexts[1]],
        ttsInputs: <String>[displayTexts[1]],
      ),
      _RecommendationItemContract(
        categoryPosition: 1,
        category: 'riskReduction',
        itemPosition: 0,
        selectionKey: 'act_fert_split_load',
        displayItemIds: const <String>['act_fert_split_load.01'],
        displayTexts: <String>[displayTexts[2]],
        ttsInputs: <String>[displayTexts[2]],
      ),
      _RecommendationItemContract(
        categoryPosition: 2,
        category: 'restRotation',
        itemPosition: 0,
        selectionKey: 'act_rest_stretch',
        displayItemIds: const <String>['act_rest_stretch.01'],
        displayTexts: <String>[displayTexts[3]],
        ttsInputs: <String>[displayTexts[3]],
      ),
      _RecommendationItemContract(
        categoryPosition: 3,
        category: 'workloadSupport',
        itemPosition: 0,
        selectionKey: 'act_extra_fert_cart',
        displayItemIds: const <String>['act_extra_fert_cart.01'],
        displayTexts: <String>[displayTexts[4]],
        ttsInputs: <String>[displayTexts[4]],
      ),
    ],
    scoreFields: scores.length == 1
        ? <_ScoreFieldContract>[
            _ScoreFieldContract(
              position: 0,
              label: thai ? 'คะแนนก่อนปรับปรุง' : 'Before Improvement',
              value: scores[0],
            ),
            _ScoreFieldContract(
              position: 1,
              label: thai
                  ? 'ถ้าทำตามที่เลือก คะแนนจะเป็น'
                  : 'If selected actions are done',
              value: scores[0],
            ),
          ]
        : <_ScoreFieldContract>[
            _ScoreFieldContract(
              position: 0,
              label: thai ? 'ก่อนปรับ' : 'Before',
              value: scores[0],
            ),
            _ScoreFieldContract(
              position: 1,
              label: thai ? 'หลังปรับ' : 'After',
              value: scores[1],
            ),
          ],
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
