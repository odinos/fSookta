import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/assessment_export_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/body_risk_map_card.dart';
import '../../widgets/research_disclaimer_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    required this.historyId,
    super.key,
  });

  static const routeName = '/history-detail';

  final int historyId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final record = state.historyById(historyId);

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'รายละเอียดผลตรวจ' : 'Result Details')),
      body: SafeArea(
        child: record == null
            ? Center(child: Text(thai ? 'ไม่พบประวัติ' : 'History not found'))
            : ResponsiveListView(
                maxWidth: 640,
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.activityName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SooktaColors.darkGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((record.farmerName ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              thai
                                  ? 'ชาวสวน: ${record.farmerName}'
                                  : 'Farmer: ${record.farmerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            thai
                                ? 'บันทึกเมื่อ: ${_date(record.dateTime)}'
                                : 'Date: ${_date(record.dateTime)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 330;
                              final beforePill = _ScorePill(
                                label: thai ? 'ก่อน' : 'Before',
                                score: record.scoreBefore,
                                risk: record.riskBefore,
                              );
                              final afterPill = _ScorePill(
                                label: thai ? 'หลัง' : 'After',
                                score: record.scoreAfter,
                                risk: record.riskAfter,
                              );
                              final tts = SooktaTtsButton(
                                thai: thai,
                                text: thai
                                    ? '${record.activityName} คะแนนก่อนปรับ ${record.scoreBefore} คะแนนหลังปรับ ${record.scoreAfter} ผลกระทบด้านรายได้อาจลดลง ${record.moneySaved} บาทต่อปี'
                                    : '${record.activityName}. Before score ${record.scoreBefore}. After score ${record.scoreAfter}. Potential income impact may be reduced by ${record.moneySaved} baht per year.',
                              );
                              if (compact) {
                                return Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: tts,
                                    ),
                                    beforePill,
                                    const SizedBox(height: 10),
                                    afterPill,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  tts,
                                  const SizedBox(width: 8),
                                  Expanded(child: beforePill),
                                  const SizedBox(width: 10),
                                  Expanded(child: afterPill),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.savings_outlined,
                          color: SooktaColors.darkGreen),
                      title: Text(
                        thai
                            ? 'ผลกระทบโดยประมาณเพื่อสื่อสารความเสี่ยง'
                            : 'Estimated Impact for Risk Communication',
                      ),
                      subtitle: Text(
                        thai
                            ? 'ก่อนปรับ ${record.economicLoss} บาท/ปี | อาจลดลง ${record.moneySaved} บาท/ปี'
                            : 'Before ${record.economicLoss} THB/year | Potentially reduced ${record.moneySaved} THB/year',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ResearchDisclaimerCard(thai: thai),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _exportRecord(
                      context: context,
                      state: state,
                      record: record,
                      thai: thai,
                    ),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      thai
                          ? 'ส่งออกไฟล์ Excel สำหรับเจ้าหน้าที่'
                          : 'Export Excel file for staff',
                    ),
                  ),
                  if (record.aiRiskPercent != null &&
                      record.aiAlertLevel != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.psychology_alt_outlined,
                          color: _aiColor(record.aiAlertLevel!),
                        ),
                        title: Text(
                          thai
                              ? 'สัญญาณช่วยเฝ้าระวังท่าทาง'
                              : 'Posture Awareness Signal',
                        ),
                        subtitle: Text(
                          '${_aiLabel(record.aiAlertLevel!, thai)} • '
                          '${record.aiRiskPercent}% • '
                          '${_aiModelSource(record.aiModelSource, thai)}',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  BodyRiskMapCard(
                    bodyRisks: record.bodyPartRisks,
                    thai: thai,
                    title: thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thai
                                ? 'แนวทางที่คุณเลือกไว้'
                                : 'Selected Improvements',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (record.selectedSuggestions.isEmpty)
                            Text(thai ? 'ไม่มีรายการ' : 'No items')
                          else
                            ...record.selectedSuggestions.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.done,
                                        size: 18,
                                        color: SooktaColors.leafGreen),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(item)),
                                    SooktaTtsButton(
                                      text: item,
                                      thai: thai,
                                      size: 32,
                                    ),
                                  ],
                                ),
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

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Color _aiColor(AiAlertLevel level) {
    return switch (level) {
      AiAlertLevel.low => SooktaColors.leafGreen,
      AiAlertLevel.watch => Colors.amber.shade700,
      AiAlertLevel.high => Colors.deepOrange,
      AiAlertLevel.critical => Colors.red.shade800,
    };
  }

  String _aiLabel(AiAlertLevel level, bool thai) {
    if (thai) {
      return switch (level) {
        AiAlertLevel.low => 'ความเสี่ยงต่ำ',
        AiAlertLevel.watch => 'ควรเฝ้าระวัง',
        AiAlertLevel.high => 'ความเสี่ยงสูง',
        AiAlertLevel.critical => 'ความเสี่ยงสูงมาก',
      };
    }
    return switch (level) {
      AiAlertLevel.low => 'Low risk',
      AiAlertLevel.watch => 'Watch',
      AiAlertLevel.high => 'High risk',
      AiAlertLevel.critical => 'Critical risk',
    };
  }

  String _aiModelSource(String? source, bool thai) {
    if (source == 'research_trained') {
      return thai ? 'ประเมินจากข้อมูลท่าทาง' : 'Based on posture data';
    }
    return thai
        ? 'ต้นแบบวิจัยจากท่าทางและคะแนนงาน'
        : 'Research prototype using posture and task scores';
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.label,
    required this.score,
    required this.risk,
  });

  final String label;
  final int score;
  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(risk.colorHex).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(risk.colorHex).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            FixedTextScale(
              child: Text(
                '$score',
                maxLines: 1,
                style: TextStyle(
                  color: Color(risk.colorHex),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
