import 'package:flutter/material.dart';

import '../core/models/evaluation_models.dart';
import '../core/services/ergo_calculator.dart';
import '../core/theme/sookta_theme.dart';

class AssessmentBreakdownCard extends StatelessWidget {
  const AssessmentBreakdownCard({
    required this.breakdown,
    required this.thai,
    super.key,
  });

  final AssessmentBreakdown? breakdown;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final data = breakdown;
    if (data == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            thai
                ? 'ยังไม่มีรายละเอียดการคำนวณสำหรับรายการนี้'
                : 'No calculation details are available for this record.',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    final reba = ErgoCalculator.calculateRebaScoreBreakdown(data.rebaInput);
    final worst = _worstFrame(data);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              thai ? 'รายละเอียดการคำนวณ' : 'Calculation details',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              thai
                  ? 'ใช้ REBA กับทุกกิจกรรม และใช้ ISO11228 เพิ่มเมื่องานนั้นเป็นงานยก/ขนย้าย หรือดัน/ลาก'
                  : 'REBA is used for every activity. ISO11228 is added for lifting/carrying or push/pull work.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (data.motionSummary != null && data.motionSummary!.isVideo) ...[
              _SectionTitle(thai
                  ? 'สรุปการเคลื่อนไหวจากวิดีโอ'
                  : 'Video-derived motion summary'),
              _DetailRow(
                label: thai ? 'ความยาววิดีโอ' : 'Video duration',
                value:
                    '${(data.motionSummary!.durationMs / 1000).toStringAsFixed(1)}s',
              ),
              _DetailRow(
                label: thai ? 'เฟรมที่อ่านได้' : 'Readable frames',
                value:
                    '${data.motionSummary!.readableFrameCount}/${data.motionSummary!.sampledFrameCount}',
              ),
              _DetailRow(
                label: thai ? 'เฟรมเสี่ยงสูง' : 'High-risk frames',
                value: _percent(data.motionSummary!.highRiskFrameRatio),
              ),
              _DetailRow(
                label:
                    thai ? 'เฟรมที่มีส่วนร่างกายเสี่ยง' : 'Segment-risk frames',
                value: _percent(data.motionSummary!.anySegmentRiskFrameRatio),
              ),
              _DetailRow(
                label: thai ? 'ส่วนร่างกายเด่น' : 'Dominant body segment',
                value: _bodyPartLabel(
                  data.motionSummary!.dominantRiskBodyPart,
                  thai,
                ),
              ),
              _DetailRow(
                label: thai
                    ? 'เวลาช่วงเสี่ยงรายส่วนโดยประมาณ'
                    : 'Estimated segment-risk time',
                value:
                    '${data.motionSummary!.estimatedSegmentRiskSeconds.toStringAsFixed(1)}s',
              ),
              _DetailRow(
                label: thai
                    ? 'เวลาช่วงเสี่ยงรวมโดยประมาณ'
                    : 'Estimated high-risk time',
                value:
                    '${data.motionSummary!.estimatedHighRiskSeconds.toStringAsFixed(1)}s',
              ),
              _DetailRow(
                label: thai ? 'รูปแบบการเคลื่อนไหว' : 'Motion pattern',
                value: _motionPatternLabel(data.motionSummary!.pattern, thai),
              ),
              _DetailRow(
                label: thai ? 'สัดส่วนรายส่วน' : 'Segment ratios',
                value: thai
                    ? 'คอ ${_percent(data.motionSummary!.neckRiskFrameRatio)}, ลำตัว ${_percent(data.motionSummary!.trunkRiskFrameRatio)}, ต้นแขน ${_percent(data.motionSummary!.upperArmRiskFrameRatio)}, ปลายแขน ${_percent(data.motionSummary!.lowerArmRiskFrameRatio)}, ข้อมือ ${_percent(data.motionSummary!.wristRiskFrameRatio)}, ขา ${_percent(data.motionSummary!.legRiskFrameRatio)}'
                    : 'neck ${_percent(data.motionSummary!.neckRiskFrameRatio)}, trunk ${_percent(data.motionSummary!.trunkRiskFrameRatio)}, upper arm ${_percent(data.motionSummary!.upperArmRiskFrameRatio)}, lower arm ${_percent(data.motionSummary!.lowerArmRiskFrameRatio)}, wrist ${_percent(data.motionSummary!.wristRiskFrameRatio)}, legs ${_percent(data.motionSummary!.legRiskFrameRatio)}',
              ),
              const SizedBox(height: 10),
            ],
            if (data.poseFrames.isNotEmpty) ...[
              _SectionTitle(thai ? 'ภาพที่ใช้ประเมิน' : 'Photo analysis'),
              ...data.poseFrames.map(
                (frame) => _DetailRow(
                  label: thai
                      ? 'ภาพที่ ${frame.imageIndex}'
                      : 'Photo ${frame.imageIndex}',
                  value: thai
                      ? 'คอ ${_deg(frame.neckFlexionDeg)}, ลำตัว ${_deg(frame.trunkFlexionDeg)}, ต้นแขน ${_deg(frame.upperArmFlexionDeg)}, REBA ${frame.rebaScore}${frame.imageIndex == data.worstPoseImageIndex ? ' • Worst Posture' : ''}'
                      : 'neck ${_deg(frame.neckFlexionDeg)}, trunk ${_deg(frame.trunkFlexionDeg)}, upper arm ${_deg(frame.upperArmFlexionDeg)}, REBA ${frame.rebaScore}${frame.imageIndex == data.worstPoseImageIndex ? ' • Worst Posture' : ''}',
                ),
              ),
              if (worst != null)
                _DetailRow(
                  label: thai ? 'เหตุผลภาพหลัก' : 'Main photo reason',
                  value: thai
                      ? 'เลือกภาพที่ ${worst.imageIndex} เพราะมีคะแนน REBA สูงที่สุด (${worst.rebaScore})'
                      : 'Photo ${worst.imageIndex} was selected because it has the highest REBA score (${worst.rebaScore}).',
                ),
              const SizedBox(height: 10),
            ],
            _SectionTitle(thai ? 'คะแนนย่อย REBA' : 'REBA sub-scores'),
            _DetailRow(
              label: 'Group A',
              value: thai
                  ? 'คอ ${data.rebaInput.neckScore}, ลำตัว ${data.rebaInput.trunkScore} → ${reba.adjustedTrunkScore}, ขา ${data.rebaInput.legScore}, Table A ${reba.tableAScore}, Load +${data.rebaInput.loadScore}, Score A ${reba.scoreA}'
                  : 'neck ${data.rebaInput.neckScore}, trunk ${data.rebaInput.trunkScore} → ${reba.adjustedTrunkScore}, legs ${data.rebaInput.legScore}, Table A ${reba.tableAScore}, Load +${data.rebaInput.loadScore}, Score A ${reba.scoreA}',
            ),
            _DetailRow(
              label: 'Group B',
              value: thai
                  ? 'ต้นแขน ${data.rebaInput.upperArmScore}, ปลายแขน ${data.rebaInput.lowerArmScore}, ข้อมือ ${data.rebaInput.wristScore} → ${reba.adjustedWristScore}, Table B ${reba.tableBScore}, Coupling +${data.rebaInput.couplingScore}, Score B ${reba.scoreB}'
                  : 'upper arm ${data.rebaInput.upperArmScore}, lower arm ${data.rebaInput.lowerArmScore}, wrist ${data.rebaInput.wristScore} → ${reba.adjustedWristScore}, Table B ${reba.tableBScore}, Coupling +${data.rebaInput.couplingScore}, Score B ${reba.scoreB}',
            ),
            _DetailRow(
              label: 'Group C',
              value: thai
                  ? 'Score C ${reba.scoreC}, Activity +${reba.activityScore}, Final REBA ${reba.finalScore}'
                  : 'Score C ${reba.scoreC}, Activity +${reba.activityScore}, Final REBA ${reba.finalScore}',
            ),
            const SizedBox(height: 10),
            _SectionTitle(thai ? 'เหตุผลที่ได้คะแนน' : 'Why this score'),
            ..._scoreReasons(data, worst).map(
              (reason) => _Bullet(text: reason),
            ),
            const SizedBox(height: 6),
            _SectionTitle(thai ? 'เกณฑ์ REBA ที่ใช้' : 'REBA criteria used'),
            _Bullet(
              text: thai
                  ? 'ลำตัว: 0-5° = 1, 5-20° = 2, 20-60° = 3, มากกว่า 60° = 4'
                  : 'Trunk: 0-5° = 1, 5-20° = 2, 20-60° = 3, >60° = 4',
            ),
            _Bullet(
              text: thai
                  ? 'คอ: ไม่เกิน 20° = 1, มากกว่า 20° = 2 และเพิ่มเมื่อพบการบิด/เอียง'
                  : 'Neck: <=20° = 1, >20° = 2, with modifiers for twist/side bend',
            ),
            _Bullet(
              text: thai
                  ? 'ต้นแขน: ไม่เกิน 20° = 1, 20-45° = 2, 45-90° = 3, มากกว่า 90° = 4'
                  : 'Upper arm: <=20° = 1, 20-45° = 2, 45-90° = 3, >90° = 4',
            ),
            _Bullet(
              text: thai
                  ? 'ปลายแขน: 60-100° = 1, นอกช่วงนี้ = 2; ขา: เข่างอมาก/ไม่สมดุล = 2'
                  : 'Lower arm: 60-100° = 1, outside range = 2; legs: bent/unstable = 2',
            ),
            const SizedBox(height: 10),
            _SectionTitle(thai
                ? 'ข้อมูล ISO11228 / งานซ้ำ'
                : 'ISO11228 / repetitive work'),
            _DetailRow(
              label: thai ? 'ระยะเวลา' : 'Duration',
              value: thai
                  ? '${_num(data.ergoInput.durationHours)} ชม.'
                  : '${_num(data.ergoInput.durationHours)} hr',
            ),
            _DetailRow(
              label: thai ? 'ความถี่' : 'Frequency',
              value: thai
                  ? '${_num(data.ergoInput.liftFrequency)} ครั้ง/นาที'
                  : '${_num(data.ergoInput.liftFrequency)} times/min',
            ),
            _DetailRow(
              label: thai ? 'วันทำงานต่อสัปดาห์' : 'Work days per week',
              value: thai
                  ? '${_num(data.ergoInput.workDaysPerWeek)} วัน/สัปดาห์'
                  : '${_num(data.ergoInput.workDaysPerWeek)} days/week',
            ),
            _DetailRow(
              label: thai ? 'น้ำหนัก/แรง' : 'Load/force',
              value: thai
                  ? '${_num(data.ergoInput.loadWeight)} กก. • Load Score +${data.rebaInput.loadScore}'
                  : '${_num(data.ergoInput.loadWeight)} kg • Load Score +${data.rebaInput.loadScore}',
            ),
            _DetailRow(
              label: thai ? 'การจับยึด' : 'Coupling',
              value: thai
                  ? 'Coupling Score +${data.rebaInput.couplingScore}'
                  : 'Coupling Score +${data.rebaInput.couplingScore}',
            ),
          ],
        ),
      ),
    );
  }

  List<String> _scoreReasons(
    AssessmentBreakdown data,
    PoseRebaFrameAnalysis? worst,
  ) {
    final input = data.rebaInput;
    return [
      if (worst?.neckFlexionDeg != null)
        thai
            ? 'คอ: มุมก้มประมาณ ${_deg(worst!.neckFlexionDeg)} ทำให้ Neck Score = ${input.neckScore}'
            : 'Neck: flexion around ${_deg(worst!.neckFlexionDeg)} gives Neck Score = ${input.neckScore}',
      if (worst?.trunkFlexionDeg != null)
        thai
            ? 'ลำตัว/หลัง: มุมก้มประมาณ ${_deg(worst!.trunkFlexionDeg)} ทำให้ Trunk Score = ${input.trunkScore}'
            : 'Trunk/back: flexion around ${_deg(worst!.trunkFlexionDeg)} gives Trunk Score = ${input.trunkScore}',
      if (input.trunkTwist || input.trunkSideFlex)
        thai
            ? 'ลำตัวมีการบิดหรือเอียง จึงเพิ่มคะแนนลำตัวเป็น ${input.adjustedTrunkScore}'
            : 'Trunk twist or side bending was detected, so adjusted trunk score is ${input.adjustedTrunkScore}',
      thai
          ? 'Activity Score = +${input.activityScore} จากระยะเวลา/ความถี่/การค้างท่าที่ตั้งไว้ในแบบประเมิน'
          : 'Activity Score = +${input.activityScore}, based on duration, frequency, and static posture settings.',
    ];
  }
}

