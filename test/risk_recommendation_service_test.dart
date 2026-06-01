import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/localization/sookta_strings.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/services/risk_recommendation_service.dart';

void main() {
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
}
