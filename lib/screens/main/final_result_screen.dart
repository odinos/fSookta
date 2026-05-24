import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/localization/sookta_strings.dart';
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/assessment_export_service.dart';
import '../../core/services/economic_impact_service.dart';
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
  bool exporting = false;

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
            _FarmerFinalSummaryCard(
              before: before,
              after: after,
              saved: saved,
              thai: thai,
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: exporting
                  ? null
                  : () => _exportForStaff(
                        context: context,
                        state: state,
                        suggestions: suggestions,
                        thai: thai,
                      ),
              icon: exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                thai
                    ? 'ส่งออกไฟล์ Excel สำหรับเจ้าหน้าที่'
                    : 'Export Excel file for staff',
              ),
            ),
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

  Future<void> _exportForStaff({
    required BuildContext context,
    required SooktaAppState state,
    required List<String> suggestions,
    required bool thai,
  }) async {
    setState(() => exporting = true);
    try {
      final before = widget.bundle.before;
      final after = widget.bundle.after;
      final dailyIncome = state.dailyIncome.toDouble();
      final beforeImpact = EconomicImpactService.estimate(
        overallRisk: before.riskLevel,
        dailyIncome: dailyIncome,
        bodyPartRisks: before.bodyPartRisks,
      );
      final afterImpact = EconomicImpactService.estimate(
        overallRisk: after.riskLevel,
        dailyIncome: dailyIncome,
        bodyPartRisks: after.bodyPartRisks,
      );
      final file = await AssessmentExportService.exportExcelCsv(
        bundle: widget.bundle,
        profile: state.profile,
        selectedSuggestions: suggestions,
        beforeImpact: beforeImpact,
        afterImpact: afterImpact,
        record: savedRecord,
        thai: thai,
      );
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: thai ? 'ไฟล์ผลประเมินสุขท่า' : 'Sookta assessment export',
          subject: thai ? 'ไฟล์ผลประเมินสุขท่า' : 'Sookta assessment export',
          text: thai
              ? 'ไฟล์ CSV นี้เปิดด้วย Excel ได้ สำหรับเจ้าหน้าที่ใช้ติดตามผลประเมิน'
              : 'This CSV opens in Excel for staff assessment review.',
          files: [XFile(file.path, mimeType: 'text/csv')],
          fileNameOverrides: [file.uri.pathSegments.last],
          sharePositionOrigin: _shareOrigin(context),
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'สร้างไฟล์สำหรับเจ้าหน้าที่แล้ว'
                : 'Staff export file created.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังส่งออกไฟล์ไม่ได้ กรุณาลองอีกครั้ง'
                : 'Could not export the file. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Rect? _shareOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

class _FarmerFinalSummaryCard extends StatelessWidget {
  const _FarmerFinalSummaryCard({
    required this.before,
    required this.after,
    required this.saved,
    required this.thai,
  });

  final ErgoResult before;
  final ErgoResult after;
  final int saved;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final isBetter = after.userScore < before.userScore;
    return Card(
      color: const Color(0xFFF4FBF5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isBetter ? Icons.check_circle_outline : Icons.info_outline,
                  color: SooktaColors.darkGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai ? 'สรุปแบบเข้าใจง่าย' : 'Simple summary',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isBetter
                  ? (thai
                      ? 'ท่าทางนี้ดีขึ้นจากคะแนน ${before.userScore} เหลือ ${after.userScore}'
                      : 'This posture improves from ${before.userScore} to ${after.userScore}.')
                  : (thai
                      ? 'คะแนนยังไม่ลดลง ลองเลือกวิธีปรับท่าทางเพิ่มในครั้งต่อไป'
                      : 'The score has not dropped yet. Try more posture actions next time.'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              saved > 0
                  ? (thai
                      ? 'ผลกระทบที่อาจลดลงประมาณ $saved บาท ใช้เป็นข้อมูลคุยกับเจ้าหน้าที่'
                      : 'Potential impact may reduce by about $saved THB. Staff can review the export.')
                  : (thai
                      ? 'ข้อมูลนี้ถูกบันทึกแล้ว เจ้าหน้าที่สามารถดูรายละเอียดจากไฟล์ส่งออก'
                      : 'This result is saved. Staff can review details from the export.'),
            ),
          ],
        ),
      ),
    );
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