Map<BodyPart, List<String>> assessmentBodyRiskReasons(
  AssessmentBreakdown? breakdown,
  bool thai,
) {
  final data = breakdown;
  if (data == null) return const {};
  final worst = _worstFrame(data);
  final input = data.rebaInput;
  return {
    BodyPart.neck: [
      if (worst?.neckFlexionDeg != null)
        thai
            ? 'ก้มคอประมาณ ${_deg(worst!.neckFlexionDeg)}'
            : 'Neck flexion around ${_deg(worst!.neckFlexionDeg)}',
      if (worst?.neckSideBending == true)
        thai ? 'พบการเอียงคอ' : 'Neck side bend detected',
      if (worst?.neckTwisting == true)
        thai ? 'พบการบิดคอ' : 'Neck twist detected',
      thai
          ? 'Neck Score = ${input.neckScore}'
          : 'Neck Score = ${input.neckScore}',
    ],
    BodyPart.trunk: [
      if (worst?.trunkFlexionDeg != null)
        thai
            ? 'ก้มลำตัวประมาณ ${_deg(worst!.trunkFlexionDeg)}'
            : 'Trunk flexion around ${_deg(worst!.trunkFlexionDeg)}',
      if (input.trunkTwist) thai ? 'มีการบิดลำตัว' : 'Trunk twist',
      if (input.trunkSideFlex) thai ? 'มีการเอียงลำตัว' : 'Trunk side bend',
      thai
          ? 'Trunk Score = ${input.adjustedTrunkScore}'
          : 'Trunk Score = ${input.adjustedTrunkScore}',
    ],
    BodyPart.arms: [
      if (worst?.upperArmFlexionDeg != null)
        thai
            ? 'ยกต้นแขนประมาณ ${_deg(worst!.upperArmFlexionDeg)}'
            : 'Upper arm flexion around ${_deg(worst!.upperArmFlexionDeg)}',
      if (worst?.upperArmAbduction == true)
        thai ? 'พบการกางแขน' : 'Arm abduction detected',
      if (worst?.shoulderElevation == true)
        thai ? 'พบการยกไหล่/ยกแขนสูง' : 'Shoulder/arm raised',
      thai
          ? 'Upper/Lower Arm Score = ${input.upperArmScore}/${input.lowerArmScore}'
          : 'Upper/Lower Arm Score = ${input.upperArmScore}/${input.lowerArmScore}',
    ],
    BodyPart.wrists: [
      thai
          ? 'Wrist Score = ${input.adjustedWristScore}'
          : 'Wrist Score = ${input.adjustedWristScore}',
      if (input.wristTwist) thai ? 'มีการบิดข้อมือ' : 'Wrist twist',
      if (input.couplingScore > 0)
        thai
            ? 'การจับยึดเพิ่มคะแนน +${input.couplingScore}'
            : 'Coupling adds +${input.couplingScore}',
    ],
    BodyPart.legs: [
      if (worst?.kneeAngleDeg != null)
        thai
            ? 'มุมเข่าประมาณ ${_deg(worst!.kneeAngleDeg)}'
            : 'Knee angle around ${_deg(worst!.kneeAngleDeg)}',
      thai ? 'Leg Score = ${input.legScore}' : 'Leg Score = ${input.legScore}',
    ],
  };
}

