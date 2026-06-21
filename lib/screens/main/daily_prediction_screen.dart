import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/services/daily_injury_prediction_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';

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
          thai ? 'ทำนายจากประวัติ 7 รายการ' : '7-Transaction Prediction',
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
                        ? 'ยังโหลดโมเดลทำนายไม่ได้'
                        : 'Could not load prediction model.',
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
                _SummaryCard(
                  prediction: prediction,
                  thai: thai,
                  farmerName: state.profile.name,
                ),
                const SizedBox(height: 12),
                if (prediction.chartScores.isNotEmpty)
                  _TrendCard(prediction: prediction, thai: thai),
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
    final percent = (prediction.probability * 100).round();
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
                    ? 'ต้องมีผลประเมินครบ ${prediction.requiredTransactions} transaction ก่อน ระบบจึงจะทำนายแนวโน้มได้'
                    : 'At least ${prediction.requiredTransactions} assessment transactions are required before prediction.',
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
                    ? 'ความน่าจะเป็นที่ควรติดตามอาการ/ข้อมูลการรักษา: $percent%'
                    : 'Symptom/treatment follow-up probability: $percent%',
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
            ],
          ],
        ),
      ),
    );
  }

  String get _title =>
      thai ? 'ผลทำนายประวัติรายวัน' : 'Daily History Prediction';

  String get _message {
    return switch (prediction.level) {
      DailyInjuryPredictionLevel.critical => thai
          ? 'ควรให้เจ้าหน้าที่ติดตามทันที และสอบถามอาการปวด/การรักษาเพิ่มเติม'
          : 'Immediate staff follow-up is recommended. Ask about pain symptoms and treatment.',
      DailyInjuryPredictionLevel.high => thai
          ? 'ควรติดตามอาการและพิจารณาส่งต่อเพื่อประเมินเพิ่มเติม'
          : 'Follow up and consider referral for further assessment.',
      DailyInjuryPredictionLevel.watch => thai
          ? 'ควรเฝ้าดูแนวโน้มคะแนนและทบทวนคำแนะนำที่ทำได้จริง'
          : 'Watch the trend and review practical recommendations.',
      DailyInjuryPredictionLevel.low => thai
          ? 'ยังไม่พบแนวโน้มที่ต้องแจ้งเตือนจาก 7 transaction ล่าสุด'
          : 'No alert-level trend was detected in the latest 7 transactions.',
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
                  ? 'กราฟคะแนนก่อนปรับ 7 transaction ล่าสุด'
                  : 'Latest 7 Before Scores',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _ScoreTrendPainter(prediction.chartScores),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'คะแนนสูงหรือต่อเนื่องหลายวันจะเพิ่มโอกาสการแจ้งเตือน'
                  : 'High or persistent scores increase the alert probability.',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.62)),
            ),
          ],
        ),
      ),
    );
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
    final features = prediction.featureValues;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thai
                  ? 'ข้อมูลที่ส่งเข้า Logistic Regression'
                  : 'Inputs Sent to Logistic Regression',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'ระบบแยกคะแนนท่าทาง REBA และภาระงาน ISO11228 ก่อนนำ 7 transaction ล่าสุดไปทำนายแนวโน้ม'
                  : 'The app separates REBA posture scores from ISO11228 manual-handling exposure before predicting from the latest 7 transactions.',
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
                  label: thai ? 'REBA เฉลี่ย' : 'Avg REBA',
                  value: _pct(features['avg_reba_score_before_norm']),
                ),
                _FeatureChip(
                  label: thai ? 'ISO เฉลี่ย' : 'Avg ISO',
                  value: _pct(features['avg_iso_score_before_norm']),
                ),
                _FeatureChip(
                  label: thai ? 'น้ำหนัก/แรง' : 'Load/force',
                  value: _pct(features['load_weight_norm']),
                ),
                _FeatureChip(
                  label: thai ? 'ความถี่การยก' : 'Lift frequency',
                  value: _pct(features['frequency_of_lifting_norm']),
                ),
                _FeatureChip(
                  label: thai ? 'แนวโน้ม REBA' : 'REBA slope',
                  value: _pct(features['recent_reba_score_slope_norm']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _pct(double? value) => '${((value ?? 0) * 100).round()}%';
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
              ? 'หมายเหตุ: หน้านี้ใช้ Logistic Regression แยกจากการคำนวณ REBA/ISO โดยอ่าน REBA และ ISO11228 เป็นคนละมิติจาก 7 transaction ล่าสุด ใช้เพื่อสื่อสารความเสี่ยงและติดตามงานวิจัย ไม่ใช่การวินิจฉัยโรค ไม่ใช่การยืนยันว่าบาดเจ็บหรือต้องรักษา และควรปรับ coefficients เมื่อทีมวิจัยให้ label อาการ MSD จริง'
              : 'Note: This screen uses Logistic Regression separately from REBA/ISO scoring. It reads REBA and ISO11228 as separate dimensions from the latest 7 transactions for risk communication and research follow-up. It is not a medical diagnosis or confirmation of injury/treatment. Coefficients should be retrained once real MSD symptom labels are supplied.',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
      ),
    );
  }
}

class _ScoreTrendPainter extends CustomPainter {
  _ScoreTrendPainter(this.scores);

  final List<int> scores;

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = SooktaColors.leafGreen
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()
      ..color = SooktaColors.leafGreen
      ..style = PaintingStyle.fill;

    final plot = Rect.fromLTWH(28, 8, size.width - 36, size.height - 30);
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    if (scores.isEmpty) return;
    final points = <Offset>[];
    for (var i = 0; i < scores.length; i++) {
      final x = scores.length == 1
          ? plot.left
          : plot.left + (plot.width * i / (scores.length - 1));
      final y = plot.bottom - ((scores[i].clamp(1, 9) - 1) / 8 * plot.height);
      points.add(Offset(x, y));
    }
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreTrendPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}
