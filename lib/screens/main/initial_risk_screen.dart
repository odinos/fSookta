import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/localization/sookta_strings.dart';
import '../../core/models/assessment_session.dart';
import '../../core/models/economic_impact_models.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/economic_impact_service.dart';
import '../../core/services/risk_recommendation_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/research_disclaimer_card.dart';
import '../../widgets/responsive_content.dart';
import 'final_result_screen.dart';

class InitialRiskScreen extends StatefulWidget {
  const InitialRiskScreen({
    required this.payload,
    super.key,
  });

  static const routeName = '/initial-risk';

  final InitialRiskPayload payload;

  @override
  State<InitialRiskScreen> createState() => _InitialRiskScreenState();
}

class _InitialRiskScreenState extends State<InitialRiskScreen> {
  final selectedKeys = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final strings = SooktaStrings(thai ? SooktaLocale.th : SooktaLocale.en);
    final before = widget.payload.before;
    final suggestions = _suggestionsFor(before, widget.payload.activity);
    final impact = EconomicImpactService.estimate(
      overallRisk: before.riskLevel,
      dailyIncome: state.dailyIncome.toDouble(),
      bodyPartRisks: before.bodyPartRisks,
    );
    final after = _simulateAfter(before);

    return Scaffold(
      appBar: AppBar(
          title: Text(thai ? 'ผลการประเมินเบื้องต้น' : 'Initial Assessment')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 640,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              thai
                  ? 'กิจกรรม: ${widget.payload.activityName}'
                  : 'Activity: ${widget.payload.activityName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _FarmerGuideCard(
              before: before,
              after: after,
              selectedCount: selectedKeys.length,
              thai: thai,
            ),
            const SizedBox(height: 16),
            _RiskSummaryCard(
              result: before,
              title: thai ? 'คะแนนก่อนปรับปรุง' : 'Before Improvement',
              suggestion: strings.get(before.suggestionKey),
              thai: thai,
            ),
            const SizedBox(height: 16),
            _EconomicImpactCard(
              impact: impact,
              overallRisk: before.riskLevel,
              thai: thai,
            ),
            const SizedBox(height: 12),
            ResearchDisclaimerCard(thai: thai),
            if (before.aiRiskAlert != null) ...[
              const SizedBox(height: 16),
              _AiRiskAlertCard(
                alert: before.aiRiskAlert!,
                thai: thai,
              ),
            ],
            const SizedBox(height: 16),
            _BodyMapCard(
              bodyRisks: before.bodyPartRisks,
              thai: thai,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      thai
                          ? 'เลือกวิธีลดความเสี่ยง'
                          : 'Choose risk-reduction actions',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      thai
                          ? 'แตะเลือกเฉพาะข้อที่ทำได้จริง ระบบจะคำนวณคะแนนหลังปรับให้ทันที'
                          : 'Tap only the actions you can really do. The app recalculates the after score immediately.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map((key) {
                      final action = _actionFor(key);
                      return CheckboxListTile(
                        value: selectedKeys.contains(key),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedKeys.add(key);
                            } else {
                              selectedKeys.remove(key);
                            }
                          });
                        },
                        title: Text(strings.get(key)),
                        subtitle: Text(
                          thai
                              ? 'คาดว่าลดคะแนน ${action.scoreReduction} จุด • ลดความเสี่ยง ${action.partLabels(thai: true)}'
                              : 'Estimated score reduction ${action.scoreReduction} • Targets ${action.partLabels(thai: false)}',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RiskSummaryCard(
              result: after,
              title: thai
                  ? 'ถ้าทำตามที่เลือก คะแนนจะเป็น'
                  : 'If selected actions are done',
              suggestion: selectedKeys.isEmpty
                  ? (thai
                      ? 'ยังไม่ได้เลือกวิธีลดความเสี่ยง'
                      : 'No risk-reduction action selected')
                  : (thai
                      ? 'คะแนนลดลงตามวิธีที่เลือก'
                      : 'Score reduced by selected actions'),
              thai: thai,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  FinalResultScreen.routeName,
                  arguments: AssessmentBundle(
                    activity: widget.payload.activity,
                    activityName: widget.payload.activityName,
                    jobType: widget.payload.jobType,
                    before: before,
                    after: after,
                    selectedSuggestionKeys: selectedKeys.toList(),
                    breakdown: widget.payload.breakdown,
                  ),
                );
              },
              icon: const Icon(Icons.summarize_outlined),
              label: Text(thai ? 'ดูผลหลังปรับปรุง' : 'View Improved Result'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _suggestionsFor(ErgoResult result, SooktaActivity activity) {
    final keys = <String>{
      ...RiskRecommendationService.activityKeys(
        activity: activity,
        riskLevel: result.riskLevel,
      ),
      ...result.suggestionKeys,
    };
    if (keys.isEmpty) keys.add('act_rest_stretch');
    return keys.toList();
  }

  ErgoResult _simulateAfter(ErgoResult before) {
    final reduction = math.min(
      selectedKeys.fold<int>(
        0,
        (sum, key) => sum + _actionFor(key).scoreReduction,
      ),
      4,
    );
    final score = (before.userScore - reduction).clamp(1, 9).toInt();
    final risk = _riskFromUserScore(score);
    final lossFactor =
        selectedKeys.isEmpty ? 1.0 : math.max(0.0, 1 - (0.28 * reduction));
    final affectedParts = <BodyPart>{};
    for (final key in selectedKeys) {
      affectedParts.addAll(_actionFor(key).bodyParts);
    }
    return ErgoResult(
      riskLevel: risk,
      techScore: math.max(1.0, before.techScore - reduction),
      userScore: score,
      userScoreColor: _scoreColor(score),
      limitValue: before.limitValue,
      suggestionKey: before.suggestionKey,
      economicLoss: (before.economicLoss * lossFactor).round(),
      suggestionKeys: before.suggestionKeys,
      bodyPartRisks: before.bodyPartRisks.map(
        (part, level) => MapEntry(
          part,
          affectedParts.contains(part) ? _lowerRisk(level) : level,
        ),
      ),
    );
  }

  _ImprovementAction _actionFor(String key) {
    if (key.startsWith('act_ref_weight_')) {
      return const _ImprovementAction(
        scoreReduction: 2,
        bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
      );
    }
    if (key.startsWith('act_transplant_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 2,
        bodyParts: {BodyPart.trunk, BodyPart.neck, BodyPart.legs},
      );
    }
    if (key.startsWith('act_fert_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 2,
        bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
      );
    }
    if (key.startsWith('act_pesticide_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 1,
        bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
      );
    }
    if (key.startsWith('act_pruning_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 1,
        bodyParts: {BodyPart.neck, BodyPart.arms, BodyPart.wrists},
      );
    }
    if (key.startsWith('act_harvest_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 1,
        bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
      );
    }
    if (key.startsWith('act_transport_ref_')) {
      return const _ImprovementAction(
        scoreReduction: 2,
        bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
      );
    }

    return switch (key) {
      'act_reduce_weight' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
        ),
      'act_use_cart_distance' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
        ),
      'act_check_wheels' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.trunk},
        ),
      'act_use_legs' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.legs},
        ),
      'act_iso_keep_load_close' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms},
        ),
      'act_iso_lift_height' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms},
        ),
      'act_iso_reduce_frequency' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {
            BodyPart.trunk,
            BodyPart.arms,
            BodyPart.wrists,
            BodyPart.legs,
          },
        ),
      'act_iso_improve_grip' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.wrists},
        ),
      'act_iso_plan_recovery' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {
            BodyPart.neck,
            BodyPart.trunk,
            BodyPart.arms,
            BodyPart.wrists,
            BodyPart.legs,
          },
        ),
      'act_iso_push_smooth' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms},
        ),
      'act_iso_push_handle_height' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
        ),
      'act_iso_reduce_push_distance' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
        ),
      'act_iso_floor_level' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.legs, BodyPart.trunk},
        ),
      'act_iso_push_not_pull' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms},
        ),
      'act_reduce_load_tool' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
        ),
      'act_avoid_bend' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk},
        ),
      'act_adj_eye_level' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.neck, BodyPart.trunk},
        ),
      'act_reduce_arm_raise' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms},
        ),
      'act_adj_wrist' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.wrists, BodyPart.arms},
        ),
      'act_iso_job_rotation' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {
            BodyPart.neck,
            BodyPart.trunk,
            BodyPart.arms,
            BodyPart.wrists,
            BodyPart.legs,
          },
        ),
      'act_iso_neutral_reach' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.neck, BodyPart.trunk, BodyPart.arms},
        ),
      'act_iso_tool_handle_fit' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.wrists},
        ),
      'act_transplant_raise_bed' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.neck, BodyPart.legs},
        ),
      'act_transplant_low_stool' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.legs},
        ),
      'act_extra_spray_strap' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.trunk},
        ),
      'act_extra_spray_switch' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.trunk},
        ),
      'act_spray_extension' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.arms, BodyPart.wrists, BodyPart.neck},
        ),
      'act_extra_prune_ladder' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.neck, BodyPart.arms, BodyPart.trunk},
        ),
      'act_extra_prune_tool' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.neck, BodyPart.arms},
        ),
      'act_harvest_empty_often' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
        ),
      'act_harvest_move_closer' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
        ),
      'act_extra_fert_cart' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
        ),
      'act_fert_split_load' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.wrists},
        ),
      'act_transport_two_person' => const _ImprovementAction(
          scoreReduction: 2,
          bodyParts: {BodyPart.trunk, BodyPart.arms, BodyPart.legs},
        ),
      'act_transport_clear_path' => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {BodyPart.legs, BodyPart.trunk},
        ),
      _ => const _ImprovementAction(
          scoreReduction: 1,
          bodyParts: {
            BodyPart.neck,
            BodyPart.trunk,
            BodyPart.legs,
            BodyPart.arms,
            BodyPart.wrists,
          },
        ),
    };
  }

  RiskLevel _riskFromUserScore(int score) {
    if (score <= 3) return RiskLevel.low;
    if (score <= 6) return RiskLevel.medium;
    if (score <= 8) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  RiskLevel _lowerRisk(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryHigh => RiskLevel.high,
      RiskLevel.high => RiskLevel.medium,
      RiskLevel.medium => RiskLevel.low,
      RiskLevel.low => RiskLevel.low,
    };
  }

  int _scoreColor(int score) {
    const colors = [
      0xFF8BC34A,
      0xFF9CCC65,
      0xFFAED581,
      0xFFDCE775,
      0xFFFFF176,
      0xFFFFD54F,
      0xFFFFB74D,
      0xFFFF8A65,
      0xFFFF5252,
    ];
    return colors[(score - 1).clamp(0, 8).toInt()];
  }
}

