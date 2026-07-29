import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/localization/sookta_strings.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/risk_recommendation_service.dart';

void main() {
  test('returns concise recommendations with explicit categories', () {
    final items = RiskRecommendationService.farmerRecommendations(
      activity: SooktaActivity.fertilizing,
      riskLevel: RiskLevel.high,
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
      thai: true,
    );

    expect(
      items.map((item) => item.category).toSet(),
      containsAll(FarmerRecommendationCategory.values),
    );
    for (final category in FarmerRecommendationCategory.values) {
      expect(
        items.where((item) => item.category == category).length,
        inInclusiveRange(1, 2),
      );
    }
    expect(
      items.map((item) => item.text),
      contains('แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ'),
    );
    expect(items.every((item) => item.text.length <= 70), isTrue);
  });

  test('catalog migration preserves selection keys and category counts', () {
    final items = RiskRecommendationService.farmerRecommendations(
      activity: SooktaActivity.fertilizing,
      riskLevel: RiskLevel.high,
      bodyPartRisks: const {BodyPart.trunk: RiskLevel.high},
      thai: false,
    );

    expect(
        items.map((item) => item.sourceKey),
        containsAll(<String>[
          'act_use_legs',
          'act_fert_split_load',
          'act_rest_stretch',
          'act_extra_fert_cart',
        ]));
    expect(
      items
          .map((item) => (item.category, item.sourceKey))
          .toList(growable: false),
      const [
        (FarmerRecommendationCategory.posture, 'act_use_legs'),
        (
          FarmerRecommendationCategory.riskReduction,
          'act_fert_split_load',
        ),
        (
          FarmerRecommendationCategory.restRotation,
          'act_rest_stretch',
        ),
        (
          FarmerRecommendationCategory.workloadSupport,
          'act_extra_fert_cart',
        ),
        (FarmerRecommendationCategory.posture, 'act_avoid_twist'),
      ],
    );
    expect(
      items.map((item) => item.text).toList(growable: false),
      const [
        'Use force from the legs, not the back.',
        'Split fertilizer into smaller loads per round.',
        'Take breaks to stretch muscles.',
        'Use a cart to carry fertilizer sacks instead of carrying them on the body.',
        'Avoid twisting or side bending while working.',
      ],
    );
    expect(items.every((item) => item.text.trim().isNotEmpty), isTrue);
  });

  test('keeps multi-line catalog text under one selection key', () {
    final items = RiskRecommendationService.farmerRecommendations(
      activity: SooktaActivity.transplanting,
      riskLevel: RiskLevel.high,
      bodyPartRisks: const {BodyPart.neck: RiskLevel.high},
      thai: false,
    );

    final neckItems =
        items.where((item) => item.sourceKey == 'act_adj_eye_level').toList();
    expect(neckItems, hasLength(1));
    expect(
      neckItems.single.text,
      'Adjust the work to eye level.\nReduce neck bending.',
    );
  });

  test('returns document-based recommendations by activity and risk level', () {
    expect(
      RiskRecommendationService.activityKeys(
        activity: SooktaActivity.transport,
        riskLevel: RiskLevel.high,
      ),
      containsAll(['act_transport_ref_high', 'act_ref_weight_high']),
    );
    expect(
      RiskRecommendationService.activityKeys(
        activity: SooktaActivity.pruning,
        riskLevel: RiskLevel.low,
      ),
      ['act_pruning_ref_low'],
    );
    expect(
      RiskRecommendationService.activityKeys(
        activity: SooktaActivity.pesticide,
        riskLevel: RiskLevel.veryHigh,
      ),
      containsAll(['act_pesticide_ref_high', 'act_ref_weight_high']),
    );
  });

  test('document-based recommendation keys are localized in Thai and English',
      () {
    final th = const SooktaStrings(SooktaLocale.th);
    final en = const SooktaStrings(SooktaLocale.en);

    for (final key in RiskRecommendationService.allKeys) {
      expect(th.get(key), isNot(key), reason: 'Missing Thai text for $key');
      expect(en.get(key), isNot(key), reason: 'Missing English text for $key');
    }
  });

  test('routes recommendation strings through approved catalog copy', () {
    const th = SooktaStrings(SooktaLocale.th);
    const en = SooktaStrings(SooktaLocale.en);

    expect(
      th.get('act_adj_eye_level'),
      'ปรับงานให้อยู่ระดับสายตา\nลดการก้มคอ',
    );
    expect(
      en.get('act_use_legs'),
      'Use force from the legs, not the back.',
    );
    expect(en.get('app_name'), 'Sookta');
  });
}
