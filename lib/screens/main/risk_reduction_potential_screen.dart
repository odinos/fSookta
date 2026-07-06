import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/services/daily_injury_prediction_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';

class RiskReductionPotentialScreen extends StatelessWidget {
  const RiskReductionPotentialScreen({super.key});

  static const routeName = '/risk-reduction-potential';

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
          thai ? 'ศักยภาพการลดความเสี่ยง' : 'Risk Reduction Potential',
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
                        ? 'ยังโหลดข้อมูลศักยภาพการลดความเสี่ยงไม่ได้'
                        : 'Could not load risk reduction potential.',
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
                _PotentialCard(prediction: prediction, thai: thai),
                const SizedBox(height: 12),
                _PotentialNote(thai: thai),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PotentialCard extends StatelessWidget {
  const _PotentialCard({required this.prediction, required this.thai});

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      SooktaColors.leafGreen.withValues(alpha: 0.14),
                  child: const Icon(
                    Icons.trending_down,
                    color: SooktaColors.leafGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    thai
                        ? 'ศักยภาพการลดความเสี่ยง'
                        : 'Risk reduction potential',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MethodTrendChart(prediction: prediction, thai: thai),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'กราฟนี้แยก REBA และ ISO11228 เพราะเป็นการประเมินคนละบริบท ไม่ได้นำคะแนนมารวมกัน'
                  : 'This chart separates REBA and ISO11228 because they measure different contexts; the scores are not combined.',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.64),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              thai
                  ? 'คะแนนเฉลี่ยแยกตามวิธีประเมิน'
                  : 'Average score by assessment method',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            _MethodComparisonRow(
              title: 'REBA',
              before: prediction.averageRebaBeforeScore,
              after: prediction.averageRebaAfterScore,
              thai: thai,
            ),
            const SizedBox(height: 8),
            _MethodComparisonRow(
              title: 'ISO11228',
              before: prediction.averageIsoBeforeScore,
              after: prediction.averageIsoAfterScore,
              thai: thai,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodComparisonRow extends StatelessWidget {
  const _MethodComparisonRow({
    required this.title,
    required this.before,
    required this.after,
    required this.thai,
  });

  final String title;
  final double before;
  final double after;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final hasAfter = after > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _CompactScoreValue(
                  label: thai ? 'ก่อนประเมิน' : 'Before',
                  value: before <= 0 ? '-' : _score(before),
                  color: const Color(0xFFF44336),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.black45,
                  size: 22,
                ),
              ),
              Expanded(
                flex: 3,
                child: _CompactScoreValue(
                  label: thai ? 'หลังประเมิน' : 'After',
                  value: hasAfter ? _score(after) : '-',
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactScoreValue extends StatelessWidget {
  const _CompactScoreValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 66),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.64),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTrendChart extends StatelessWidget {
  const _MethodTrendChart({required this.prediction, required this.thai});

  final DailyInjuryPrediction prediction;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          thai
              ? 'แนวโน้มก่อนและหลังปรับปรุง'
              : 'Before/after improvement trend',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _RiskReductionTrendPainter(
              series: [
                _ScoreSeries(
                  values: prediction.chartRebaBeforeScores
                      .map<int?>((value) => value)
                      .toList(),
                  color: const Color(0xFFF44336),
                  dashed: false,
                ),
                _ScoreSeries(
                  values: prediction.chartRebaAfterScores
                      .map<int?>((value) => value)
                      .toList(),
                  color: const Color(0xFFFF9800),
                  dashed: true,
                ),
                _ScoreSeries(
                  values: prediction.chartIsoBeforeScores,
                  color: const Color(0xFF1976D2),
                  dashed: false,
                ),
                _ScoreSeries(
                  values: prediction.chartIsoAfterScores,
                  color: SooktaColors.leafGreen,
                  dashed: true,
                ),
              ],
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _ChartLegendItem(
              color: const Color(0xFFF44336),
              label: thai ? 'REBA ก่อน' : 'REBA before',
            ),
            _ChartLegendItem(
              color: const Color(0xFFFF9800),
              label: thai ? 'REBA หลัง' : 'REBA after',
              dashed: true,
            ),
            _ChartLegendItem(
              color: const Color(0xFF1976D2),
              label: thai ? 'ISO ก่อน' : 'ISO before',
            ),
            _ChartLegendItem(
              color: SooktaColors.leafGreen,
              label: thai ? 'ISO หลัง' : 'ISO after',
              dashed: true,
            ),
          ],
        ),
      ],
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
          size: const Size(24, 4),
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
    if (dashed) {
      canvas.drawLine(Offset.zero, Offset(size.width * 0.42, 0), paint);
      canvas.drawLine(
        Offset(size.width * 0.62, 0),
        Offset(size.width, 0),
        paint,
      );
    } else {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.dashed != dashed;
  }
}

class _ScoreSeries {
  const _ScoreSeries({
    required this.values,
    required this.color,
    required this.dashed,
  });

  final List<int?> values;
  final Color color;
  final bool dashed;
}

class _RiskReductionTrendPainter extends CustomPainter {
  const _RiskReductionTrendPainter({required this.series});

  final List<_ScoreSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    final plot = Rect.fromLTWH(28, 8, size.width - 38, size.height - 30);
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    final allValues = [
      for (final item in series) ...item.values.whereType<int>(),
    ];
    if (allValues.isEmpty) return;
    final maxScore = math.max(9, allValues.reduce(math.max));
    for (final item in series) {
      _drawSeries(canvas, plot, item, maxScore.toDouble());
    }
  }

  void _drawSeries(
    Canvas canvas,
    Rect plot,
    _ScoreSeries series,
    double maxScore,
  ) {
    final points = <Offset>[];
    for (var i = 0; i < series.values.length; i++) {
      final value = series.values[i];
      if (value == null || value <= 0) continue;
      final x = series.values.length == 1
          ? plot.left
          : plot.left + (plot.width * i / (series.values.length - 1));
      final y =
          plot.bottom - ((value.clamp(0, maxScore) / maxScore) * plot.height);
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = series.color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      for (var i = 0; i < points.length - 1; i++) {
        if (series.dashed) {
          _drawDashedLine(canvas, points[i], points[i + 1], linePaint);
        } else {
          canvas.drawLine(points[i], points[i + 1], linePaint);
        }
      }
    }

    final pointPaint = Paint()
      ..color = series.color
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 4.5, pointPaint);
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
  bool shouldRepaint(covariant _RiskReductionTrendPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

class _PotentialNote extends StatelessWidget {
  const _PotentialNote({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          thai
              ? 'หน้านี้เป็นการประเมินศักยภาพจากคะแนนก่อนและหลังเลือกคำแนะนำ ไม่ใช่แนวโน้มความเสี่ยงจริง และไม่ใช่การวินิจฉัยโรค'
              : 'This page estimates potential reduction from before/after advice scores. It is not the actual risk trend and not a medical diagnosis.',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      ),
    );
  }
}

String _score(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
  return value.toStringAsFixed(1);
}
