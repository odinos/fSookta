import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import '../../core/theme/sookta_theme.dart';
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thai ? 'ผลตรวจย้อนหลัง' : 'Assessment History',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        thai
                            ? 'ประวัติการประเมินความเสี่ยงของคุณ'
                            : 'Your risk assessment records',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 64, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(text.noHistory, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return _HistoryCard(
                          record: item,
                          thai: thai,
                          onTap: () => Navigator.of(context).pushNamed(
                            HistoryDetailScreen.routeName,
                            arguments: item.id,
                          ),
                        );
                      },
                    ),
            ),
          ],
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
  });

  final EvaluationHistoryRecord record;
  final bool thai;
  final VoidCallback onTap;

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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(record.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          thai
              ? 'ก่อน ${record.scoreBefore} → หลัง ${record.scoreAfter} | ลดได้ ${record.moneySaved} บาท/ปี'
              : 'Before ${record.scoreBefore} → After ${record.scoreAfter} | Saved ${record.moneySaved} THB/year',
        ),
        trailing: const Icon(Icons.navigate_next),
      ),
    );
  }
}
