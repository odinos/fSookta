import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/daily_injury_prediction_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import 'risk_reduction_potential_screen.dart';

class DailyPredictionScreen extends StatelessWidget {
  const DailyPredictionScreen({super.key});

  static const routeName = '/daily-prediction';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final profileId = state.profile.profileId;
    final records =
        profileId.isEmpty ? state.history : state.historyForFarmer(profileId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          thai
              ? 'แนวโน้มความเสี่ยงจาก 7 ครั้งล่าสุด'
              : 'Risk Trend From Latest 7 Records',
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<DailyInjuryPredictionService>(
          future: DailyInjuryPredictionService.load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    thai
                        ? 'ยังโหลดข้อมูลแนวโน้มไม่ได้'
                        : 'Could not load trend data.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final prediction = snapshot.data!.predictForRecords(records);
            return ResponsiveListView(
              maxWidth: 680,
              padding: const EdgeInsets.all(16),
              children: [
                if (prediction.chartScores.isNotEmpty)
                  _TrendCard(prediction: prediction, thai: thai),
                if (prediction.chartScores.isNotEmpty)
                  const SizedBox(height: 12),
                _SummaryCard(
                  prediction: prediction,
                  thai: thai,
                  farmerName: state.profile.name,
                ),
                const SizedBox(height: 12),
                if (prediction.chartScores.isNotEmpty)
                  _ImprovementLinkCard(thai: thai),
                if (prediction.chartScores.isNotEmpty)
                  const SizedBox(height: 12),
                if (prediction.hasEnoughData)
                  _FeatureSnapshotCard(prediction: prediction, thai: thai),
                if (prediction.hasEnoughData) const SizedBox(height: 12),
                _ModelNote(prediction: prediction, thai: thai),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.prediction,
    required this.thai,
    required this.farmerName,
  });

  final DailyInjuryPrediction prediction;
  final bool thai;
  final String farmerName;

  @override
  Widget build(BuildContext context) {
    final color = _color(prediction.level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(Icons.monitor_heart_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        farmerName.isEmpty
                            ? (thai ? 'ชาวสวนที่เลือกอยู่' : 'Current farmer')
                            : farmerName,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!prediction.hasEnoughData) ...[
              Text(
                thai
                    ? 'ต้องมีผลประเมินครบ ${prediction.requiredTransactions} ครั้งก่อน จึงจะดูแนวโน้มได้'
                    : 'At least ${prediction.requiredTransactions} completed assessments are required before showing the trend.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                thai
                    ? 'ตอนนี้มี ${prediction.usedTransactions}/${prediction.requiredTransactions} รายการ'
                    : 'Current records: ${prediction.usedTransactions}/${prediction.requiredTransactions}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ] else ...[
              Text(
                thai
                    ? 'แนวโน้มความเสี่ยง: $_levelLabel'
                    : 'Risk trend: $_levelLabel',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                style: const TextStyle(fontSize: 16, height: 1.35),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    label: thai ? 'REBA ล่าสุด' : 'Latest REBA',
                    value: '${prediction.latestScore}',
                  ),
                  _MetricChip(
                    label: thai
                        ? 'REBA เฉลี่ย 7 ครั้งล่าสุด'
                        : 'Latest 7 REBA average',
                    value: prediction.averageScore.toStringAsFixed(1),
                  ),
                  _MetricChip(
                    label: thai ? 'REBA สูงสุด' : 'Highest REBA',
                    value: '${prediction.maximumScore}',
                  ),
                  _MetricChip(
                    label: thai ? 'ยังเสี่ยงสูง' : 'High-risk records',
                    value:
                        '${prediction.highRiskCount}/${prediction.usedTransactions}',
                  ),
                  _MetricChip(
                    label: thai ? 'ทิศทาง' : 'Direction',
                    value: _directionLabel,
                  ),
                  _MetricChip(
                    label: 'ISO11228',
                    value: _isoLabel,
                  ),
                  _MetricChip(
                    label: thai ? 'น้ำหนักเฉลี่ย' : 'Average load',
                    value: prediction.averageLoadKg <= 0
                        ? '-'
                        : thai
                            ? '${prediction.averageLoadKg.toStringAsFixed(1)} กก.'
                            : '${prediction.averageLoadKg.toStringAsFixed(1)} kg',
                  ),
                  _MetricChip(
                    label: thai ? 'ความถี่เฉลี่ย' : 'Average frequency',
                    value: prediction.averageLiftFrequencyPerHour <= 0
                        ? '-'
                        : thai
                            ? '${prediction.averageLiftFrequencyPerHour.toStringAsFixed(0)} ครั้ง/ชั่วโมง'
                            : '${prediction.averageLiftFrequencyPerHour.toStringAsFixed(0)} times/hour',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _title =>
      thai ? 'สรุปแนวโน้มความเสี่ยงจริง' : 'Actual Risk Trend Summary';

  String get _levelLabel {
    return switch (prediction.level) {
      DailyInjuryPredictionLevel.critical => thai ? 'สูงมาก' : 'Very high',
      DailyInjuryPredictionLevel.high => thai ? 'สูง' : 'High',
      DailyInjuryPredictionLevel.watch => thai ? 'เฝ้าระวัง' : 'Watch',
      DailyInjuryPredictionLevel.low => thai ? 'ต่ำ' : 'Low',
      DailyInjuryPredictionLevel.insufficient =>
        thai ? 'ยังไม่พอ' : 'Not enough',
    };
  }

  String get _directionLabel {
    return switch (prediction.trendDirection) {
      TrendDirection.decreasing => thai ? 'ลดลง' : 'Decreasing',
      TrendDirection.stable => thai ? 'ทรงตัว' : 'Stable',
      TrendDirection.increasing => thai ? 'เพิ่มขึ้น' : 'Increasing',
    };
  }

  String get _isoLabel {
    final risk = prediction.latestIsoRiskLevel;
    if (risk == null) return '-';
    final score = prediction.latestIsoScore;
    final label = _riskLabel(risk);
    return score == null ? label : '$label ($score)';
  }

  String _riskLabel(RiskLevel risk) => _riskText(risk, thai);

  String get _message {
    return switch (prediction.level) {
      DailyInjuryPredictionLevel.critical => thai
          ? 'จาก 7 ครั้งล่าสุด ก่อนเลือกแนวทางปรับปรุงยังพบความเสี่ยงสูงหลายครั้ง ควรให้เจ้าหน้าที่ช่วยดูงานจริงและปรับวิธีทำงานทันที'
          : 'Across the latest 7 records, actual pre-improvement risk remains high many times. Staff should review the real task and improve the workflow promptly.',
      DailyInjuryPredictionLevel.high => thai
          ? 'ยังพบความเสี่ยงสูงหลายครั้งจากท่าทางงานจริง ควรทบทวนวิธีทำงานและเลือกแนวทางลดความเสี่ยงที่ทำได้จริง'
          : 'High risk appears in several actual work records. Review the workflow and choose practical risk-reduction actions.',
      DailyInjuryPredictionLevel.watch => thai
          ? 'มีบางครั้งที่งานจริงยังเสี่ยงสูง ควรเฝ้าดูต่อและเลือกวิธีลดความเสี่ยงที่ทำได้จริง'
          : 'Some actual work records remain high risk. Keep monitoring and choose practical risk-reduction actions.',
      DailyInjuryPredictionLevel.low => thai
          ? 'ส่วนใหญ่ของงานจริงอยู่ในระดับต่ำหรือปานกลาง ให้บันทึกต่อเนื่องและทบทวนทันทีหากงานเปลี่ยน'
          : 'Most actual work records are low or medium risk. Keep recording consistently and review again if the task changes.',
      DailyInjuryPredictionLevel.insufficient => '',
    };
  }

  Color _color(DailyInjuryPredictionLevel level) {
    return switch (level) {
      DailyInjuryPredictionLevel.critical => const Color(0xFFB71C1C),
      DailyInjuryPredictionLevel.high => const Color(0xFFF44336),
      DailyInjuryPredictionLevel.watch => const Color(0xFFFF9800),
      DailyInjuryPredictionLevel.low => SooktaColors.leafGreen,
      DailyInjuryPredictionLevel.insufficient => Colors.grey,
    };
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.prediction, required this.thai});

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thai
                  ? 'แนวโน้มก่อนและหลังปรับปรุงจาก 7 ครั้งล่าสุด'
                  : 'Before/after trend from latest 7 records',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _ScoreTrendPainter(
                  series: [
                    _ScoreSeries(
                      scores: prediction.chartRebaBeforeScores,
                      color: const Color(0xFFF44336),
                    ),
                    _ScoreSeries(
                      scores: prediction.chartRebaAfterScores,
                      color: const Color(0xFFFF9800),
                      dashed: true,
                    ),
                    _ScoreSeries(
                      scores: prediction.chartIsoBeforeScores,
                      color: const Color(0xFF1976D2),
                    ),
                    _ScoreSeries(
                      scores: prediction.chartIsoAfterScores,
                      color: SooktaColors.leafGreen,
                      dashed: true,
                    ),
                  ],
                ),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _ChartLegendItem(
                  color: const Color(0xFFF44336),
                  label: thai ? 'REBA ก่อนปรับปรุง' : 'Before-improvement REBA',
                ),
                _ChartLegendItem(
                  color: const Color(0xFFFF9800),
                  label: thai ? 'REBA หลังปรับปรุง' : 'After-improvement REBA',
                  dashed: true,
                ),
                _ChartLegendItem(
                  color: const Color(0xFF1976D2),
                  label: thai
                      ? 'ISO11228 ก่อนปรับปรุง'
                      : 'Before-improvement ISO11228',
                ),
                _ChartLegendItem(
                  color: SooktaColors.leafGreen,
                  label: thai
                      ? 'ISO11228 หลังปรับปรุง'
                      : 'After-improvement ISO11228',
                  dashed: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'ระดับแนวโน้มด้านล่างคำนวณจากคะแนนก่อนปรับปรุงเท่านั้น ส่วนเส้นหลังปรับปรุงใช้เพื่อเทียบให้เห็นศักยภาพการลดความเสี่ยง'
                  : 'The trend level below is calculated from before-improvement scores only; after-improvement lines are shown for risk-reduction comparison.',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.62)),
            ),
            const SizedBox(height: 14),
            _TrendScoreTable(prediction: prediction, thai: thai),
          ],
        ),
      ),
    );
  }
}

