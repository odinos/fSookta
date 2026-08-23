import 'package:flutter/material.dart';

import '../../app/assets.dart';
import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/assessment_reference_sources.dart';
import '../../core/models/assessment_session.dart';
import '../../core/services/manual_document_service.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const routeName = '/help';

  @override
  Widget build(BuildContext context) {
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
        AppLanguage.th;

    final steps = thai ? _thaiHelpSteps : _englishHelpSteps;
    final quickTips = thai ? _thaiQuickTips : _englishQuickTips;
    final ttsText = [
      thai ? 'คู่มือการใช้งานสุขท่า' : 'Sookta user manual',
      ...steps.map((step) => '${step.title}. ${step.body}'),
      ...quickTips,
    ].join('. ');

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'คู่มือการใช้งาน' : 'User Manual')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 760,
          children: [
            _HelpHeaderCard(
              thai: thai,
              ttsText: ttsText,
            ),
            const SizedBox(height: 16),
            _ManualPdfCard(thai: thai),
            const SizedBox(height: 16),
            _ActivityExampleGallery(thai: thai),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF2E7D32),
                ),
                title: Text(thai ? 'แหล่งอ้างอิง' : 'References'),
                subtitle: Text(
                  thai
                      ? 'REBA, ISO 11228 และเอกสารอ้างอิงที่ใช้ในแอป'
                      : 'REBA, ISO 11228, and source references used in the app',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed(ReferencesScreen.routeName),
              ),
            ),
            const SizedBox(height: 16),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HelpStepCard(step: step, thai: thai),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tips_and_updates_outlined,
                            color: Color(0xFF2E7D32)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            thai ? 'ข้อควรจำ' : 'Helpful Reminders',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        SooktaTtsButton(
                          text: quickTips.join('. '),
                          thai: thai,
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...quickTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Icon(Icons.circle,
                                  size: 7, color: Color(0xFF66A88F)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tip)),
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
}

class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  static const routeName = '/references';

  @override
  Widget build(BuildContext context) {
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
        AppLanguage.th;
    final ttsText = [
      thai ? 'แหล่งอ้างอิง' : 'References',
      ...AssessmentReferenceSources.references,
    ].join('. ');

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'แหล่งอ้างอิง' : 'References')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 760,
          children: [
            Card(
              color: const Color(0xFFEAF5EF),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.menu_book_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thai
                                ? 'เอกสารที่ใช้ประกอบการประเมิน'
                                : 'Assessment source references',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF214D3A),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            thai
                                ? 'รายการนี้แสดงมาตรฐานและงานวิจัยที่ใช้เป็นฐานความรู้ของการคำนวณและคำแนะนำในแอป'
                                : 'These standards and studies are used as knowledge references for the app calculations and recommendations.',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    SooktaTtsButton(text: ttsText, thai: thai, size: 42),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AssessmentReferenceSources.references
                      .map(
                        (reference) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: Color(0xFF66A88F),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reference,
                                  style: const TextStyle(
                                    height: 1.45,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualPdfCard extends StatelessWidget {
  const _ManualPdfCard({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF7E0),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.picture_as_pdf_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thai
                            ? 'อ่านจากคู่มือ PDF ฉบับเต็ม'
                            : 'Read the full PDF manual',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF214D3A),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        thai
                            ? 'เอกสารคู่มือถูกนำมาเรียงเป็นหน้าอ่านในแอป และยังเปิดเป็นไฟล์ PDF ฉบับเต็มได้'
                            : 'The PDF manual pages are arranged for in-app reading, and the full PDF can still be opened.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ManualPageGallery(thai: thai),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openManual(context, thai),
              icon: const Icon(Icons.open_in_new),
              label: Text(thai ? 'เปิดคู่มือการใช้งาน' : 'Open User Manual'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManual(BuildContext context, bool thai) async {
    try {
      await ManualDocumentService.openManual(thai: thai);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังเปิดคู่มือไม่ได้ กรุณาลองใหม่อีกครั้ง'
                : 'Could not open the manual. Please try again.',
          ),
        ),
      );
    }
  }
}

const _manualPageAssets = [
  SooktaAssets.userManualPage1,
  SooktaAssets.userManualPage2,
  SooktaAssets.userManualPage3,
  SooktaAssets.userManualPage4,
  SooktaAssets.userManualPage5,
];

class _ManualPageGallery extends StatelessWidget {
  const _ManualPageGallery({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _manualPageAssets.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final pageNumber = index + 1;
            final title =
                thai ? 'คู่มือหน้า $pageNumber' : 'Manual page $pageNumber';
            return _PreviewableAssetImage(
              key: ValueKey('manual_pdf_page_$pageNumber'),
              imageAsset: _manualPageAssets[index],
              title: title,
              thai: thai,
              fit: BoxFit.contain,
            );
          },
        );
      },
    );
  }
}

