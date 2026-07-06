import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/assessment_session.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
import 'evaluation_form_screen.dart';

class EvaluationMenuScreen extends StatelessWidget {
  const EvaluationMenuScreen({super.key});

  static const routeName = '/evaluation-menu';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final language = state.language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;
    final draft = state.evaluationDraft;

    return Scaffold(
      appBar: AppBar(
        title: Text(thai ? 'เลือกประเภทงาน' : 'Select Job Type'),
      ),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 880,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  kToolbarHeight -
                  32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thai
                        ? 'โปรดเลือกกิจกรรมที่ต้องการประเมิน'
                        : 'Please select an activity to evaluate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SooktaTtsButton(
                      thai: thai,
                      text: thai
                          ? 'เลือกกิจกรรมที่ต้องการประเมิน เช่น ปลูกกล้า ใส่ปุ๋ย ฉีดพ่น ตัดแต่งกิ่ง เก็บเกี่ยว หรือขนย้ายผลผลิต หลังเลือกแล้วให้ถ่ายรูปท่าทางทำงานให้เห็นคนชัดเจน'
                          : 'Choose the activity to assess, such as transplanting, fertilizing, spraying, pruning, harvesting, or transport. After choosing, take a clear work-posture photo.',
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (draft != null) ...[
                    _DraftResumeCard(
                      draft: draft,
                      thai: thai,
                      onResume: () => Navigator.of(context).pushNamed(
                        EvaluationFormScreen.routeName,
                        arguments: draft.activity,
                      ),
                      onClear: () => state.clearEvaluationDraft(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 720
                            ? 3
                            : constraints.maxWidth < 340
                                ? 1
                                : 2;
                        final aspectRatio = columns == 1 ? 2.4 : 0.95;
                        return GridView.builder(
                          itemCount: SooktaActivity.values.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: aspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            final activity = SooktaActivity.values[index];
                            return _ActivityCard(
                              activity: activity,
                              label: activity.label(thai: thai),
                              thai: thai,
                              onTap: () => Navigator.of(context).pushNamed(
                                EvaluationFormScreen.routeName,
                                arguments: activity,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftResumeCard extends StatelessWidget {
  const _DraftResumeCard({
    required this.draft,
    required this.thai,
    required this.onResume,
    required this.onClear,
  });

  final EvaluationDraft draft;
  final bool thai;
  final VoidCallback onResume;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final activityName = draft.activity.label(thai: thai);
    final imageCount = draft.selectedImagePaths.length;
    final detail = thai
        ? '$activityName • รูป $imageCount/4'
        : '$activityName • $imageCount/4 photos';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6E7DD)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final text = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thai ? 'แบบร่างล่าสุด' : 'Latest draft',
                  style: const TextStyle(
                    color: SooktaColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
                label: Text(thai ? 'ล้างแบบร่าง' : 'Clear'),
              ),
              FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: Text(thai ? 'กลับไปทำแบบร่างต่อ' : 'Resume draft'),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.history, color: SooktaColors.darkGreen),
                  const SizedBox(width: 10),
                  text,
                ]),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              const Icon(Icons.history, color: SooktaColors.darkGreen),
              const SizedBox(width: 10),
              text,
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.label,
    required this.thai,
    required this.onTap,
  });

  final SooktaActivity activity;
  final String label;
  final bool thai;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: Image.asset(
                    activity.imageAsset,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ClampedTextScale(
                maxScale: 1.12,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SooktaColors.darkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SooktaTtsButton(
                thai: thai,
                text: thai
                    ? '$label ระบบจะเตรียมวิธีคำนวณที่เหมาะกับกิจกรรมนี้ให้'
                    : '$label. The app will prepare the suitable calculation method for this activity.',
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