class _TrendScoreTable extends StatelessWidget {
  const _TrendScoreTable({required this.prediction, required this.thai});

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final rowCount = prediction.chartScores.length;
    if (rowCount == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          thai
              ? 'คะแนนก่อน/หลังปรับปรุง 7 ครั้งล่าสุด'
              : 'Latest 7 before/after improvement scores',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            children: [
              _CompareTableRow(
                cells: [
                  thai ? 'ครั้งที่' : 'No.',
                  thai ? 'REBA ก่อน' : 'REBA before',
                  thai ? 'REBA หลัง' : 'REBA after',
                  thai ? 'ISO ก่อน' : 'ISO before',
                  thai ? 'ISO หลัง' : 'ISO after',
                ],
                header: true,
              ),
              for (var index = 0; index < rowCount; index++)
                _CompareTableRow(
                  cells: [
                    '${index + 1}',
                    '${prediction.chartScores[index]}',
                    _rebaAfterScoreAt(index),
                    _isoScoreAt(index),
                    _isoAfterScoreAt(index),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _isoScoreAt(int index) {
    if (index >= prediction.chartIsoBeforeScores.length) return '-';
    return prediction.chartIsoBeforeScores[index]?.toString() ?? '-';
  }

  String _rebaAfterScoreAt(int index) {
    if (index >= prediction.chartRebaAfterScores.length) return '-';
    return prediction.chartRebaAfterScores[index].toString();
  }

  String _isoAfterScoreAt(int index) {
    if (index >= prediction.chartIsoAfterScores.length) return '-';
    return prediction.chartIsoAfterScores[index]?.toString() ?? '-';
  }
}

class _ImprovementLinkCard extends StatelessWidget {
  const _ImprovementLinkCard({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pushNamed(
        RiskReductionPotentialScreen.routeName,
      ),
      icon: const Icon(Icons.trending_down),
      label: Text(
        thai ? 'ดูศักยภาพการลดความเสี่ยง' : 'View risk reduction potential',
      ),
    );
  }
}

class _CompareTableRow extends StatelessWidget {
  const _CompareTableRow({
    required this.cells,
    this.header = false,
  });

  final List<String> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: header ? FontWeight.w800 : FontWeight.w600,
      color: header ? Colors.black87 : Colors.black.withValues(alpha: 0.72),
      fontSize: 13,
    );
    return Container(
      color: header
          ? SooktaColors.leafGreen.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Text(
                cell,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 4),
          painter: _LegendLinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.68),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    if (!dashed) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
      return;
    }
    canvas.drawLine(Offset.zero, Offset(size.width * 0.42, 0), paint);
    canvas.drawLine(
      Offset(size.width * 0.62, 0),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.dashed != dashed;
  }
}

class _FeatureSnapshotCard extends StatelessWidget {
  const _FeatureSnapshotCard({
    required this.prediction,
    required this.thai,
  });

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thai
                  ? 'ค่าจริงที่ใช้ดูแนวโน้ม'
                  : 'Actual values used for the trend',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'ระบบใช้ผลก่อนปรับปรุงเป็นฐานคำนวณระดับแนวโน้มจาก 7 ครั้งล่าสุด ผลหลังปรับปรุงถูกใช้เพื่อเปรียบเทียบศักยภาพการลดความเสี่ยงและเป็นข้อมูลประกอบเท่านั้น ยังไม่ใช่ผลทำนายจากข้อมูลอาการหรือการรักษาจริง'
                  : 'The app uses before-improvement results from the latest 7 records as the basis for the trend level. After-improvement results are used for risk-reduction comparison and supporting features only. This is not yet a prediction from real symptom or treatment outcomes.',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.64),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  label: thai ? 'REBA เฉลี่ย' : 'Average REBA',
                  value: prediction.averageScore.toStringAsFixed(1),
                ),
                _FeatureChip(
                  label: thai ? 'REBA สูงสุด' : 'Highest REBA',
                  value: '${prediction.maximumScore}',
                ),
                _FeatureChip(
                  label: thai ? 'ยังเสี่ยงสูง' : 'High-risk records',
                  value:
                      '${prediction.highRiskCount}/${prediction.usedTransactions}',
                ),
                _FeatureChip(
                  label: thai ? 'น้ำหนัก/แรงเฉลี่ย' : 'Average load/force',
                  value: prediction.averageLoadKg <= 0
                      ? '-'
                      : thai
                          ? '${prediction.averageLoadKg.toStringAsFixed(1)} กก.'
                          : '${prediction.averageLoadKg.toStringAsFixed(1)} kg',
                ),
                _FeatureChip(
                  label: thai ? 'ความถี่ยกเฉลี่ย' : 'Lift frequency',
                  value: prediction.averageLiftFrequencyPerHour <= 0
                      ? '-'
                      : thai
                          ? '${prediction.averageLiftFrequencyPerHour.toStringAsFixed(0)} ครั้ง/ชม.'
                          : '${prediction.averageLiftFrequencyPerHour.toStringAsFixed(0)} times/hr',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _riskText(RiskLevel risk, bool thai) {
  if (thai) return risk.label;
  return switch (risk) {
    RiskLevel.low => 'Low',
    RiskLevel.medium => 'Medium',
    RiskLevel.high => 'High',
    RiskLevel.veryHigh => 'Very high',
  };
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: SooktaColors.leafGreen.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(color: Colors.black54),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: SooktaColors.leafGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ModelNote extends StatelessWidget {
  const _ModelNote({required this.prediction, required this.thai});

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          thai
              ? 'หมายเหตุ: หน้านี้ใช้เพื่อดูแนวโน้มความเสี่ยงจากผลประเมินที่บันทึกในแอปเท่านั้น ไม่ใช่การวินิจฉัยโรค และไม่สามารถยืนยันว่าบาดเจ็บหรือต้องรักษาได้ หากมีอาการผิดปกติควรปรึกษาเจ้าหน้าที่สาธารณสุขหรือบุคลากรทางการแพทย์'
              : 'Note: This screen communicates risk trends from app records only. It is not a medical diagnosis and does not confirm injury or treatment need. Seek medical or occupational-health advice for unusual symptoms.',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      ),
    );
  }
}

