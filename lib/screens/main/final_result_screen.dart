import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/localization/sookta_strings.dart';
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/assessment_export_service.dart';
import '../../core/services/daily_injury_prediction_service.dart';
import '../../core/services/economic_impact_service.dart';
import '../../core/services/firebase_telemetry_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/assessment_breakdown_card.dart';
import '../../widgets/body_risk_map_card.dart';
import '../../widgets/economic_impact_comparison_card.dart';
import '../../widgets/research_disclaimer_card.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
import 'daily_prediction_screen.dart';
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
  bool savingRecord = false;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_saveResultOnce());
    });
  }

  Future<void> _saveResultOnce() async {
    if (!mounted || savedRecord != null || savingRecord) return;
    savingRecord = true;
    final strings = _strings(context);
    late final EvaluationHistoryRecord record;
    try {
      record = await AppStateScope.of(context).saveEvaluation(
        activity: widget.bundle.activity,
        activityName: widget.bundle.activityName,
        before: widget.bundle.before,
        after: widget.bundle.after,
        selectedSuggestions:
            widget.bundle.selectedSuggestionKeys.map(strings.get).toList(),
        assessmentBreakdown: widget.bundle.breakdown,
        afterAssessmentBreakdown: widget.bundle.afterBreakdown,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'sookta final result',
        context: ErrorDescription('saving an evaluation history record'),
      ));
      if (mounted) {
        setState(() => savingRecord = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      savedRecord = record;
      savingRecord = false;
    });
    unawaited(FirebaseTelemetryService.logAssessmentSaved(
      activity: widget.bundle.activity.name,
      beforeRisk: widget.bundle.before.riskLevel.name,
      afterRisk: widget.bundle.after.riskLevel.name,
      beforeScore: widget.bundle.before.userScore,
      afterScore: widget.bundle.after.userScore,
      suggestionCount: widget.bundle.selectedSuggestionKeys.length,
    ));
    unawaited(_showDailyPredictionAlertIfNeeded(record));
  }

  Future<void> _showDailyPredictionAlertIfNeeded(
    EvaluationHistoryRecord record,
  ) async {
    try {
      final state = AppStateScope.of(context);
      final profileId = record.farmerProfileId ?? state.profile.profileId;
      final records =
          profileId.isEmpty ? state.history : state.historyForFarmer(profileId);
      if (records.length < 7 || records.length % 7 != 0) return;
      final service = await DailyInjuryPredictionService.load();
      final prediction = service.predictForRecords(records);
      if (!mounted || !prediction.requiresCareAlert) return;
      final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ครบ ${records.length} ครั้งแล้ว: งานจริงก่อนปรับยังพบความเสี่ยงสูงหลายครั้ง ควรดูแนวโน้ม'
                : '${records.length} records reached: high actual pre-improvement risk appears several times.',
          ),
          action: SnackBarAction(
            label: thai ? 'ดูผล' : 'View',
            onPressed: () => Navigator.of(context).pushNamed(
              DailyPredictionScreen.routeName,
            ),
          ),
        ),
      );
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final strings = _strings(context);
    final before = widget.bundle.before;
    final after = widget.bundle.after;
    final recordReady = savedRecord != null;
    final impactComparison = EconomicImpactService.compareBeforeAfter(
      beforeImpact: before.economicLoss,
      beforeScore: before.userScore,
      afterScore: after.userScore,
    );
    final saved = impactComparison.savedAmount;
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
                              ? 'ผลลัพธ์โดยประมาณหลังเลือกแนวทางปรับปรุง ก่อนปรับ ${before.userScore} หลังปรับ ${after.userScore} ผลกระทบก่อนปรับ ${impactComparison.beforeImpact} บาทต่อปี หลังปรับประมาณ ${impactComparison.afterImpact} บาทต่อปี อาจประหยัดได้ ${impactComparison.savedAmount} บาทต่อปี'
                              : 'Estimated result after selected improvements. Before score ${before.userScore}. After score ${after.userScore}. Before impact ${impactComparison.beforeImpact} baht per year. After impact about ${impactComparison.afterImpact} baht per year. Potential saving ${impactComparison.savedAmount} baht per year.',
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
            EconomicImpactComparisonCard(
              comparison: impactComparison,
              thai: thai,
            ),
            const SizedBox(height: 16),
            _FarmerFinalSummaryCard(
              before: before,
              after: after,
              saved: saved,
              thai: thai,
            ),
            const SizedBox(height: 12),
            ResearchDisclaimerCard(thai: thai),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: exporting || !recordReady
                  ? null
                  : () => _exportForStaff(
                        context: context,
                        state: state,
                        suggestions: suggestions,
                        thai: thai,
                      ),
              icon: exporting || !recordReady
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                !recordReady
                    ? (thai ? 'กำลังบันทึกข้อมูล...' : 'Saving result...')
                    : (thai
                        ? 'ส่งออกไฟล์ Excel สำหรับเจ้าหน้าที่'
                        : 'Export Excel file for staff'),
              ),
            ),
            const SizedBox(height: 16),
            BodyRiskMapCard(
              bodyRisks: before.bodyPartRisks,
              thai: thai,
              title: thai ? 'จุดเสี่ยงที่พบ' : 'Risky Points',
              bodyRiskReasons: assessmentBodyRiskReasons(
                widget.bundle.breakdown,
                thai,
              ),
            ),
            const SizedBox(height: 16),
            AssessmentMethodSummaryCard(
              breakdown: widget.bundle.breakdown,
              thai: thai,
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
            const SizedBox(height: 12),
            RiskReferenceFootnote(thai: thai),
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
      final afterImpact = EconomicImpactService.estimateAfterBreakdown(
        beforeImpact: beforeImpact,
        beforeScore: before.userScore,
        afterScore: after.userScore,
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
      unawaited(FirebaseTelemetryService.logExportCreated(
        exportType: 'assessment_csv',
        recordCount: 1,
      ));
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
                      ? 'ผลกระทบก่อนปรับ ${before.economicLoss} บาท หลังปรับประมาณ ${after.economicLoss} บาท จึงอาจประหยัดได้ $saved บาท ใช้เป็นข้อมูลคุยกับเจ้าหน้าที่'
                      : 'Estimated impact changes from ${before.economicLoss} THB to about ${after.economicLoss} THB, a potential saving of $saved THB. Staff can review the export.')
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
    final textColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? const Color(0xFF263238)
            : Colors.white;

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
                style: TextStyle(
                  color: textColor,
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
