import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/localization/sookta_strings.dart';
import 'package:fsookta/core/recommendations/generated_recommendation_catalog.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';
import 'package:fsookta/core/services/recommendation_catalog_service.dart';

RecommendationCatalogItem _fixtureItem(
  String id, {
  required String activity,
  required String bodyPart,
  required String riskLevel,
  int displayOrder = 1,
}) {
  return RecommendationCatalogItem(
    id: id,
    selectionKey: 'act_fixture',
    displayOrder: displayOrder,
    category: 'posture',
    activity: activity,
    bodyPart: bodyPart,
    riskLevel: riskLevel,
    thaiText: 'คำแนะนำ $id',
    englishText: 'Advice $id',
    sourceId: 'fixture',
    sourcePage: '1',
  );
}

void main() {
  test('resolves exact activity and risk context in both approved languages',
      () {
    final th = RecommendationCatalogService.resolve(
      selectionKey: 'act_pruning_ref_high',
      language: RecommendationLanguage.th,
      activity: 'pruning',
      riskLevel: 'high',
    );
    final en = RecommendationCatalogService.resolve(
      selectionKey: 'act_pruning_ref_high',
      language: RecommendationLanguage.en,
      activity: 'pruning',
      riskLevel: 'high',
    );

    expect(th, hasLength(4));
    expect(en, hasLength(th.length));
    expect(th.map((item) => item.displayOrder), [1, 2, 3, 4]);
    expect(th.every((item) => item.text(RecommendationLanguage.th).isNotEmpty),
        isTrue);
    expect(
      en.every((item) => item.englishText.trim().isNotEmpty),
      isTrue,
    );
  });

  test('uses the global context without merging unrelated rows', () {
    final items = RecommendationCatalogService.resolve(
      selectionKey: 'act_rest_stretch',
      language: RecommendationLanguage.th,
      activity: 'pruning',
      bodyPart: 'trunk',
      riskLevel: 'high',
    );

    expect(items, hasLength(1));
    expect(items.single.id, 'act_rest_stretch.01');
    expect(items.single.activity, 'any');
    expect(items.single.bodyPart, 'any');
    expect(items.single.riskLevel, 'any');
  });

  test('competing fixture selects only the best of all six specificity tiers',
      () {
    final tierGroups = <List<RecommendationCatalogItem>>[
      [
        _fixtureItem(
          'tier-1-second',
          activity: 'pruning',
          bodyPart: 'trunk',
          riskLevel: 'high',
          displayOrder: 2,
        ),
        _fixtureItem(
          'tier-1-first',
          activity: 'pruning',
          bodyPart: 'trunk',
          riskLevel: 'high',
        ),
      ],
      [
        _fixtureItem(
          'tier-2',
          activity: 'pruning',
          bodyPart: 'any',
          riskLevel: 'high',
        ),
      ],
      [
        _fixtureItem(
          'tier-3',
          activity: 'any',
          bodyPart: 'trunk',
          riskLevel: 'high',
        ),
      ],
      [
        _fixtureItem(
          'tier-4',
          activity: 'pruning',
          bodyPart: 'any',
          riskLevel: 'any',
        ),
      ],
      [
        _fixtureItem(
          'tier-5',
          activity: 'any',
          bodyPart: 'trunk',
          riskLevel: 'any',
        ),
      ],
      [
        _fixtureItem(
          'tier-6',
          activity: 'any',
          bodyPart: 'any',
          riskLevel: 'any',
        ),
      ],
    ];
    final expectedIds = [
      ['tier-1-first', 'tier-1-second'],
      ['tier-2'],
      ['tier-3'],
      ['tier-4'],
      ['tier-5'],
      ['tier-6'],
    ];

    for (var tier = 0; tier < tierGroups.length; tier++) {
      final fixture = tierGroups
          .skip(tier)
          .expand((items) => items)
          .toList(growable: false);

      final resolved = RecommendationCatalogService.resolveFromCatalog(
        catalog: fixture,
        selectionKey: 'act_fixture',
        language: RecommendationLanguage.en,
        activity: 'pruning',
        bodyPart: 'trunk',
        riskLevel: 'high',
      );

      expect(
        resolved.map((item) => item.id),
        expectedIds[tier],
        reason: 'specificity tier ${tier + 1}',
      );
    }
  });

  test('joined text follows display order and selected language', () {
    final items = RecommendationCatalogService.resolve(
      selectionKey: 'act_pruning_ref_high',
      language: RecommendationLanguage.en,
      activity: 'pruning',
      riskLevel: 'high',
    );

    expect(
      RecommendationCatalogService.joinedText(
        selectionKey: 'act_pruning_ref_high',
        language: RecommendationLanguage.en,
        activity: 'pruning',
        riskLevel: 'high',
      ),
      items.map((item) => item.englishText).join('\n'),
    );
  });

  test('tryJoinedText distinguishes an unknown selection key', () {
    expect(
      RecommendationCatalogService.tryJoinedText(
        selectionKey: 'act_unknown',
        language: RecommendationLanguage.en,
      ),
      isNull,
    );
    expect(
      RecommendationCatalogService.joinedText(
        selectionKey: 'act_unknown',
        language: RecommendationLanguage.en,
      ),
      isEmpty,
    );
  });

  test('selection-key lookup resolves one context and rejects ambiguity', () {
    final uniqueContext = [
      _fixtureItem(
        'unique-second',
        activity: 'fertilizing',
        bodyPart: 'any',
        riskLevel: 'high',
        displayOrder: 2,
      ),
      _fixtureItem(
        'unique-first',
        activity: 'fertilizing',
        bodyPart: 'any',
        riskLevel: 'high',
      ),
    ];
    final ambiguousContexts = [
      ...uniqueContext,
      _fixtureItem(
        'other-context',
        activity: 'pruning',
        bodyPart: 'any',
        riskLevel: 'high',
      ),
    ];

    expect(
      RecommendationCatalogService.tryJoinedTextForSelectionKeyFromCatalog(
        catalog: uniqueContext,
        selectionKey: 'act_fixture',
        language: RecommendationLanguage.en,
      ),
      'Advice unique-first\nAdvice unique-second',
    );
    expect(
      RecommendationCatalogService.tryJoinedTextForSelectionKeyFromCatalog(
        catalog: ambiguousContexts,
        selectionKey: 'act_fixture',
        language: RecommendationLanguage.en,
      ),
      isNull,
    );
  });

  test('maps legacy Thai and English history text to the selection key', () {
    expect(
      RecommendationCatalogService.selectionKeyForLegacyText(
        'เปลี่ยนมาใช้เครื่องตัดกิ่งแบบกลไกช่วย '
        'ถ้าใช้กรรไกรต้องพัก 10 นาทีทุก 20 นาที '
        'ทำงานเป็นทีมเพื่อหมุนเวียน และหลีกเลี่ยงการตัดในท่าบิดตัว',
      ),
      'act_pruning_ref_high',
    );
    expect(
      RecommendationCatalogService.selectionKeyForLegacyText(
        'Use mechanical pruning tools when possible. If shears are used, '
        'rest 10 minutes every 20 minutes, rotate as a team, and avoid '
        'twisting while cutting.',
      ),
      'act_pruning_ref_high',
    );
    expect(
      RecommendationCatalogService.selectionKeyForLegacyText(
        'not a catalog alias',
      ),
      isNull,
    );
  });

  test('canonicalizes camel-case runtime risk context for very-high rows', () {
    final items = RecommendationCatalogService.resolve(
      selectionKey: 'act_body_neck_very_high',
      language: RecommendationLanguage.en,
      bodyPart: 'neck',
      riskLevel: 'veryHigh',
    );

    expect(items, isNotEmpty);
    expect(items.every((item) => item.bodyPart == 'neck'), isTrue);
    expect(items.every((item) => item.riskLevel == 'very_high'), isTrue);
    expect(items.first.id, 'act_body_neck_very_high.01');
  });

  test('unknown recommendation keys use exact approved fallback copy', () {
    const thai = SooktaStrings(SooktaLocale.th);
    const english = SooktaStrings(SooktaLocale.en);

    expect(
      thai.get('act_unknown_internal_identifier'),
      'ไม่สามารถจับคู่คำแนะนำเดิมกับรายการปัจจุบันได้',
    );
    expect(
      english.get('act_unknown_internal_identifier'),
      'A saved recommendation could not be matched to the current approved catalog.',
    );
  });

  test('every packaged UI system and report key resolves from the Catalog', () {
    const expectedKeys = <String>{
      'report.selected_recommendations',
      'system.unmapped_saved_recommendation',
      'ui.category.posture',
      'ui.category.rest_rotation',
      'ui.category.risk_reduction',
      'ui.category.workload_support',
      'ui.recommendations.empty',
      'ui.recommendations.full',
      'ui.recommendations.heading',
      'ui.recommendations.instruction',
    };
    final packagedKeys = generatedRecommendationCatalog
        .map((item) => item.selectionKey)
        .where(
          (key) =>
              key.startsWith('ui.') ||
              key.startsWith('system.') ||
              key.startsWith('report.'),
        )
        .toSet();

    expect(packagedKeys, expectedKeys);
    for (final key in expectedKeys) {
      expect(
        const SooktaStrings(SooktaLocale.th).get(key),
        isNotEmpty,
        reason: 'Thai Catalog copy missing for $key',
      );
      expect(
        const SooktaStrings(SooktaLocale.en).get(key),
        isNotEmpty,
        reason: 'English Catalog copy missing for $key',
      );
      expect(
        const SooktaStrings(SooktaLocale.en).get(key),
        isNot(key),
        reason: 'Catalog key leaked for $key',
      );
    }
  });
}
