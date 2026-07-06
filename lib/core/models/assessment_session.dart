import '../../app/assets.dart';
import 'evaluation_models.dart';

enum SooktaActivity {
  transplanting,
  fertilizing,
  pesticide,
  pruning,
  harvesting,
  transport,
}

class ActivityToolOption {
  const ActivityToolOption({
    required this.id,
    required this.labelTh,
    required this.labelEn,
    required this.weightKg,
    required this.weightBandCode,
  });

  final String id;
  final String labelTh;
  final String labelEn;
  final double weightKg;

  /// Weight band used in exports/training data.
  /// 1=<5 kg, 2=5-10 kg, 3=10-15 kg, 4=15-20 kg,
  /// 5=20-25 kg, 6=25-30 kg, 7=>30 kg.
  final int weightBandCode;

  String label({required bool thai}) => thai ? labelTh : labelEn;
}

extension SooktaActivityInfo on SooktaActivity {
  String get imageAsset {
    return switch (this) {
      SooktaActivity.transplanting => SooktaAssets.transplanting,
      SooktaActivity.fertilizing => SooktaAssets.fertilizing,
      SooktaActivity.pesticide => SooktaAssets.pesticide,
      SooktaActivity.pruning => SooktaAssets.pruning,
      SooktaActivity.harvesting => SooktaAssets.harvesting,
      SooktaActivity.transport => SooktaAssets.transport,
    };
  }

  String get readablePoseExampleAsset {
    return switch (this) {
      SooktaActivity.transplanting => SooktaAssets.transplantingPoseExample,
      SooktaActivity.fertilizing => SooktaAssets.fertilizingPoseExample,
      SooktaActivity.pesticide => SooktaAssets.pesticidePoseExample,
      SooktaActivity.pruning => SooktaAssets.pruningPoseExample,
      SooktaActivity.harvesting => SooktaAssets.harvestingPoseExample,
      SooktaActivity.transport => SooktaAssets.transportPoseExample,
    };
  }

  String label({required bool thai}) {
    if (thai) {
      return switch (this) {
        SooktaActivity.transplanting => 'การปลูกกล้า',
        SooktaActivity.fertilizing => 'การใส่ปุ๋ย',
        SooktaActivity.pesticide => 'การฉีดพ่นสารกำจัดศัตรูพืช',
        SooktaActivity.pruning => 'การตัดแต่งกิ่ง',
        SooktaActivity.harvesting => 'การเก็บเกี่ยว',
        SooktaActivity.transport => 'การขนย้ายผลผลิต',
      };
    }
    return switch (this) {
      SooktaActivity.transplanting => 'Planting',
      SooktaActivity.fertilizing => 'Fertilizing',
      SooktaActivity.pesticide => 'Pesticide Spraying',
      SooktaActivity.pruning => 'Pruning',
      SooktaActivity.harvesting => 'Harvesting',
      SooktaActivity.transport => 'On-farm Transport',
    };
  }

  String stageLabel({required bool thai}) {
    if (thai) {
      return switch (this) {
        SooktaActivity.transplanting => 'การปลูก',
        SooktaActivity.fertilizing ||
        SooktaActivity.pesticide =>
          'การดูแลรักษา',
        SooktaActivity.pruning => 'การตัดแต่ง/ดูแลรักษา',
        SooktaActivity.harvesting => 'การเก็บเกี่ยว',
        SooktaActivity.transport => 'การขนส่ง/ขนย้าย',
      };
    }
    return switch (this) {
      SooktaActivity.transplanting => 'Planting',
      SooktaActivity.fertilizing || SooktaActivity.pesticide => 'Maintenance',
      SooktaActivity.pruning => 'Maintenance / Pruning',
      SooktaActivity.harvesting => 'Harvesting',
      SooktaActivity.transport => 'Transport',
    };
  }

