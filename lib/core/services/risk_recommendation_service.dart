import '../models/assessment_session.dart';
import '../models/evaluation_models.dart';

enum FarmerRecommendationCategory {
  posture,
  riskReduction,
  restRotation,
  workloadSupport,
}

class FarmerRecommendation {
  const FarmerRecommendation({required this.category, required this.text});

  final FarmerRecommendationCategory category;
  final String text;
}

class RiskRecommendationService {
  const RiskRecommendationService._();

  static List<FarmerRecommendation> farmerRecommendations({
    required SooktaActivity activity,
    required RiskLevel riskLevel,
    required Map<BodyPart, RiskLevel> bodyPartRisks,
    required bool thai,
  }) {
    final items = <FarmerRecommendation>[
      _activityPosture(activity, thai),
      _activityRiskReduction(activity, thai),
      _restAction(riskLevel, thai),
      _workloadSupport(activity, thai),
    ];
    final riskyParts = bodyPartRisks.entries
        .where((entry) => entry.value != RiskLevel.low)
        .map((entry) => entry.key)
        .take(1);
    for (final part in riskyParts) {
      items.add(_bodyPosture(part, thai));
    }

    final seen = <String>{};
    final counts = <FarmerRecommendationCategory, int>{};
    return items.where((item) {
      final key = '${item.category.name}:${item.text}';
      if (!seen.add(key)) return false;
      final count = counts[item.category] ?? 0;
      if (count >= 2) return false;
      counts[item.category] = count + 1;
      return true;
    }).toList(growable: false);
  }

  static FarmerRecommendation _activityPosture(
    SooktaActivity activity,
    bool thai,
  ) {
    final text = switch (activity) {
      SooktaActivity.transplanting =>
        thai ? 'สลับยืนกับนั่งยองเป็นระยะ' : 'Alternate standing and squatting',
      SooktaActivity.fertilizing =>
        thai ? 'หันตัวเข้าหาปุ๋ยก่อนยก' : 'Face the fertilizer before lifting',
      SooktaActivity.pesticide => thai
          ? 'สลับข้างที่ถือท่อพ่น'
          : 'Alternate the side holding the spray wand',
      SooktaActivity.pruning => thai
          ? 'หลีกเลี่ยงการยกแขนเหนือไหล่นาน'
          : 'Avoid keeping arms above shoulder level',
      SooktaActivity.harvesting => thai
          ? 'ขยับเข้าใกล้ต้นก่อนเก็บ'
          : 'Move closer to the plant before picking',
      SooktaActivity.transport => thai
          ? 'งอเข่าและรักษาหลังให้ตรงขณะยก'
          : 'Bend the knees and keep the back straight',
    };
    return FarmerRecommendation(
      category: FarmerRecommendationCategory.posture,
      text: text,
    );
  }

  static FarmerRecommendation _activityRiskReduction(
    SooktaActivity activity,
    bool thai,
  ) {
    final text = switch (activity) {
      SooktaActivity.transplanting =>
        thai ? 'ลดเวลาก้มทำงานต่อเนื่อง' : 'Reduce continuous bending time',
      SooktaActivity.fertilizing =>
        thai ? 'ลดน้ำหนักปุ๋ยต่อครั้ง' : 'Reduce fertilizer weight per trip',
      SooktaActivity.pesticide =>
        thai ? 'ลดระยะเวลาพ่นต่อเนื่อง' : 'Reduce continuous spraying time',
      SooktaActivity.pruning => thai
          ? 'หลีกเลี่ยงการตัดกิ่งในท่าบิดตัว'
          : 'Avoid twisting while pruning',
      SooktaActivity.harvesting => thai
          ? 'หยุดงานเมื่อปวดมือหรือหลัง'
          : 'Stop when hand or back pain occurs',
      SooktaActivity.transport =>
        thai ? 'ลดน้ำหนักกระสอบต่อครั้ง' : 'Reduce sack weight per trip',
    };
    return FarmerRecommendation(
      category: FarmerRecommendationCategory.riskReduction,
      text: text,
    );
  }