class _HelpStep {
  const _HelpStep({
    required this.title,
    required this.body,
    required this.icon,
    this.imageAsset,
  });

  final String title;
  final String body;
  final IconData icon;
  final String? imageAsset;
}

const _thaiHelpSteps = [
  _HelpStep(
    title: '1. เลือกหรือเพิ่มชาวสวน',
    body:
        'หน้าแรกจะแสดงชาวสวนที่กำลังเก็บข้อมูลอยู่ หากเจ้าหน้าที่เก็บข้อมูลหลายคน ให้กดสลับรายชื่อเพื่อเลือก เพิ่ม แก้ไข หรือลบชาวสวนก่อนเริ่มประเมิน',
    icon: Icons.groups_outlined,
    imageAsset: SooktaAssets.female01,
  ),
  _HelpStep(
    title: '2. เลือกกิจกรรมที่ทำจริง',
    body:
        'กดเริ่มทำแบบประเมิน แล้วเลือกกิจกรรม เช่น ปลูกกล้า ใส่ปุ๋ย ฉีดพ่น ตัดแต่งกิ่ง เก็บเกี่ยว หรือขนย้ายผลผลิต แอปจะเตรียมวิธีคำนวณที่เหมาะกับงานนั้นให้เอง',
    icon: Icons.grid_view_outlined,
    imageAsset: SooktaAssets.transplanting,
  ),
  _HelpStep(
    title: '3. ถ่ายรูปหรือเลือกรูปท่าทาง',
    body:
        'ถ่ายให้เห็นคนทำงานเกือบทั้งตัว แสงชัด ไม่ให้ใบไม้หรือเครื่องมือบังศีรษะ หลัง แขน มือ และขา ถ่ายได้สูงสุด 4 รูป หรือใช้วิดีโอสั้น ระบบจะอ่านท่าทางและตั้งค่าประเมินให้อัตโนมัติ',
    icon: Icons.camera_alt_outlined,
    imageAsset: SooktaAssets.readablePoseExample,
  ),
  _HelpStep(
    title: '4. ตรวจข้อมูลก่อนดูผล',
    body:
        'เปิดส่วนปรับรายละเอียดเพื่อเลือกค่าน้ำหนัก ระยะทาง ความถี่ ระยะเวลา หรือแรงดันลากที่ใกล้เคียงงานจริงที่สุด ค่าเหล่านี้มีผลต่อคะแนน REBA และ ISO11228 หากไม่แน่ใจใช้ค่าเริ่มต้นได้',
    icon: Icons.tune_outlined,
  ),
  _HelpStep(
    title: '5. อ่านผลความเสี่ยง',
    body:
        'ทุกงานใช้ REBA เพื่อดูความเสี่ยงจากท่าทาง หากเป็นงานยก แบก ขนย้าย หรือดันลาก แอปจะใช้ ISO11228 ร่วมด้วย แล้วแสดงคะแนนรวม ระดับความเสี่ยง จุดเสี่ยงบนร่างกาย และผลกระทบทางเศรษฐกิจโดยประมาณ',
    icon: Icons.analytics_outlined,
  ),
  _HelpStep(
    title: '6. เลือกวิธีลดความเสี่ยง',
    body:
        'หน้าคำแนะนำจะแสดงวิธีปรับงานที่ทำได้จริง เช่น ลดการก้มบิด ใช้อุปกรณ์ช่วย แบ่งน้ำหนัก หรือพักเป็นช่วง เลือกวิธีที่ทำได้ ระบบจะแสดงคะแนนหลังปรับปรุงให้เห็นทันที',
    icon: Icons.checklist_rtl_outlined,
    imageAsset: SooktaAssets.pruning,
  ),
  _HelpStep(
    title: '7. ดูประวัติและส่งออกไฟล์',
    body:
        'ผลตรวจจะถูกบันทึกในเมนูผลตรวจ สามารถเปิดดูย้อนหลัง แยกตามชาวสวน และส่งออกไฟล์ CSV ที่เปิดด้วย Excel ได้ เพื่อให้เจ้าหน้าที่นำข้อมูลไปใช้ต่อในงานวิจัย',
    icon: Icons.ios_share_outlined,
  ),
];

