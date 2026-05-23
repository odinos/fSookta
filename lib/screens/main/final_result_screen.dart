import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/localization/sookta_strings.dart';
import '../../core/models/assessment_session.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/body_risk_map_card.dart';
import '../../widgets/research_disclaimer_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
import 'main_tabs_screen.dart';

class FinalResultScreen extends StatefulWidget {
  const FinalResultScreen({
    required this.bundle,
    super.key,
  });

  static const routeName = '/final-result';

  final AssessmentBundle bundle;

  @override
  State<FinalResultScreen> createState() => _FinalResultScreenState();
}

class _FinalResultScreenState extends State<FinalResultScreen> {
  EvaluationHistoryRecord? savedRecord;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || savedRecord != null) return;
      final strings = _strings(context);
      setState(() {
        savedRecord = AppStateScope.of(context).saveEvaluation(
          activityName: widget.bundle.activityName,
          before: widget.bundle.before,
          after: widget.bundle.after,
          selectedSuggestions:
              widget.bundle.selectedSuggestionKeys.map(strings.get).toList(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final strings = _strings(context);
    final before = widget.bundle.before;
    final after = widget.bundle.after;
    final saved = before.economicLoss - after.economicLoss;
    final suggestions =
        widget.bundle.selectedSuggestionKeys.map(strings.get).toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(thai ? 'บันทึกและสรุปผลสำเร็จ' : 'Saved Successfully')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 640,
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 64, color: SooktaColors.leafGreen),
                    const SizedBox(height: 8),
                    ClampedTextScale(
                      maxScale: 1.12,
                      child: Text(
                        thai
                            ? 'ผลลัพธ์โดยประมาณหลังเลือกแนวทางปรับปรุง'
                            : 'Estimated result after selected improvements',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 330;
                        final beforeBlock = _ScoreBlock(
                          label: thai ? 'ก่อนปรับ' : 'Before',
                          score: before.userScore,
                          color: Color(before.userScoreColor),
                        );
                        final afterBlock = _ScoreBlock(
                          label: thai ? 'หลังปรับ' : 'After',
                          score: after.userScore,
                          color: Color(after.userScoreColor),
                        );
                        final tts = SooktaTtsButton(
                          thai: thai,
                          text: thai
                              ? 'ผลลัพธ์โดยประมาณหลังเลือกแนวทางปรับปรุง ก่อนปรับ ${before.userScore} หลังปรับ ${after.userScore}'
                              : 'Estimated result after selected improvements. Before ${before.userScore}. After ${after.userScore}.',
                        );
                        if (compact) {
                          return Column(
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft, child: tts),
                              beforeBlock,
                              const Icon(Icons.arrow_downward,
                                  color: SooktaColors.leafGreen),
                              afterBlock,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            tts,
                            const SizedBox(width: 8),
                            Expanded(child: beforeBlock),
                            const Icon(Icons.arrow_forward,
                                color: SooktaColors.leafGreen),
                            Expanded(child: afterBlock),
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
                      ? 'ผลกระทบที่อาจลดลงโดยประมาณ'
                      : 'Estimated Potential Impact Reduction',
                ),
                subtitle: Text(
                  saved > 0
                      ? (thai
                          ? 'ประมาณ $saved บาท/ปี เพื่อการสื่อสารความเสี่ยง'
                          : 'Estimated $saved THB/year for risk communication')
                      : (thai
                          ? 'ไม่พบผลกระทบด้านรายได้เพิ่มเติมจากแบบจำลองนี้'
                          : 'No additional potential income impact in this model'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ResearchDisclaimerCard(thai: thai),
            const SizedBox(height: 16),
            BodyRiskMapCard(
              bodyRisks: before.bodyPartRisks,
              thai: thai,
              title: thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      thai
                          ? 'แนวทางที่คุณเลือกปฏิบัติ'
                          : 'Selected Improvements',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (suggestions.isEmpty)
                      Text(thai
                          ? 'ไม่ได้เลือกแนวทางเพิ่มเติม'
                          : 'No selected improvements')
                    else
                      ...suggestions.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.done,
                                  size: 18, color: SooktaColors.leafGreen),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  MainTabsScreen.routeName,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.home),
              label: Text(thai ? 'กลับสู่หน้าหลัก' : 'Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  SooktaStrings _strings(BuildContext context) {
    final language = AppStateScope.of(context).language ?? AppLanguage.th;
    return SooktaStrings(
        language == AppLanguage.th ? SooktaLocale.th : SooktaLocale.en);
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 6),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: FixedTextScale(
              child: Text(
                '$score',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
