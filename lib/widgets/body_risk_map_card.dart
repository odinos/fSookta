import 'package:flutter/material.dart';

import '../core/models/evaluation_models.dart';
import '../core/theme/sookta_theme.dart';

class BodyRiskMapCard extends StatelessWidget {
  const BodyRiskMapCard({
    required this.bodyRisks,
    required this.thai,
    this.title,
    super.key,
  });

  final Map<BodyPart, RiskLevel> bodyRisks;
  final bool thai;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final riskyParts = BodyPart.values
        .where((part) => (bodyRisks[part] ?? RiskLevel.low) != RiskLevel.low)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title ??
                  (thai
                      ? 'ตำแหน่งที่เสี่ยงบนร่างกาย'
                      : 'Risk points on body map'),
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final height =
                    (constraints.maxWidth * 0.78).clamp(230.0, 320.0);
                return SizedBox(
                  height: height,
                  child: CustomPaint(
                    painter: BodyRiskPainter(
                      bodyRisks: bodyRisks,
                      thai: thai,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            if (riskyParts.isEmpty)
              Text(
                thai ? 'ไม่พบตำแหน่งเสี่ยง' : 'No risky body parts found',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              )
            else
              ...riskyParts.map(
                (part) {
                  final risk = bodyRisks[part] ?? RiskLevel.low;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 6,
                          backgroundColor: Color(risk.colorHex),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${bodyPartLabel(part, thai)}: '
                            '${riskLevelText(risk, thai)}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class BodyRiskPainter extends CustomPainter {
  const BodyRiskPainter({
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
      canvas.drawCircle(
        entry.value,
        17 * scale,
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(entry.value, 11 * scale, markerPaint);
      canvas.drawLine(
        entry.value,
        labelOffsets[entry.key]! + Offset(0, 14 * scale),
        Paint()
          ..color = color.withValues(alpha: 0.55)
          ..strokeWidth = 1,
      );
      _drawLabel(
        canvas,
        labelOffsets[entry.key]!,
        '${bodyPartLabel(entry.key, thai)}\n${riskLevelText(risk, thai)}',
        color,
        scale,
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
  bool shouldRepaint(covariant BodyRiskPainter oldDelegate) {
    return oldDelegate.bodyRisks != bodyRisks || oldDelegate.thai != thai;
  }
}

String bodyPartLabel(BodyPart part, bool thai) {
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

String riskLevelText(RiskLevel level, bool thai) {
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
