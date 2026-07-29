import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/recommendations/recommendation_catalog_models.dart';
import 'package:fsookta/core/services/recommendation_catalog_service.dart';

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
}
