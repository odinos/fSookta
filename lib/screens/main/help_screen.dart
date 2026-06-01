import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
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
      thai ? 'คำแนะนำการใช้งานสุขท่า' : 'Sookta usage guide',
      ...steps.map((step) => '${step.title}. ${step.body}'),
      ...quickTips,
    ].join('. ');

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'ความช่วยเหลือ' : 'Help')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 760,
          children: [
            _HelpHeaderCard(
              thai: thai,
              ttsText: ttsText,
            ),
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
      ..._references,
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
                  children: _references
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

const _references = [
  'Hignett, S., & McAtamney, L. (2000). Rapid Entire Body Assessment (REBA). Applied Ergonomics, 31(2), 201–205.',
  'ISO 11228-1:2021 – Ergonomics – Manual handling – Part 1: Lifting, holding and carrying.',
  'ISO 11228-2:2007 – Ergonomics – Manual handling – Part 2: Pushing and pulling.',
  'ISO 11228-3:2007 – Ergonomics – Manual handling – Part 3: Handling of low loads at high frequency.',
  'International Labour Organization. (2014). Ergonomic Checkpoints in Agriculture (2nd ed.). ILO.',
  'Zadry, H.R., Kamil, M., & Saputra, N. (2025). Design and evaluation of a novel user-centred cassava extractor.',
];

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
    imageAsset: 'assets/images/male_01.png',
  ),
  _HelpStep(
    title: '2. เลือกกิจกรรมที่ทำจริง',
    body:
        'กดเริ่มทำแบบประเมิน แล้วเลือกกิจกรรม เช่น ปลูกกล้า ใส่ปุ๋ย ฉีดพ่น ตัดแต่งกิ่ง เก็บเกี่ยว หรือขนย้ายผลผลิต แอปจะเตรียมวิธีคำนวณที่เหมาะกับงานนั้นให้เอง',
    icon: Icons.grid_view_outlined,
    imageAsset: 'assets/images/img_transport.png',
  ),
  _HelpStep(
    title: '3. ถ่ายรูปหรือเลือกรูปท่าทาง',
    body:
        'ถ่ายให้เห็นคนทำงานทั้งตัวชัดที่สุด โดยเฉพาะศีรษะ หลัง แขน มือ และขา ถ่ายได้สูงสุด 4 รูป ระบบจะอ่านท่าทางจากภาพและตั้งค่าประเมินให้อัตโนมัติ',
    icon: Icons.camera_alt_outlined,
    imageAsset: 'assets/images/img_pruning.png',
  ),
  _HelpStep(
    title: '4. ตรวจข้อมูลก่อนดูผล',
    body:
        'ผู้ใช้ทั่วไปไม่จำเป็นต้องกรอกตัวเลขเอง ถ้าต้องการเก็บข้อมูลงานวิจัยให้ละเอียด เจ้าหน้าที่สามารถเปิดส่วนปรับรายละเอียดเพื่อใส่น้ำหนัก ระยะทาง ความถี่ ระยะเวลา หรือแรงดันลากได้',
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
    imageAsset: 'assets/images/img_harvesting.png',
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
    imageAsset: 'assets/images/male_01.png',
  ),
  _HelpStep(
    title: '2. Choose the real activity',
    body:
        'Tap Start Evaluation and choose the work activity, such as transplanting, fertilizing, spraying, pruning, harvesting, or produce transport. The app prepares the right assessment method for that task.',
    icon: Icons.grid_view_outlined,
    imageAsset: 'assets/images/img_transport.png',
  ),
  _HelpStep(
    title: '3. Take or choose posture photos',
    body:
        'Capture the worker as clearly as possible, especially the head, back, arms, hands, and legs. You can add up to 4 photos. The app reads posture from the images and prepares the assessment automatically.',
    icon: Icons.camera_alt_outlined,
    imageAsset: 'assets/images/img_pruning.png',
  ),
  _HelpStep(
    title: '4. Review before viewing results',
    body:
        'General users do not need to enter numbers manually. Research staff can open the detail section to record weight, distance, frequency, duration, or push/pull force when those values are available.',
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
    imageAsset: 'assets/images/img_harvesting.png',
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
                    thai ? 'ใช้สุขท่าอย่างไร' : 'How to Use Sookta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF214D3A),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    thai
                        ? 'ทำตามขั้นตอนสั้น ๆ นี้เพื่อประเมินท่าทาง ลดความเสี่ยง และส่งออกข้อมูลวิจัยได้ถูกต้อง'
                        : 'Follow these short steps to assess posture, reduce risk, and export research data correctly.',
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
    required this.compact,
  });

  final String imageAsset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: compact ? Alignment.center : Alignment.topRight,
      child: Container(
        width: compact ? double.infinity : 132,
        height: compact ? 128 : 116,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBF8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(imageAsset, fit: BoxFit.contain),
        ),
      ),
    );
  }
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