  JobType get defaultJobType {
    return switch (this) {
      SooktaActivity.fertilizing || SooktaActivity.transport => JobType.lifting,
      SooktaActivity.pesticide => JobType.pushPull,
      _ => JobType.reba,
    };
  }

  List<ActivityToolOption> get toolOptions {
    return switch (this) {
      SooktaActivity.transplanting => const [
          ActivityToolOption(
            id: 'hoe_2_5kg',
            labelTh: 'จอบ (2.5 กก.)',
            labelEn: 'Hoe (2.5 kg)',
            weightKg: 2.5,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'spade_2kg',
            labelTh: 'เสียม (2 กก.)',
            labelEn: 'Spade (2 kg)',
            weightKg: 2.0,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'seedling_bucket_5_10kg',
            labelTh: 'ถังกล้า (5-10 กก.)',
            labelEn: 'Seedling bucket (5-10 kg)',
            weightKg: 7.5,
            weightBandCode: 2,
          ),
        ],
      SooktaActivity.fertilizing => const [
          ActivityToolOption(
            id: 'fertilizer_lt5kg',
            labelTh: 'ปุ๋ยน้อยกว่า 5 กก.',
            labelEn: 'Fertilizer under 5 kg',
            weightKg: 4.0,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'fertilizer_5_10kg',
            labelTh: 'ปุ๋ย 5-10 กก.',
            labelEn: 'Fertilizer 5-10 kg',
            weightKg: 7.5,
            weightBandCode: 2,
          ),
          ActivityToolOption(
            id: 'fertilizer_10_15kg',
            labelTh: 'ปุ๋ย 10-15 กก.',
            labelEn: 'Fertilizer 10-15 kg',
            weightKg: 12.5,
            weightBandCode: 3,
          ),
          ActivityToolOption(
            id: 'fertilizer_15_20kg',
            labelTh: 'ปุ๋ย 15-20 กก.',
            labelEn: 'Fertilizer 15-20 kg',
            weightKg: 17.5,
            weightBandCode: 4,
          ),
          ActivityToolOption(
            id: 'fertilizer_20_25kg',
            labelTh: 'ปุ๋ย 20-25 กก.',
            labelEn: 'Fertilizer 20-25 kg',
            weightKg: 22.5,
            weightBandCode: 5,
          ),
          ActivityToolOption(
            id: 'fertilizer_25_30kg',
            labelTh: 'ปุ๋ย 25-30 กก.',
            labelEn: 'Fertilizer 25-30 kg',
            weightKg: 27.5,
            weightBandCode: 6,
          ),
          ActivityToolOption(
            id: 'fertilizer_full_32kg',
            labelTh: 'กระสอบปุ๋ยเต็ม มากกว่า 30 กก. (ประมาณ 32 กก.)',
            labelEn: 'Full fertilizer sack over 30 kg (about 32 kg)',
            weightKg: 32.0,
            weightBandCode: 7,
          ),
          ActivityToolOption(
            id: 'spade_2kg',
            labelTh: 'เสียม (2 กก.)',
            labelEn: 'Spade (2 kg)',
            weightKg: 2.0,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'hoe_2_5kg',
            labelTh: 'จอบ (2.5 กก.)',
            labelEn: 'Hoe (2.5 kg)',
            weightKg: 2.5,
            weightBandCode: 1,
          ),
        ],
      SooktaActivity.pesticide => const [
          ActivityToolOption(
            id: 'sprayer_full_23_24kg',
            labelTh: 'ถังพ่นเต็ม 20 ลิตร (23-24 กก.)',
            labelEn: 'Full 20 L sprayer (23-24 kg)',
            weightKg: 23.5,
            weightBandCode: 5,
          ),
          ActivityToolOption(
            id: 'sprayer_15_20kg',
            labelTh: 'ถังพ่น 15-20 กก.',
            labelEn: 'Sprayer 15-20 kg',
            weightKg: 17.5,
            weightBandCode: 4,
          ),
          ActivityToolOption(
            id: 'sprayer_10_15kg',
            labelTh: 'ถังพ่น 10-15 กก.',
            labelEn: 'Sprayer 10-15 kg',
            weightKg: 12.5,
            weightBandCode: 3,
          ),
          ActivityToolOption(
            id: 'sprayer_lt10kg',
            labelTh: 'ถังพ่นน้อยกว่า 10 กก.',
            labelEn: 'Sprayer under 10 kg',
            weightKg: 7.5,
            weightBandCode: 2,
          ),
        ],
      SooktaActivity.pruning => const [
          ActivityToolOption(
            id: 'pruning_shears_0_242kg',
            labelTh: 'กรรไกรตัดแต่งกิ่ง (0.242 กก.)',
            labelEn: 'Pruning shears (0.242 kg)',
            weightKg: 0.242,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'saw_0_258kg',
            labelTh: 'เลื่อย (0.258 กก.)',
            labelEn: 'Saw (0.258 kg)',
            weightKg: 0.258,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'machete_0_320kg',
            labelTh: 'มีด/พร้า (0.320 กก.)',
            labelEn: 'Machete (0.320 kg)',
            weightKg: 0.320,
            weightBandCode: 1,
          ),
        ],
      SooktaActivity.harvesting => const [
          ActivityToolOption(
            id: 'basket_empty_2kg',
            labelTh: 'ตะกร้าเปล่า (2 กก.)',
            labelEn: 'Empty basket (2 kg)',
            weightKg: 2.0,
            weightBandCode: 1,
          ),
          ActivityToolOption(
            id: 'basket_small_5_10kg',
            labelTh: 'ตะกร้าเล็ก 5-10 กก.',
            labelEn: 'Small basket 5-10 kg',
            weightKg: 7.5,
            weightBandCode: 2,
          ),
          ActivityToolOption(
            id: 'basket_mid_10_15kg',
            labelTh: 'ตะกร้ากลาง 10-15 กก.',
            labelEn: 'Medium basket 10-15 kg',
            weightKg: 12.5,
            weightBandCode: 3,
          ),
          ActivityToolOption(
            id: 'basket_near_full_15_25kg',
            labelTh: 'ตะกร้าใกล้เต็ม 15-25 กก.',
            labelEn: 'Nearly full basket 15-25 kg',
            weightKg: 20.0,
            weightBandCode: 5,
          ),
          ActivityToolOption(
            id: 'basket_full_25_27kg',
            labelTh: 'ตะกร้าเต็ม 25-27 กก.',
            labelEn: 'Full basket 25-27 kg',
            weightKg: 26.0,
            weightBandCode: 6,
          ),
          ActivityToolOption(
            id: 'packed_basket_27_30kg',
            labelTh: 'ตะกร้าบรรจุแน่น 27-30 กก.',
            labelEn: 'Packed basket 27-30 kg',
            weightKg: 28.5,
            weightBandCode: 6,
          ),
          ActivityToolOption(
            id: 'basket_or_sack_25_30plus',
            labelTh: 'ย้ายตะกร้า/กระสอบ 25-30+ กก.',
            labelEn: 'Move basket/sack 25-30+ kg',
            weightKg: 30.0,
            weightBandCode: 7,
          ),
        ],
      SooktaActivity.transport => const [
          ActivityToolOption(
            id: 'basket_25_27kg',
            labelTh: 'ตะกร้าผลผลิต 25-27 กก.',
            labelEn: 'Produce basket 25-27 kg',
            weightKg: 26.0,
            weightBandCode: 6,
          ),
          ActivityToolOption(
            id: 'coffee_sack_30_40kg',
            labelTh: 'กระสอบกาแฟ 30-40 กก.',
            labelEn: 'Coffee sack 30-40 kg',
            weightKg: 35.0,
            weightBandCode: 7,
          ),
          ActivityToolOption(
            id: 'wheelbarrow_gt50kg',
            labelTh: 'รถเข็นบรรทุกมากกว่า 50 กก.',
            labelEn: 'Wheelbarrow load over 50 kg',
            weightKg: 50.0,
            weightBandCode: 7,
          ),
        ],
    };
  }

