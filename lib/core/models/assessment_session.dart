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
      SooktaActivity.transplanting => 'Transplanting',
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
  });

  final SooktaActivity activity;
  final String activityName;
  final JobType jobType;
  final ErgoResult before;
  final ErgoResult after;
  final List<String> selectedSuggestionKeys;
  final AssessmentBreakdown? breakdown;
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