class _FarmerGuideCard extends StatelessWidget {
  const _FarmerGuideCard({
    required this.before,
    required this.after,
    required this.selectedCount,
    required this.thai,
  });

  final ErgoResult before;
  final ErgoResult after;
  final int selectedCount;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final improved = selectedCount > 0 && after.userScore < before.userScore;
    return Card(
      color: const Color(0xFFF4FBF5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  improved
                      ? Icons.thumb_up_alt_outlined
                      : Icons.front_hand_outlined,
                  color: SooktaColors.darkGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai ? 'อ่านตรงนี้ก่อน' : 'Read this first',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'คะแนนตอนนี้คือ ${before.userScore} (${before.riskLevel.label})'
                  : 'Current score is ${before.userScore} (${_riskLabel(before.riskLevel)})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              improved
                  ? (thai
                      ? 'ถ้าทำตามที่เลือก คะแนนจะลดเหลือ ${after.userScore} ให้เจ้าหน้าที่ช่วยดูต่อได้'
                      : 'With selected actions, the score may drop to ${after.userScore}. Staff can review the export.')
                  : (thai
                      ? 'เลือกวิธีที่ทำได้จริงด้านล่าง ไม่ต้องกรอกข้อมูลเพิ่ม'
                      : 'Choose practical actions below. No extra form is needed.'),
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  String _riskLabel(RiskLevel risk) {
    return switch (risk) {
      RiskLevel.low => 'low risk',
      RiskLevel.medium => 'medium risk',
      RiskLevel.high => 'high risk',
      RiskLevel.veryHigh => 'very high risk',
    };
  }
}

class _AiRiskAlertCard extends StatelessWidget {
  const _AiRiskAlertCard({
    required this.alert,
    required this.thai,
  });

  final AiRiskAlert alert;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final percent = (alert.probability * 100).round();
    final color = _levelColor(alert.level);
    final title =
        thai ? 'สัญญาณช่วยเฝ้าระวังท่าทาง' : 'Posture Awareness Signal';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_alt_outlined, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  backgroundColor: color.withValues(alpha: 0.12),
                  label: Text(
                    '$percent%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _levelLabel(alert.level, thai),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              thai
                  ? 'เป็นการประมาณแนวโน้มในต้นแบบวิจัยจากข้อมูลท่าทางและคะแนนงาน ไม่ใช่การทำนายการบาดเจ็บรายบุคคล'
                  : 'This research-prototype estimate uses posture and task scores. It is not an individual injury prediction.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              thai
                  ? 'ปัจจัยที่ใช้สื่อสารความเสี่ยง'
                  : 'Factors used for risk communication',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...alert.featureImportance.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(feature.label(thai: thai))),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 92,
                      child: LinearProgressIndicator(
                        value: feature.score.clamp(0.0, 1.0).toDouble(),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(AiAlertLevel level) {
    return switch (level) {
      AiAlertLevel.low => SooktaColors.leafGreen,
      AiAlertLevel.watch => Colors.amber.shade700,
      AiAlertLevel.high => Colors.deepOrange,
      AiAlertLevel.critical => Colors.red.shade800,
    };
  }

  String _levelLabel(AiAlertLevel level, bool thai) {
    if (thai) {
      return switch (level) {
        AiAlertLevel.low => 'ความเสี่ยงต่ำ',
        AiAlertLevel.watch => 'ควรเฝ้าระวังท่าทางนี้',
        AiAlertLevel.high => 'ความเสี่ยงสูง ควรปรับท่าทาง',
        AiAlertLevel.critical => 'ความเสี่ยงสูงมาก ควรปรับท่าทางทันที',
      };
    }
    return switch (level) {
      AiAlertLevel.low => 'Low risk',
      AiAlertLevel.watch => 'Watch this posture',
      AiAlertLevel.high => 'High risk, improve posture',
      AiAlertLevel.critical => 'Very high risk, improve posture now',
    };
  }
}

class _RiskSummaryCard extends StatelessWidget {
  const _RiskSummaryCard({
    required this.result,
    required this.title,
    required this.suggestion,
    required this.thai,
  });

  final ErgoResult result;
  final String title;
  final String suggestion;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final color = Color(result.userScoreColor);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 320;
            final score = Container(
              width: compact ? 74 : 86,
              height: compact ? 74 : 86,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: FixedTextScale(
                  child: Text(
                    '${result.userScore}',
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 30 : 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_riskLabel(result.riskLevel, thai)),
                const SizedBox(height: 4),
                Text(suggestion, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Text(
                  thai
                      ? 'ผลกระทบประมาณ ${_money(result.economicLoss)}'
                      : 'Estimated impact ${_money(result.economicLoss)}',
                  style: const TextStyle(color: SooktaColors.darkGreen),
                ),
              ],
            );
            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: score),
                  const SizedBox(height: 12),
                  details,
                ],
              );
            }
            return Row(
              children: [
                score,
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }

  String _riskLabel(RiskLevel level, bool thai) {
    if (thai) return level.label;
    return switch (level) {
      RiskLevel.low => 'Low Risk',
      RiskLevel.medium => 'Medium Risk',
      RiskLevel.high => 'High Risk',
      RiskLevel.veryHigh => 'Very High Risk',
    };
  }

  String _money(int amount) {
    return thai ? '$amount บ.' : '$amount THB';
  }
}

class _EconomicImpactCard extends StatelessWidget {
  const _EconomicImpactCard({
    required this.impact,
    required this.overallRisk,
    required this.thai,
  });