PoseRebaFrameAnalysis? _worstFrame(AssessmentBreakdown data) {
  if (data.poseFrames.isEmpty) return null;
  final target = data.worstPoseImageIndex;
  if (target != null) {
    for (final frame in data.poseFrames) {
      if (frame.imageIndex == target) return frame;
    }
  }
  return data.poseFrames.reduce(
    (current, next) => next.rebaScore > current.rebaScore ? next : current,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: SooktaColors.darkGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

String _deg(double? value) {
  if (value == null || value.isNaN) return '-';
  return '${value.round()}°';
}

String _num(double value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _percent(double ratio) => '${(ratio * 100).round()}%';

String _motionPatternLabel(MotionPattern pattern, bool thai) {
  if (thai) {
    return switch (pattern) {
      MotionPattern.stableLowRisk => 'ท่าทางค่อนข้างคงที่และเสี่ยงต่ำ',
      MotionPattern.intermittentWorstPosture => 'มีช่วงท่าเสี่ยงเป็นบางจุด',
      MotionPattern.repeatedRiskMovement => 'มีการเคลื่อนไหวเสี่ยงซ้ำ',
      MotionPattern.staticHighRiskHold => 'ค้างท่าเสี่ยงสูงหลายช่วง',
    };
  }
  return switch (pattern) {
    MotionPattern.stableLowRisk => 'stable lower-risk posture',
    MotionPattern.intermittentWorstPosture => 'intermittent worst posture',
    MotionPattern.repeatedRiskMovement => 'repeated risk movement',
    MotionPattern.staticHighRiskHold => 'static high-risk hold',
  };
}

String _bodyPartLabel(String? key, bool thai) {
  if (key == null) return thai ? 'ไม่พบส่วนเด่น' : 'none';
  if (thai) {
    return switch (key) {
      'neck' => 'คอ',
      'trunk' => 'ลำตัว/หลัง',
      'upper_arm' => 'ต้นแขน/ไหล่',
      'lower_arm' => 'ปลายแขน',
      'wrist' => 'ข้อมือ',
      'legs' => 'ขา/เข่า',
      _ => key,
    };
  }
  return switch (key) {
    'neck' => 'neck',
    'trunk' => 'trunk/back',
    'upper_arm' => 'upper arm/shoulder',
    'lower_arm' => 'lower arm',
    'wrist' => 'wrist',
    'legs' => 'legs/knees',
    _ => key,
  };
}
