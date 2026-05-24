import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import '../../core/services/assessment_export_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import 'history_detail_screen.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({
    required this.text,
    super.key,
  });

  final AppText text;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = text.isThai;
    final history = state.history;

    return Container(
      color: const Color(0xFFFDF8E1),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              decoration: const BoxDecoration(
                color: SooktaColors.leafGreen,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thai ? 'ผลตรวจย้อนหลัง' : 'Assessment History',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              thai
                                  ? 'ประวัติการประเมินความเสี่ยงของคุณ'
                                  : 'Your risk assessment records',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(text.noHistory,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ResponsiveListView(
                      maxWidth: 620,
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final item in history) ...[
                          _HistoryCard(
                            record: item,
                            thai: thai,
                            onTap: () => Navigator.of(context).pushNamed(
                              HistoryDetailScreen.routeName,
                              arguments: item.id,
                            ),
                            onExport: (buttonContext) => _exportRecord(
                              context: buttonContext,
                              state: state,
                              record: item,
                              thai: thai,
                            ),
                          ),
                          if (item != history.last) const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportRecord({
    required BuildContext context,
    required SooktaAppState state,
    required EvaluationHistoryRecord record,
    required bool thai,
  }) async {
    try {
      final file = await AssessmentExportService.exportHistoryRecordCsv(
        record: record,
        profile: state.profile,
        thai: thai,
      );
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: thai ? 'ไฟล์ประวัติผลประเมินสุขท่า' : 'Sookta history export',
          subject:
              thai ? 'ไฟล์ประวัติผลประเมินสุขท่า' : 'Sookta history export',
          text: thai
              ? 'ไฟล์ CSV นี้เปิดด้วย Excel ได้ สำหรับเจ้าหน้าที่ใช้ติดตามผลประเมินย้อนหลัง'
              : 'This CSV opens in Excel for staff history review.',
          files: [XFile(file.path, mimeType: 'text/csv')],
          fileNameOverrides: [file.uri.pathSegments.last],
          sharePositionOrigin: _shareOrigin(context),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังส่งออกไฟล์ประวัติไม่ได้ กรุณาลองอีกครั้ง'
                : 'Could not export history. Please try again.',
          ),
        ),
      );
    }
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.thai,
    required this.onTap,
    required this.onExport,
  });

  final EvaluationHistoryRecord record;
  final bool thai;
  final VoidCallback onTap;
  final ValueChanged<BuildContext> onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Color(record.riskBefore.colorHex),
          child: Text(
            '${record.scoreBefore}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          record.activityName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          thai
              ? 'ก่อน ${record.scoreBefore} → หลัง ${record.scoreAfter} | อาจลดลง ${record.moneySaved} บาท/ปี'
              : 'Before ${record.scoreBefore} → After ${record.scoreAfter} | Potentially reduced ${record.moneySaved} THB/year',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (buttonContext) => IconButton(
                tooltip: thai ? 'ส่งออก Excel' : 'Export Excel',
                onPressed: () => onExport(buttonContext),
                icon: const Icon(Icons.download_outlined),
              ),
            ),
            const Icon(Icons.navigate_next),
          ],
        ),
      ),
    );
  }
}