const _englishHelpSteps = [
  _HelpStep(
    title: '1. Select or add a farmer',
    body:
        'Home shows the farmer currently being recorded. For field research with multiple farmers, switch the active farmer or add, edit, and delete farmer records before starting an assessment.',
    icon: Icons.groups_outlined,
    imageAsset: SooktaAssets.female01,
  ),
  _HelpStep(
    title: '2. Choose the real activity',
    body:
        'Tap Start Evaluation and choose the work activity, such as planting, fertilizing, spraying, pruning, harvesting, or produce transport. The app prepares the right assessment method for that task.',
    icon: Icons.grid_view_outlined,
    imageAsset: SooktaAssets.transplanting,
  ),
  _HelpStep(
    title: '3. Take or choose posture photos',
    body:
        'Capture almost the full worker with clear light. Avoid leaves or tools covering the head, back, arms, hands, and legs. You can add up to 4 photos or a short video. The app reads posture and prepares the assessment automatically.',
    icon: Icons.camera_alt_outlined,
    imageAsset: SooktaAssets.readablePoseExample,
  ),
  _HelpStep(
    title: '4. Review before viewing results',
    body:
        'Open the detail section to choose load, distance, frequency, duration, or push/pull force values that are closest to the real task. These values affect REBA and ISO11228 scores. If unsure, keep the defaults.',
    icon: Icons.tune_outlined,
  ),
  _HelpStep(
    title: '5. Read the risk result',
    body:
        'All activities use REBA for posture risk. If the task includes lifting, carrying, transport, pushing, or pulling, the app also uses ISO11228 and shows the combined score, risk level, risky body areas, and estimated economic impact.',
    icon: Icons.analytics_outlined,
  ),
  _HelpStep(
    title: '6. Choose risk-reduction actions',
    body:
        'The recommendations screen shows practical actions such as reducing twisting, using support tools, splitting loads, or taking work breaks. Select what can really be done and the app shows the improved score.',
    icon: Icons.checklist_rtl_outlined,
    imageAsset: SooktaAssets.pruning,
  ),
  _HelpStep(
    title: '7. Review history and export files',
    body:
        'Results are saved in History. You can review past assessments by farmer and export Excel-compatible CSV files for research staff.',
    icon: Icons.ios_share_outlined,
  ),
];

const _thaiQuickTips = [
  'ผลประเมินเป็นข้อมูลเพื่อการสื่อสารความเสี่ยงและงานวิจัย ไม่ใช่การวินิจฉัยทางการแพทย์',
  'ถ้าระบบอ่านภาพไม่ได้ ให้ถ่ายใหม่ในมุมที่เห็นทั้งตัว หรือกดดูผลโดยใช้ค่าพื้นฐานของงานนั้น',
  'งานทั่วไปใช้ REBA ทุกครั้ง และใช้ ISO11228 เพิ่มเฉพาะงานที่มีการยก แบก ขนย้าย ดัน หรือลาก',
  'ข้อมูลค่าใช้จ่ายเป็นค่าประมาณเพื่อให้เห็นผลกระทบ ไม่ใช่ใบแจ้งค่ารักษาจริงเฉพาะบุคคล',
];