  ActivityToolOption get defaultToolOption {
    return switch (this) {
      SooktaActivity.transplanting => toolOptionById('seedling_bucket_5_10kg'),
      SooktaActivity.fertilizing => toolOptionById('fertilizer_15_20kg'),
      SooktaActivity.pesticide => toolOptionById('sprayer_10_15kg'),
      SooktaActivity.pruning => toolOptionById('pruning_shears_0_242kg'),
      SooktaActivity.harvesting => toolOptionById('basket_mid_10_15kg'),
      SooktaActivity.transport => toolOptionById('basket_25_27kg'),
    };
  }

  ActivityToolOption toolOptionById(String id) {
    return toolOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => toolOptions.first,
    );
  }
}

class AssessmentBundle {
  const AssessmentBundle({
    required this.activity,
    required this.activityName,
    required this.jobType,
    required this.before,
    required this.after,
    required this.selectedSuggestionKeys,
    this.breakdown,
    this.afterBreakdown,
  });

  final SooktaActivity activity;
  final String activityName;
  final JobType jobType;
  final ErgoResult before;
  final ErgoResult after;
  final List<String> selectedSuggestionKeys;
  final AssessmentBreakdown? breakdown;
  final AssessmentBreakdown? afterBreakdown;
}

class InitialRiskPayload {
  const InitialRiskPayload({
    required this.activity,
    required this.activityName,
    required this.jobType,
    required this.before,
    required this.ergoInput,
    required this.rebaInput,
    this.breakdown,
  });

