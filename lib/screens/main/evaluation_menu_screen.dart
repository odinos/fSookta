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
    final language = AppStateScope.of(context).language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;

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