class _ScoreSeries {
  const _ScoreSeries({
    required this.scores,
    required this.color,
    this.dashed = false,
  });

  final List<int?> scores;
  final Color color;
  final bool dashed;
}

class _ScoreTrendPainter extends CustomPainter {
  _ScoreTrendPainter({required this.series});

  final List<_ScoreSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    final plot = Rect.fromLTWH(28, 8, size.width - 36, size.height - 30);
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    final allScores = [
      for (final item in series) ...item.scores.whereType<int>(),
    ];
    if (allScores.isEmpty) return;
    final maxScore = math.max(9, allScores.reduce(math.max));
    for (final item in series) {
      _drawSeries(canvas: canvas, plot: plot, series: item, maxScore: maxScore);
    }
  }

  void _drawSeries({
    required Canvas canvas,
    required Rect plot,
    required _ScoreSeries series,
    required int maxScore,
  }) {
    final scores = series.scores;
    if (scores.isEmpty) return;
    final linePaint = Paint()
      ..color = series.color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()
      ..color = series.color
      ..style = PaintingStyle.fill;
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = scores.length == 1
          ? plot.left
          : plot.left + (plot.width * i / (scores.length - 1));
      final score = scores[i];
      if (score == null) continue;
      final y = plot.bottom -
          ((score.clamp(1, maxScore) - 1) / (maxScore - 1) * plot.height);
      points.add(Offset(x, y));
    }
    if (points.length > 1) {
      for (var i = 0; i < points.length - 1; i++) {
        if (series.dashed) {
          _drawDashedLine(canvas, points[i], points[i + 1], linePaint);
        } else {
          canvas.drawLine(points[i], points[i + 1], linePaint);
        }
      }
    }
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final total = (end - start).distance;
    if (total <= 0) return;
    const dash = 8.0;
    const gap = 6.0;
    final direction = (end - start) / total;
    var distance = 0.0;
    while (distance < total) {
      final segmentStart = start + direction * distance;
      final segmentEnd = start + direction * math.min(distance + dash, total);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreTrendPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}