  final SooktaActivity activity;
  final String activityName;
  final JobType jobType;
  final ErgoResult before;
  final ErgoInputData ergoInput;
  final RebaInputData rebaInput;
  final AssessmentBreakdown? breakdown;
}

class EvaluationDraft {
  const EvaluationDraft({
    required this.activity,
    required this.jobType,
    this.selectedImagePaths = const [],
    this.selectedToolId = '',
    this.durationHours = 1,
    this.frequency = 0.2,
    this.staticHoldLevel = 0,
    this.workDaysPerWeek = 3,
    this.loadWeight = 10,
    this.pushPullDistance = 10,
    this.initialForce = 18,
    this.sustainForce = 10,
    this.horizontalDistanceText = '25',
    this.verticalHeightText = '75',
    this.transportDistanceText = '4',
    this.showAdvancedDetails = false,
    this.rebaInput = const RebaInputData(),
    this.savedAt,
  });

  final SooktaActivity activity;
  final JobType jobType;
  final List<String> selectedImagePaths;
  final String selectedToolId;
  final double durationHours;
  final double frequency;
  final int staticHoldLevel;
  final double workDaysPerWeek;
  final double loadWeight;
  final double pushPullDistance;
  final double initialForce;
  final double sustainForce;
  final String horizontalDistanceText;
  final String verticalHeightText;
  final String transportDistanceText;
  final bool showAdvancedDetails;
  final RebaInputData rebaInput;
  final DateTime? savedAt;

