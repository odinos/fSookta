import 'package:flutter/material.dart';

import '../core/models/economic_impact_models.dart';
import '../core/theme/sookta_theme.dart';
import 'responsive_content.dart';

class EconomicImpactComparisonCard extends StatelessWidget {
  const EconomicImpactComparisonCard({
    required this.comparison,
    required this.thai,
    this.title,
    this.compact = false,
    this.showFormula = true,
    super.key,
  });

  final EconomicImpactComparison comparison;
  final bool thai;
  final String? title;
  final bool compact;
  final bool showFormula;

  @override
  Widget build(BuildContext context) {
    final hasSaving = comparison.savedAmount > 0;
    final titleText = title ??
        (thai ? 'เปรียบเทียบรายได้ที่สูญเสีย' : 'Lost Income Comparison');

    return Card(
      color: const Color(0xFFF4FBF5),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  color: SooktaColors.darkGreen,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: TextStyle(
                          color: SooktaColors.darkGreen,
                          fontSize: compact ? 15 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thai
                            ? 'เห็นผลกระทบก่อนและหลังทำตามคำแนะนำได้ทันที'
                            : 'Shows the estimated impact before and after the selected advice.',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.62),
                          fontSize: compact ? 11.5 : 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 430;
                final items = [
                  _ImpactMetric(
                    label: thai ? 'ก่อนปรับ' : 'Before',
                    value: comparison.beforeImpact,
                    color: Colors.deepOrange,
                    icon: Icons.warning_amber_rounded,
                    thai: thai,
                  ),
                  _ImpactMetric(
                    label: thai ? 'หลังปรับ' : 'After',
                    value: comparison.afterImpact,
                    color: SooktaColors.leafGreen,
                    icon: Icons.check_circle_outline,
                    thai: thai,
                  ),
                  _ImpactMetric(
                    label: thai ? 'ลดการสูญเสียได้' : 'Potential saving',
                    value: comparison.savedAmount,
                    color: hasSaving
                        ? SooktaColors.darkGreen
                        : Colors.grey.shade700,
                    icon: Icons.trending_down,
                    emphasized: true,
                    thai: thai,
                  ),
                ];

                if (stacked) {
                  return Column(
                    children: [
                      for (final item in items) ...[
                        item,
                        if (item != items.last) const SizedBox(height: 8),
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 8),
                    Expanded(child: items[1]),
                    const SizedBox(width: 8),
                    Expanded(child: items[2]),
                  ],
                );
              },
            ),
            if (showFormula) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SooktaColors.darkGreen.withValues(alpha: 0.14),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Text(
                  hasSaving
                      ? (thai
                          ? 'สูตร: ผลกระทบหลังปรับ = ผลกระทบก่อนปรับ × (1 - ${comparison.effectiveScoreReduction} จุด × 28%)'
                          : 'Formula: after impact = before impact x (1 - ${comparison.effectiveScoreReduction} score point(s) x 28%)')
                      : (thai
                          ? 'ยังไม่มีคะแนนลดลงจากคำแนะนำที่เลือก จึงยังไม่พบมูลค่าที่ลดการสูญเสียได้'
                          : 'No score reduction yet, so no estimated saving is shown.'),
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.72),
                    fontSize: compact ? 11.5 : 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                thai
                    ? 'ตัวเลขนี้ใช้เพื่อสื่อสารผลกระทบโดยประมาณ ไม่ใช่ค่ารักษาหรือรายได้จริงเฉพาะบุคคล'
                    : 'This is an approximate risk-communication estimate, not exact personal medical cost or income loss.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.55),
                  fontSize: compact ? 10.8 : 11.2,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.thai,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool thai;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 98),
      decoration: BoxDecoration(
        color: emphasized
            ? color.withValues(alpha: 0.11)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FixedTextScale(
            child: Text(
              _money(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: emphasized ? 22 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            thai ? 'บาท/ปี' : 'THB/year',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.58),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _money(int value) {
    final text = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i += 1) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }
}
