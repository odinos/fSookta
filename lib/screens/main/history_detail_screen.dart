import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/theme/sookta_theme.dart';

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
            : ListView(
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
                            style: const TextStyle(
                              color: SooktaColors.darkGreen,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            thai
                                ? 'บันทึกเมื่อ: ${_date(record.dateTime)}'
                                : 'Date: ${_date(record.dateTime)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _ScorePill(
                                  label: thai ? 'ก่อน' : 'Before',
                                  score: record.scoreBefore,
                                  risk: record.riskBefore,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ScorePill(
                                  label: thai ? 'หลัง' : 'After',
                                  score: record.scoreAfter,
                                  risk: record.riskAfter,
                                ),
                              ),
                            ],
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
                          thai ? 'ความสูญเสียก่อนปรับปรุง' : 'Potential Loss'),
                      subtitle: Text(
                        thai
                            ? '${record.economicLoss} บาท/ปี | ลดได้ ${record.moneySaved} บาท/ปี'
                            : '${record.economicLoss} THB/year | Saved ${record.moneySaved} THB/year',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: record.bodyPartRisks.entries.map((entry) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Color(entry.value.colorHex),
                                ),
                                label: Text(
                                    '${_part(entry.key, thai)}: ${_risk(entry.value, thai)}'),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
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

  String _part(BodyPart part, bool thai) {
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

  String _risk(RiskLevel risk, bool thai) {
    if (thai) return risk.label;
    return switch (risk) {
      RiskLevel.low => 'Low',
      RiskLevel.medium => 'Medium',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'Very High',
    };
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
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(
              '$score',
              style: TextStyle(
                color: Color(risk.colorHex),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