  final EconomicImpactBreakdown impact;
  final RiskLevel overallRisk;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final color = Color(overallRisk.colorHex);
    final topBodyImpacts = impact.bodyImpacts.take(3).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai
                        ? 'ผลกระทบที่อาจเกิดจากท่าทางเสี่ยง'
                        : 'Estimated impact from risky posture',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _money(impact.totalCost),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      thai
                          ? 'ประมาณการค่าใช้จ่ายและรายได้ที่อาจลดลง'
                          : 'Estimated care cost and potential income impact',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ImpactRow(
              icon: Icons.medical_services_outlined,
              label:
                  thai ? 'ค่าใช้จ่ายดูแลรักษาโดยประมาณ' : 'Estimated care cost',
              value: _money(impact.bodyTreatmentCost),
            ),
            _ImpactRow(
              icon: Icons.local_hospital_outlined,
              label:
                  thai ? 'ค่าพบแพทย์/คลินิกโดยประมาณ' : 'Estimated visit cost',
              value: _money(impact.medicalVisitCost),
            ),
            _ImpactRow(
              icon: Icons.medication_outlined,
              label: thai ? 'ค่ายาและเวชภัณฑ์' : 'Medicine and supplies',
              value: _money(impact.medicineAndSuppliesCost),
            ),
            _ImpactRow(
              icon: Icons.directions_car_outlined,
              label: thai ? 'ค่าเดินทาง' : 'Travel',
              value: _money(impact.travelCost),
            ),
            _ImpactRow(
              icon: Icons.work_off_outlined,
              label: thai
                  ? 'รายได้ที่อาจสูญเสีย/ลดลง'
                  : 'Potential lost/reduced income',
              value: _money(impact.lostIncome + impact.reducedIncome),
            ),
            if (topBodyImpacts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                thai
                    ? 'ตำแหน่งที่มีผลต่อประมาณการ'
                    : 'Body areas affecting the estimate',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...topBodyImpacts.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Color(item.riskLevel.colorHex),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_partLabel(item.bodyPart, thai))),
                      Text(_money(item.estimatedTreatmentCost)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'ตัวเลขนี้เป็นประมาณการจากข้อมูลสำรวจค่าใช้จ่ายและรายได้ของกลุ่มตัวอย่าง ใช้เพื่อช่วยตัดสินใจเบื้องต้น ไม่ใช่ค่ารักษาเฉพาะบุคคล'
                  : 'This is estimated from care-cost and income-impact survey data. It supports early decision-making and is not a personal medical bill.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _money(int amount) => thai ? '$amount บ.' : '$amount THB';
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SooktaColors.darkGreen),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BodyMapCard extends StatelessWidget {
  const _BodyMapCard({
    required this.bodyRisks,
    required this.thai,
  });

  final Map<BodyPart, RiskLevel> bodyRisks;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final parts = BodyPart.values;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              thai ? 'ตำแหน่งที่เสี่ยงบนร่างกาย' : 'Risk points on body map',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final height =
                    (constraints.maxWidth * 0.78).clamp(230.0, 320.0);
                return SizedBox(
                  height: height,
                  child: CustomPaint(
                    painter: _BodyRiskPainter(
                      bodyRisks: bodyRisks,
                      thai: thai,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: parts.map((part) {
                final risk = bodyRisks[part] ?? RiskLevel.low;
                return Chip(
                  avatar: CircleAvatar(backgroundColor: Color(risk.colorHex)),
                  label: Text('${_partLabel(part, thai)}: ${_shortRisk(risk)}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _shortRisk(RiskLevel level) {
    if (thai) {
      return switch (level) {
        RiskLevel.low => 'ต่ำ',
        RiskLevel.medium => 'ปานกลาง',
        RiskLevel.high => 'สูง',
        RiskLevel.veryHigh => 'สูงมาก',
      };
    }
    return switch (level) {
      RiskLevel.low => 'Low',
      RiskLevel.medium => 'Med',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'V.High',
    };
  }
}

class _BodyRiskPainter extends CustomPainter {
  const _BodyRiskPainter({
    required this.bodyRisks,
    required this.thai,
  });

  final Map<BodyPart, RiskLevel> bodyRisks;
  final bool thai;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final scale = size.height / 300;
    Offset p(double x, double y) => Offset(centerX + (x * scale), y * scale);
    final bodyPaint = Paint()
      ..color = SooktaColors.darkGreen.withValues(alpha: 0.18)
      ..strokeWidth = 9 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final jointPaint = Paint()
      ..color = SooktaColors.darkGreen.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(p(0, 34), 21 * scale, jointPaint);
    canvas.drawLine(p(0, 58), p(0, 145), bodyPaint);
    canvas.drawLine(p(-55, 82), p(55, 82), bodyPaint);
    canvas.drawLine(p(-55, 82), p(-82, 142), bodyPaint);
    canvas.drawLine(p(55, 82), p(82, 142), bodyPaint);
    canvas.drawLine(p(-8, 145), p(-46, 238), bodyPaint);
    canvas.drawLine(p(8, 145), p(46, 238), bodyPaint);

    final markers = <BodyPart, Offset>{
      BodyPart.neck: p(0, 62),
      BodyPart.trunk: p(0, 124),
      BodyPart.arms: p(70, 104),
      BodyPart.wrists: p(84, 145),
      BodyPart.legs: p(38, 222),
    };
    final labelOffsets = <BodyPart, Offset>{
      BodyPart.neck: p(-128, 48),
      BodyPart.trunk: p(-128, 122),
      BodyPart.arms: p(78, 96),
      BodyPart.wrists: p(78, 144),
      BodyPart.legs: p(68, 226),
    };

    for (final entry in markers.entries) {
      final risk = bodyRisks[entry.key] ?? RiskLevel.low;
      final color = Color(risk.colorHex);
      final markerPaint = Paint()..color = color;
      canvas.drawCircle(entry.value, 11 * scale, markerPaint);
      canvas.drawCircle(
        entry.value,
        17 * scale,
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill,
      );
      _drawLabel(
        canvas,
        labelOffsets[entry.key]!,
        '${_partLabel(entry.key, thai)}\n${_riskText(risk, thai)}',
        color,
        scale,
      );
      canvas.drawLine(
        entry.value,
        labelOffsets[entry.key]! + Offset(0, 14 * scale),
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    Offset offset,
    String text,
    Color color,
    double scale,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12 * scale,
          height: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 86 * scale);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BodyRiskPainter oldDelegate) {
    return oldDelegate.bodyRisks != bodyRisks || oldDelegate.thai != thai;
  }
}

class _ImprovementAction {
  const _ImprovementAction({
    required this.scoreReduction,
    required this.bodyParts,
  });

  final int scoreReduction;
  final Set<BodyPart> bodyParts;

  String partLabels({required bool thai}) {
    return bodyParts.map((part) => _partLabel(part, thai)).join(', ');
  }
}

String _partLabel(BodyPart part, bool thai) {
  if (thai) {
    return switch (part) {
      BodyPart.neck => 'คอ',
      BodyPart.trunk => 'หลัง/ลำตัว',
      BodyPart.legs => 'ขา/เข่า',
      BodyPart.arms => 'ไหล่/แขน',
      BodyPart.wrists => 'ข้อมือ',
    };
  }
  return switch (part) {
    BodyPart.neck => 'Neck',
    BodyPart.trunk => 'Back/Trunk',
    BodyPart.legs => 'Legs/Knees',
    BodyPart.arms => 'Shoulders/Arms',
    BodyPart.wrists => 'Wrists',
  };
}

String _riskText(RiskLevel level, bool thai) {
  if (thai) {
    return switch (level) {
      RiskLevel.low => 'ต่ำ',
      RiskLevel.medium => 'ปานกลาง',
      RiskLevel.high => 'สูง',
      RiskLevel.veryHigh => 'สูงมาก',
    };
  }
  return switch (level) {
    RiskLevel.low => 'Low',
    RiskLevel.medium => 'Medium',
    RiskLevel.high => 'High',
    RiskLevel.veryHigh => 'Very high',
  };
}