  static FarmerRecommendation _restAction(RiskLevel risk, bool thai) {
    final text = switch (risk) {
      RiskLevel.low =>
        thai ? 'เปลี่ยนท่าทุก 30 นาที' : 'Change posture every 30 minutes',
      RiskLevel.medium =>
        thai ? 'พัก 5 นาทีทุก 30 นาที' : 'Rest 5 minutes every 30 minutes',
      RiskLevel.high ||
      RiskLevel.veryHigh =>
        thai ? 'พัก 10 นาทีทุกชั่วโมง' : 'Rest 10 minutes every hour',
    };
    return FarmerRecommendation(
      category: FarmerRecommendationCategory.restRotation,
      text: text,
    );
  }

  static FarmerRecommendation _workloadSupport(
    SooktaActivity activity,
    bool thai,
  ) {
    final text = switch (activity) {
      SooktaActivity.transplanting => thai
          ? 'ใช้เก้าอี้เตี้ยหรือเบาะรองนั่ง'
          : 'Use a low stool or squat cushion',
      SooktaActivity.fertilizing =>
        thai ? 'ใช้รถเข็นหรือสายพาน' : 'Use a cart or conveyor',
      SooktaActivity.pesticide => thai
          ? 'ใช้รถเข็นหรือหัวฉีดต่อท่อยาว'
          : 'Use a wheeled aid or long-hose nozzle',
      SooktaActivity.pruning => thai
          ? 'ใช้กรรไกรด้ามยาวที่น้ำหนักเบา'
          : 'Use lightweight long-handled shears',
      SooktaActivity.harvesting =>
        thai ? 'วางตะกร้าบนแท่นสูง' : 'Place the basket on a raised stand',
      SooktaActivity.transport => thai
          ? 'ใช้รถเข็นล้อใหญ่หรือรถลาก'
          : 'Use a large-wheel cart or trolley',
    };
    return FarmerRecommendation(
      category: FarmerRecommendationCategory.workloadSupport,
      text: text,
    );
  }

  static FarmerRecommendation _bodyPosture(BodyPart part, bool thai) {
    final text = switch (part) {
      BodyPart.neck => thai
          ? 'หลีกเลี่ยงการก้มหรือเอียงคอนาน'
          : 'Avoid prolonged neck bending or tilting',
      BodyPart.trunk => thai
          ? 'ใช้เท้าหมุนตัวแทนการบิดเอว'
          : 'Turn with the feet instead of twisting the waist',
      BodyPart.arms =>
        thai ? 'วางงานให้ต่ำกว่าระดับไหล่' : 'Keep work below shoulder level',
      BodyPart.wrists => thai
          ? 'รักษาข้อมือให้ตรงขณะจับอุปกรณ์'
          : 'Keep wrists straight while holding tools',
      BodyPart.legs => thai
          ? 'สลับนั่ง ยืน และเดิน'
          : 'Alternate sitting, standing, and walking',
    };
    return FarmerRecommendation(
      category: FarmerRecommendationCategory.posture,
      text: text,
    );
  }

  static List<String> activityKeys({
    required SooktaActivity activity,
    required RiskLevel riskLevel,
  }) {
    final tier = _tierFor(riskLevel);
    final weightLimitKey = switch (tier) {
      _RecommendationTier.low => 'act_ref_weight_low',
      _RecommendationTier.medium => 'act_ref_weight_medium',
      _RecommendationTier.high => 'act_ref_weight_high',
      _RecommendationTier.veryHigh => 'act_ref_weight_high',
    };
    final activityKey = switch ((activity, tier)) {
      (SooktaActivity.transplanting, _RecommendationTier.low) =>
        'act_transplant_ref_low',
      (SooktaActivity.transplanting, _RecommendationTier.medium) =>
        'act_transplant_ref_medium',
      (SooktaActivity.transplanting, _RecommendationTier.high) =>
        'act_transplant_ref_high',
      (SooktaActivity.transplanting, _RecommendationTier.veryHigh) =>
        'act_transplant_ref_high',
      (SooktaActivity.fertilizing, _RecommendationTier.low) =>
        'act_fert_ref_low',
      (SooktaActivity.fertilizing, _RecommendationTier.medium) =>
        'act_fert_ref_medium',
      (SooktaActivity.fertilizing, _RecommendationTier.high) =>
        'act_fert_ref_high',
      (SooktaActivity.fertilizing, _RecommendationTier.veryHigh) =>
        'act_fert_ref_high',
      (SooktaActivity.pesticide, _RecommendationTier.low) =>
        'act_pesticide_ref_low',
      (SooktaActivity.pesticide, _RecommendationTier.medium) =>
        'act_pesticide_ref_medium',
      (SooktaActivity.pesticide, _RecommendationTier.high) =>
        'act_pesticide_ref_high',
      (SooktaActivity.pesticide, _RecommendationTier.veryHigh) =>
        'act_pesticide_ref_high',
      (SooktaActivity.pruning, _RecommendationTier.low) =>
        'act_pruning_ref_low',
      (SooktaActivity.pruning, _RecommendationTier.medium) =>
        'act_pruning_ref_medium',
      (SooktaActivity.pruning, _RecommendationTier.high) =>
        'act_pruning_ref_high',
      (SooktaActivity.pruning, _RecommendationTier.veryHigh) =>
        'act_pruning_ref_high',
      (SooktaActivity.harvesting, _RecommendationTier.low) =>
        'act_harvest_ref_low',
      (SooktaActivity.harvesting, _RecommendationTier.medium) =>
        'act_harvest_ref_medium',
      (SooktaActivity.harvesting, _RecommendationTier.high) =>
        'act_harvest_ref_high',
      (SooktaActivity.harvesting, _RecommendationTier.veryHigh) =>
        'act_harvest_ref_high',
      (SooktaActivity.transport, _RecommendationTier.low) =>
        'act_transport_ref_low',
      (SooktaActivity.transport, _RecommendationTier.medium) =>
        'act_transport_ref_medium',
      (SooktaActivity.transport, _RecommendationTier.high) =>
        'act_transport_ref_high',
      (SooktaActivity.transport, _RecommendationTier.veryHigh) =>
        'act_transport_ref_high',
    };

    return [
      activityKey,
      if (_usesManualHandling(activity)) weightLimitKey,
    ];
  }