const _englishQuickTips = [
  'The assessment is for risk communication and research, not medical diagnosis.',
  'If the app cannot read a photo, retake it with the full body visible or continue with the task defaults.',
  'Every task uses REBA. ISO11228 is added only when the task involves lifting, carrying, transport, pushing, or pulling.',
  'Cost impact is an estimate for awareness and is not a personal medical bill.',
];

class _HelpHeaderCard extends StatelessWidget {
  const _HelpHeaderCard({
    required this.thai,
    required this.ttsText,
  });

  final bool thai;
  final String ttsText;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFEAF5EF),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo_app.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thai ? 'คู่มือการใช้งาน Sookta' : 'Sookta User Manual',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF214D3A),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    thai
                        ? 'รวมคู่มือ PDF ขั้นตอนใช้งาน และตัวอย่างภาพที่ควรถ่ายสำหรับแต่ละหมวดงาน'
                        : 'PDF manual, step-by-step guidance, and recommended capture examples for each activity.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            SooktaTtsButton(text: ttsText, thai: thai, size: 42),
          ],
        ),
      ),
    );
  }
}

class _HelpStepCard extends StatelessWidget {
  const _HelpStepCard({
    required this.step,
    required this.thai,
  });

  final _HelpStep step;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final imageAsset = step.imageAsset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final text = _StepText(step: step, thai: thai);
            final image = imageAsset == null
                ? null
                : _StepImage(
                    imageAsset: imageAsset,
                    title: step.title,
                    thai: thai,
                    compact: compact,
                  );

            if (compact || image == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  if (image != null) ...[
                    const SizedBox(height: 12),
                    image,
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: 14),
                image,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepText extends StatelessWidget {
  const _StepText({
    required this.step,
    required this.thai,
  });

  final _HelpStep step;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5EF),
                shape: BoxShape.circle,
              ),
              child: Icon(step.icon, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            SooktaTtsButton(text: step.body, thai: thai, size: 38),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          step.body,
          style: const TextStyle(height: 1.45, color: Colors.black87),
        ),
      ],
    );
  }
}

class _StepImage extends StatelessWidget {
  const _StepImage({
    required this.imageAsset,
    required this.title,
    required this.thai,
    required this.compact,
  });