  EvaluationDraft copyWith({
    SooktaActivity? activity,
    JobType? jobType,
    List<String>? selectedImagePaths,
    String? selectedToolId,
    double? durationHours,
    double? frequency,
    int? staticHoldLevel,
    double? workDaysPerWeek,
    double? loadWeight,
    double? pushPullDistance,
    double? initialForce,
    double? sustainForce,
    String? horizontalDistanceText,
    String? verticalHeightText,
    String? transportDistanceText,
    bool? showAdvancedDetails,
    RebaInputData? rebaInput,
    DateTime? savedAt,
  }) {
    return EvaluationDraft(
      activity: activity ?? this.activity,
      jobType: jobType ?? this.jobType,
      selectedImagePaths: selectedImagePaths ?? this.selectedImagePaths,
      selectedToolId: selectedToolId ?? this.selectedToolId,
      durationHours: durationHours ?? this.durationHours,
      frequency: frequency ?? this.frequency,
      staticHoldLevel: staticHoldLevel ?? this.staticHoldLevel,
      workDaysPerWeek: workDaysPerWeek ?? this.workDaysPerWeek,
      loadWeight: loadWeight ?? this.loadWeight,
      pushPullDistance: pushPullDistance ?? this.pushPullDistance,
      initialForce: initialForce ?? this.initialForce,
      sustainForce: sustainForce ?? this.sustainForce,
      horizontalDistanceText:
          horizontalDistanceText ?? this.horizontalDistanceText,
      verticalHeightText: verticalHeightText ?? this.verticalHeightText,
      transportDistanceText:
          transportDistanceText ?? this.transportDistanceText,
      showAdvancedDetails: showAdvancedDetails ?? this.showAdvancedDetails,
      rebaInput: rebaInput ?? this.rebaInput,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'activity': activity.name,
      'jobType': jobType.name,
      'selectedImagePaths': selectedImagePaths,
      'selectedToolId': selectedToolId,
      'durationHours': durationHours,
      'frequency': frequency,
      'staticHoldLevel': staticHoldLevel,
      'workDaysPerWeek': workDaysPerWeek,
      'loadWeight': loadWeight,
      'pushPullDistance': pushPullDistance,
      'initialForce': initialForce,
      'sustainForce': sustainForce,
      'horizontalDistanceText': horizontalDistanceText,
      'verticalHeightText': verticalHeightText,
      'transportDistanceText': transportDistanceText,
      'showAdvancedDetails': showAdvancedDetails,
      'rebaInput': rebaInput.toJson(),
      'savedAt': savedAt?.toIso8601String(),
    };
  }

  factory EvaluationDraft.fromJson(Map<String, Object?> json) {
    final activityName = json['activity'] as String?;
    final jobTypeName = json['jobType'] as String?;
    final activity = SooktaActivity.values.firstWhere(
      (item) => item.name == activityName,
      orElse: () => SooktaActivity.transplanting,
    );
    final jobType = JobType.values.firstWhere(
      (item) => item.name == jobTypeName,
      orElse: () => activity.defaultJobType,
    );
    final savedAtRaw = json['savedAt'] as String?;
    return EvaluationDraft(
      activity: activity,
      jobType: jobType,
      selectedImagePaths: (json['selectedImagePaths'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      selectedToolId: json['selectedToolId'] as String? ?? '',
      durationHours: _draftDouble(json['durationHours'], 1),
      frequency: _draftDouble(json['frequency'], 0.2),
      staticHoldLevel: _draftInt(json['staticHoldLevel'], 0),
      workDaysPerWeek: _draftDouble(json['workDaysPerWeek'], 3),
      loadWeight: _draftDouble(json['loadWeight'], 10),
      pushPullDistance: _draftDouble(json['pushPullDistance'], 10),
      initialForce: _draftDouble(json['initialForce'], 18),
      sustainForce: _draftDouble(json['sustainForce'], 10),
      horizontalDistanceText: json['horizontalDistanceText'] as String? ?? '25',
      verticalHeightText: json['verticalHeightText'] as String? ?? '75',
      transportDistanceText: json['transportDistanceText'] as String? ?? '4',
      showAdvancedDetails: json['showAdvancedDetails'] as bool? ?? false,
      rebaInput: json['rebaInput'] is Map
          ? RebaInputData.fromJson(
              Map<String, Object?>.from(json['rebaInput'] as Map),
            )
          : const RebaInputData(),
      savedAt: savedAtRaw == null ? null : DateTime.tryParse(savedAtRaw),
    );
  }
}

double _draftDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _draftInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
