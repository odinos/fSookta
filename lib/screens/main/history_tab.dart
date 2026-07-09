import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/assessment_export_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import 'daily_prediction_screen.dart';
import 'history_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({
    required this.text,
    super.key,
  });

  final AppText text;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  _HistoryRiskFilter _riskFilter = _HistoryRiskFilter.all;
  String? _activityFilter;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = widget.text.isThai;
    final history = state.history;
    final filteredHistory = _filteredHistory(history);

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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filled(
                            tooltip: thai
                                ? 'แนวโน้ม 7 ครั้งล่าสุด'
                                : '7-record trend',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                            ),
                            onPressed: history.isEmpty
                                ? null
                                : () => Navigator.of(context).pushNamed(
                                      DailyPredictionScreen.routeName,
                                    ),
                            icon: const Icon(
                              Icons.monitor_heart_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: thai ? 'ส่งออกทั้งหมด' : 'Export all',
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                            ),
                            onPressed: history.isEmpty
                                ? null
                                : () => _exportAll(
                                      context: context,
                                      state: state,
                                      thai: thai,
                                    ),
                            icon: const Icon(Icons.download_outlined,
                                color: Colors.white),
                          ),
                        ],
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
                          Text(widget.text.noHistory,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ResponsiveListView(
                      maxWidth: 620,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _HistorySummaryAndFilters(
                          history: history,
                          filteredHistory: filteredHistory,
                          riskFilter: _riskFilter,
                          activityFilter: _activityFilter,
                          thai: thai,
                          onRiskFilterChanged: (filter) {
                            setState(() => _riskFilter = filter);
                          },
                          onActivityFilterChanged: (activityName) {
                            setState(() {
                              _activityFilter = _activityFilter == activityName
                                  ? null
                                  : activityName;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (filteredHistory.isEmpty)
                          _NoFilteredHistoryMessage(thai: thai)
                        else
                          for (final item in filteredHistory) ...[
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
                            if (item != filteredHistory.last)
                              const SizedBox(height: 10),
                          ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<EvaluationHistoryRecord> _filteredHistory(
    List<EvaluationHistoryRecord> history,
  ) {
    return history.where((record) {
      final matchesRisk = switch (_riskFilter) {
        _HistoryRiskFilter.all => true,
        _HistoryRiskFilter.highRisk => record.riskBefore >= RiskLevel.high,
      };
      final matchesActivity =
          _activityFilter == null || record.activityName == _activityFilter;
      return matchesRisk && matchesActivity;
    }).toList(growable: false);
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
        profile: state.profileForRecord(record),
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

  Future<void> _exportAll({
    required BuildContext context,
    required SooktaAppState state,
    required bool thai,
  }) async {
    try {
      final records = state.history;
      final file = await AssessmentExportService.exportAllHistoryCsv(
        records: records,
        profilesByRecordId: {
          for (final record in records)
            record.id: state.profileForRecord(record)
        },
        thai: thai,
      );
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: thai
              ? 'ไฟล์ประวัติผลประเมินทุกคน'
              : 'All farmer assessment export',
          subject: thai
              ? 'ไฟล์ประวัติผลประเมินทุกคน'
              : 'All farmer assessment export',
          text: thai
              ? 'ไฟล์ CSV รวมผลประเมินหลายคน สำหรับเจ้าหน้าที่วิจัย'
              : 'CSV with all farmer assessment records for research staff.',
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
                ? 'ยังส่งออกไฟล์รวมไม่ได้ กรุณาลองอีกครั้ง'
                : 'Could not export all records. Please try again.',
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

enum _HistoryRiskFilter {
  all,
  highRisk,
}

class _HistorySummaryAndFilters extends StatelessWidget {
  const _HistorySummaryAndFilters({
    required this.history,
    required this.filteredHistory,
    required this.riskFilter,
    required this.activityFilter,
    required this.thai,
    required this.onRiskFilterChanged,
    required this.onActivityFilterChanged,
  });

  final List<EvaluationHistoryRecord> history;
  final List<EvaluationHistoryRecord> filteredHistory;
  final _HistoryRiskFilter riskFilter;
  final String? activityFilter;
  final bool thai;
  final ValueChanged<_HistoryRiskFilter> onRiskFilterChanged;
  final ValueChanged<String> onActivityFilterChanged;

  @override
  Widget build(BuildContext context) {
    final beforeAverage = _averageScore(
      filteredHistory.map((record) => record.scoreBefore),
    );
    final afterAverage = _averageScore(
      filteredHistory.map((record) => record.scoreAfter),
    );
    final highRiskCount = filteredHistory
        .where((record) => record.riskBefore >= RiskLevel.high)
        .length;
    final activityNames = _activityNames(history);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_down, color: SooktaColors.darkGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai
                        ? 'สรุปประวัติและแนวโน้ม'
                        : 'History and Trend Summary',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _summaryLine(
                thai: thai,
                shown: filteredHistory.length,
                total: history.length,
                beforeAverage: beforeAverage,
                afterAverage: afterAverage,
                highRiskCount: highRiskCount,
              ),
              style: const TextStyle(color: Colors.black87, height: 1.35),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(thai ? 'ทั้งหมด' : 'All'),
                  selected: riskFilter == _HistoryRiskFilter.all,
                  onSelected: (_) =>
                      onRiskFilterChanged(_HistoryRiskFilter.all),
                ),
                ChoiceChip(
                  label: Text(thai ? 'เสี่ยงสูง' : 'High risk'),
                  selected: riskFilter == _HistoryRiskFilter.highRisk,
                  onSelected: (_) =>
                      onRiskFilterChanged(_HistoryRiskFilter.highRisk),
                ),
                for (final name in activityNames)
                  ChoiceChip(
                    label: Text(name),
                    selected: activityFilter == name,
                    onSelected: (_) => onActivityFilterChanged(name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static double _averageScore(Iterable<int> scores) {
    if (scores.isEmpty) return 0;
    final values = scores.toList(growable: false);
    return values.reduce((sum, score) => sum + score) / values.length;
  }

  static List<String> _activityNames(List<EvaluationHistoryRecord> history) {
    final names = <String>{};
    for (final record in history) {
      if (record.activityName.trim().isNotEmpty) {
        names.add(record.activityName.trim());
      }
    }
    return names.toList(growable: false)..sort();
  }

  static String _summaryLine({
    required bool thai,
    required int shown,
    required int total,
    required double beforeAverage,
    required double afterAverage,
    required int highRiskCount,
  }) {
    final countText = shown == total
        ? (thai ? 'ทั้งหมด $total ครั้ง' : 'All $total records')
        : (thai
            ? 'แสดง $shown จาก $total ครั้ง'
            : 'Showing $shown of $total records');
    if (thai) {
      return '$countText • คะแนนก่อนเฉลี่ย ${beforeAverage.toStringAsFixed(1)} • '
          'คะแนนหลังเฉลี่ย ${afterAverage.toStringAsFixed(1)} • '
          'ความเสี่ยงสูง $highRiskCount ครั้ง';
    }
    return '$countText • Avg before ${beforeAverage.toStringAsFixed(1)} • '
        'Avg after ${afterAverage.toStringAsFixed(1)} • '
        'High risk $highRiskCount records';
  }
}

class _NoFilteredHistoryMessage extends StatelessWidget {
  const _NoFilteredHistoryMessage({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          thai
              ? 'ไม่พบประวัติตามตัวกรองนี้'
              : 'No history matches this filter.',
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
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
          [
            if ((record.farmerName ?? '').isNotEmpty) record.farmerName!,
            record.activityName,
          ].join(' • '),
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