  final String imageAsset;
  final String title;
  final bool thai;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: compact ? Alignment.center : Alignment.topRight,
      child: _PreviewableAssetImage(
        imageAsset: imageAsset,
        title: title,
        thai: thai,
        width: compact ? double.infinity : 132,
        height: compact ? 128 : 116,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ActivityExampleGallery extends StatelessWidget {
  const _ActivityExampleGallery({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEAF5EF),
                  foregroundColor: Color(0xFF2E7D32),
                  child: Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thai
                            ? 'ตัวอย่างภาพที่ควรถ่ายตามหมวดงาน'
                            : 'Recommended photo examples by activity',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        thai
                            ? 'ใช้ภาพตัวอย่างเพื่อเทียบมุมกล้องก่อนถ่ายจริง ควรเห็นศีรษะ หลัง แขน มือ ขา และเท้าให้ครบที่สุด'
                            : 'Use these examples to compare the camera angle before capture. The head, back, arms, hands, legs, and feet should be visible as much as possible.',
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620
                    ? 3
                    : constraints.maxWidth < 360
                        ? 1
                        : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: SooktaActivity.values.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columns == 1 ? 2.6 : 1.3,
                  ),
                  itemBuilder: (context, index) {
                    final activity = SooktaActivity.values[index];
                    final label = activity.label(thai: thai);
                    return _ActivityExampleTile(
                      key: ValueKey('help_activity_example_${activity.name}'),
                      title: label,
                      imageAsset: activity.readablePoseExampleAsset,
                      thai: thai,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityExampleTile extends StatelessWidget {
  const _ActivityExampleTile({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.thai,
  });

  final String title;
  final String imageAsset;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: thai ? 'ดูภาพเต็ม $title' : 'View full image: $title',
      child: InkWell(
        onTap: () => _showAssetPreview(context, imageAsset, title, thai),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6E7DD)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 220;
              final image = SizedBox(
                width: compact ? double.infinity : 104,
                height: compact ? 96 : 104,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
              final label = Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 8 : 0,
                  compact ? 0 : 8,
                  8,
                  8,
                ),
                child: Text(
                  thai ? 'ตัวอย่างภาพ: $title' : 'Example photo: $title',
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFF214D3A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
              if (compact) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    image,
                    label,
                  ],
                );
              }
              return Row(
                children: [
                  image,
                  Expanded(child: label),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewableAssetImage extends StatelessWidget {
  const _PreviewableAssetImage({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.thai,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String imageAsset;
  final String title;
  final bool thai;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const bottomInset = 34.0;
    final content = Stack(
      children: [
        Positioned.fill(
          bottom: bottomInset,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Image.asset(
              imageAsset,
              fit: fit,
              gaplessPlayback: true,
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Text(
            thai ? 'แตะเพื่อดูภาพเต็ม' : 'Tap to view full image',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );

    final imageCard = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: content,
    );

    final sizedContent = width == null && height == null
        ? AspectRatio(
            aspectRatio: 1.3,
            child: imageCard,
          )
        : SizedBox(
            width: width,
            height: height,
            child: imageCard,
          );

    return Semantics(
      button: true,
      label: thai ? 'ดูภาพเต็ม $title' : 'View full image: $title',
      child: InkWell(
        onTap: () => _showAssetPreview(context, imageAsset, title, thai),
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FBF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD6E7DD)),
          ),
          child: sizedContent,
        ),
      ),
    );
  }
}

Future<void> _showAssetPreview(
  BuildContext context,
  String imageAsset,
  String title,
  bool thai,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    tooltip: thai ? 'ปิด' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  key: const ValueKey('asset_image_full_preview'),
                  minScale: 0.7,
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Text(
                  thai
                      ? 'ใช้ภาพตัวอย่างนี้เพื่อเทียบมุมและกิจกรรม ก่อนถ่ายภาพหรือวิดีโอจริง'
                      : 'Use this example to compare the angle and activity before taking the real photo or video.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const routeName = '/terms';

  @override
  Widget build(BuildContext context) {
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
        AppLanguage.th;
    final items = thai ? _thaiTerms : _englishTerms;
    final ttsText =
        items.map((item) => '${item.title}. ${item.body}').join('. ');

    return Scaffold(
      appBar: AppBar(
        title: Text(thai ? 'เงื่อนไขการใช้งาน' : 'Terms of Use'),
      ),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 760,
          children: [
            Card(
              color: const Color(0xFFEAF5EF),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFFFFFFF),
                      foregroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.description_outlined),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thai
                                ? 'ข้อกำหนดและเงื่อนไข'
                                : 'Terms and Conditions',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF214D3A),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            thai
                                ? 'กรุณาอ่านก่อนใช้งาน แอปนี้ออกแบบเพื่อช่วยสื่อสารความเสี่ยงด้านการยศาสตร์และสนับสนุนงานวิจัยภาคสนาม'
                                : 'Please read before use. This app supports ergonomic risk communication and field research.',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    SooktaTtsButton(text: ttsText, thai: thai, size: 42),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TermsCard(item: item, thai: thai),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsItem {
  const _TermsItem({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

const _thaiTerms = [
  _TermsItem(
    title: '1. บทนำ',
    body:
        'การใช้งานแอปสุขท่าถือว่าผู้ใช้ยอมรับข้อกำหนดและเงื่อนไขเหล่านี้ ผู้ใช้ควรอ่านและทำความเข้าใจก่อนเริ่มบันทึกข้อมูลหรือประเมินความเสี่ยง',
    icon: Icons.info_outline,
  ),
  _TermsItem(
    title: '2. วัตถุประสงค์',
    body:
        'แอปใช้ประเมินความเสี่ยงทางการยศาสตร์เบื้องต้นสำหรับเกษตรกร และใช้สนับสนุนการเก็บข้อมูลภาคสนาม เช่น ข้อมูลชาวสวน กิจกรรม ท่าทาง ผลคะแนน คำแนะนำ และประวัติการประเมิน',
    icon: Icons.flag_outlined,
  ),
  _TermsItem(
    title: '3. ข้อควรระวัง',
    body:
        'ผลประเมินเป็นคำแนะนำเบื้องต้น ไม่ใช่การวินิจฉัยทางการแพทย์ ไม่ใช่การยืนยันการบาดเจ็บ และไม่ควรใช้แทนคำแนะนำจากแพทย์หรือนักวิชาชีพ หากมีอาการเจ็บปวดรุนแรงหรือผิดปกติควรปรึกษาผู้เชี่ยวชาญ',
    icon: Icons.health_and_safety_outlined,
  ),
  _TermsItem(
    title: '4. ข้อมูลส่วนบุคคล',
    body:
        'ข้อมูลโปรไฟล์และประวัติใช้เพื่อคำนวณและแสดงผลภายในแอป รวมถึงช่วยผูกผลประเมินกับรหัสผู้เข้าร่วมวิจัย แอปสร้างรหัสแบบสุ่มได้ และข้อมูลพื้นที่หรือสวนสามารถจัดการเพิ่มเติมในไฟล์ CSV/Excel ของงานวิจัย',
    icon: Icons.privacy_tip_outlined,
  ),
  _TermsItem(
    title: '5. ลิขสิทธิ์',
    body:
        'เนื้อหาและองค์ประกอบของแอปเป็นของผู้พัฒนาโครงการ ห้ามนำไปคัดลอก ดัดแปลง หรือเผยแพร่ต่อโดยไม่ได้รับอนุญาต เว้นแต่เป็นการใช้งานตามวัตถุประสงค์ของโครงการหรือได้รับอนุญาตจากเจ้าของสิทธิ์',
    icon: Icons.copyright_outlined,
  ),
];

const _englishTerms = [
  _TermsItem(
    title: '1. Introduction',
    body:
        'Using Sookta means you accept these terms and conditions. Users should read and understand them before recording data or starting a risk assessment.',
    icon: Icons.info_outline,
  ),
  _TermsItem(
    title: '2. Purpose',
    body:
        'The app provides preliminary ergonomic risk assessment for farmers and supports field research data collection, including farmer records, activities, posture, scores, recommendations, and assessment history.',
    icon: Icons.flag_outlined,
  ),
  _TermsItem(
    title: '3. Disclaimer',
    body:
        'Results are recommendations only and not medical diagnosis, confirmed injury evidence, or a substitute for advice from medical or occupational professionals. Seek professional advice for severe or unusual pain.',
    icon: Icons.health_and_safety_outlined,
  ),
  _TermsItem(
    title: '4. Privacy',
    body:
        'Profile and assessment data are used to calculate and display app results, and to link assessments with a participant code. The app can generate a random code, and location or farm details may be completed later in the research CSV/Excel file.',
    icon: Icons.privacy_tip_outlined,
  ),
  _TermsItem(
    title: '5. Copyright',
    body:
        'App content and assets belong to the project owner. Do not copy, modify, or redistribute them without permission, except for authorized project use.',
    icon: Icons.copyright_outlined,
  ),
];

class _TermsCard extends StatelessWidget {
  const _TermsCard({
    required this.item,
    required this.thai,
  });

  final _TermsItem item;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5EF),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: const TextStyle(height: 1.45, color: Colors.black87),
                  ),
                ],
              ),
            ),
            SooktaTtsButton(text: item.body, thai: thai, size: 38),
          ],
        ),
      ),
    );
  }
}
