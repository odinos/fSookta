import 'package:flutter/material.dart';

import '../core/theme/sookta_theme.dart';

class ResearchDisclaimerCard extends StatelessWidget {
  const ResearchDisclaimerCard({
    required this.thai,
    this.compact = false,
    super.key,
  });

  final bool thai;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFBEE),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline,
              color: SooktaColors.darkGreen,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thai
                    ? 'ผลประเมินนี้ใช้เพื่อสื่อสารความเสี่ยงด้านท่าทาง การเรียนรู้ และงานวิจัยเท่านั้น ไม่ใช่การวินิจฉัยทางการแพทย์ การยืนยันการบาดเจ็บ หรือการคำนวณค่าใช้จ่ายจริงเฉพาะบุคคล'
                    : 'This result supports ergonomic risk communication, learning, and research only. It is not a medical diagnosis, confirmed injury prediction, or exact personal cost calculation.',
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.68),
                  fontSize: compact ? 11.5 : 12.5,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