  static List<String> bodyMapKeys({
    required Map<BodyPart, RiskLevel> bodyPartRisks,
    required SooktaActivity activity,
    required RiskLevel overallRisk,
  }) {
    final keys = <String>[];
    for (final entry in bodyPartRisks.entries) {
      if (entry.value == RiskLevel.low) continue;
      keys.add(_bodyPartKey(entry.key, _tierForExact(entry.value)));
    }
    if (_usesManualHandling(activity) && overallRisk >= RiskLevel.medium) {
      keys.add(_manualHandlingKey(_tierForExact(overallRisk)));
    }
    return keys.toSet().toList(growable: false);
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
        'act_body_neck_medium',
        'act_body_neck_high',
        'act_body_neck_very_high',
        'act_body_trunk_medium',
        'act_body_trunk_high',
        'act_body_trunk_very_high',
        'act_body_arms_medium',
        'act_body_arms_high',
        'act_body_arms_very_high',
        'act_body_wrists_medium',
        'act_body_wrists_high',
        'act_body_wrists_very_high',
        'act_body_legs_medium',
        'act_body_legs_high',
        'act_body_legs_very_high',
        'act_body_manual_medium',
        'act_body_manual_high',
        'act_body_manual_very_high',
      };

  static _RecommendationTier _tierFor(RiskLevel riskLevel) {
    return switch (riskLevel) {
      RiskLevel.low => _RecommendationTier.low,
      RiskLevel.medium => _RecommendationTier.medium,
      RiskLevel.high || RiskLevel.veryHigh => _RecommendationTier.high,
    };
  }

  static _RecommendationTier _tierForExact(RiskLevel riskLevel) {
    return switch (riskLevel) {
      RiskLevel.low => _RecommendationTier.low,
      RiskLevel.medium => _RecommendationTier.medium,
      RiskLevel.high => _RecommendationTier.high,
      RiskLevel.veryHigh => _RecommendationTier.veryHigh,
    };
  }

  static String _bodyPartKey(BodyPart part, _RecommendationTier tier) {
    final partKey = switch (part) {
      BodyPart.neck => 'neck',
      BodyPart.trunk => 'trunk',
      BodyPart.arms => 'arms',
      BodyPart.wrists => 'wrists',
      BodyPart.legs => 'legs',
    };
    return 'act_body_${partKey}_${_tierKey(tier)}';
  }

  static String _manualHandlingKey(_RecommendationTier tier) {
    return 'act_body_manual_${_tierKey(tier)}';
  }

  static String _tierKey(_RecommendationTier tier) {
    return switch (tier) {
      _RecommendationTier.low => 'medium',
      _RecommendationTier.medium => 'medium',
      _RecommendationTier.high => 'high',
      _RecommendationTier.veryHigh => 'very_high',
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
  veryHigh,
}
