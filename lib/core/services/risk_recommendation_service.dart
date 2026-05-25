import '../models/assessment_session.dart';
import '../models/evaluation_models.dart';

class RiskRecommendationService {
  const RiskRecommendationService._();

  static List<String> activityKeys({
    required SooktaActivity activity,
    required RiskLevel riskLevel,
  }) {
    final tier = _tierFor(riskLevel);
    final weightLimitKey = switch (tier) {
      _RecommendationTier.low => 'act_ref_weight_low',
      _RecommendationTier.medium => 'act_ref_weight_medium',
      _RecommendationTier.high => 'act_ref_weight_high',
    };
    final activityKey = switch ((activity, tier)) {
      (SooktaActivity.transplanting, _RecommendationTier.low) =>
        'act_transplant_ref_low',
      (SooktaActivity.transplanting, _RecommendationTier.medium) =>
        'act_transplant_ref_medium',
      (SooktaActivity.transplanting, _RecommendationTier.high) =>
        'act_transplant_ref_high',
      (SooktaActivity.fertilizing, _RecommendationTier.low) =>
        'act_fert_ref_low',
      (SooktaActivity.fertilizing, _RecommendationTier.medium) =>
        'act_fert_ref_medium',
      (SooktaActivity.fertilizing, _RecommendationTier.high) =>
        'act_fert_ref_high',
      (SooktaActivity.pesticide, _RecommendationTier.low) =>
        'act_pesticide_ref_low',
      (SooktaActivity.pesticide, _RecommendationTier.medium) =>
        'act_pesticide_ref_medium',
      (SooktaActivity.pesticide, _RecommendationTier.high) =>
        'act_pesticide_ref_high',
      (SooktaActivity.pruning, _RecommendationTier.low) =>
        'act_pruning_ref_low',
      (SooktaActivity.pruning, _RecommendationTier.medium) =>
        'act_pruning_ref_medium',
      (SooktaActivity.pruning, _RecommendationTier.high) =>
        'act_pruning_ref_high',
      (SooktaActivity.harvesting, _RecommendationTier.low) =>
        'act_harvest_ref_low',
      (SooktaActivity.harvesting, _RecommendationTier.medium) =>
        'act_harvest_ref_medium',
      (SooktaActivity.harvesting, _RecommendationTier.high) =>
        'act_harvest_ref_high',
      (SooktaActivity.transport, _RecommendationTier.low) =>
        'act_transport_ref_low',
      (SooktaActivity.transport, _RecommendationTier.medium) =>
        'act_transport_ref_medium',
      (SooktaActivity.transport, _RecommendationTier.high) =>
        'act_transport_ref_high',
    };

    return [
      activityKey,
      if (_usesManualHandling(activity)) weightLimitKey,
    ];
  }

  static Set<String> get allKeys => const {
        'act_ref_weight_low',
        'act_ref_weight_medium',
        'act_ref_weight_high',
        'act_transplant_ref_low',
        'act_transplant_ref_medium',
        'act_transplant_ref_high',
        'act_fert_ref_low',
        'act_fert_ref_medium',
        'act_fert_ref_high',
        'act_pesticide_ref_low',
        'act_pesticide_ref_medium',
        'act_pesticide_ref_high',
        'act_pruning_ref_low',
        'act_pruning_ref_medium',
        'act_pruning_ref_high',
        'act_harvest_ref_low',
        'act_harvest_ref_medium',
        'act_harvest_ref_high',
        'act_transport_ref_low',
        'act_transport_ref_medium',
        'act_transport_ref_high',
      };

  static _RecommendationTier _tierFor(RiskLevel riskLevel) {
    return switch (riskLevel) {
      RiskLevel.low => _RecommendationTier.low,
      RiskLevel.medium => _RecommendationTier.medium,
      RiskLevel.high || RiskLevel.veryHigh => _RecommendationTier.high,
    };
  }

  static bool _usesManualHandling(SooktaActivity activity) {
    return switch (activity) {
      SooktaActivity.transplanting ||
      SooktaActivity.fertilizing ||
      SooktaActivity.pesticide ||
      SooktaActivity.transport =>
        true,
      SooktaActivity.pruning || SooktaActivity.harvesting => false,
    };
  }
}

enum _RecommendationTier {
  low,
  medium,
  high,
}
