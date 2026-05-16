import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const routeName = '/help';

  @override
  Widget build(BuildContext context) {
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
        AppLanguage.th;
    final items = thai
        ? const [
            (
              '1. วิธีเริ่มประเมิน',
              'ไปที่หน้าแรก กดเริ่มทำแบบประเมิน แล้วเลือกกิจกรรมเกษตรที่ต้องการตรวจสอบ'
            ),
            (
              '2. การถ่ายภาพ',
              'ถ่ายภาพด้านข้างให้เห็นศีรษะ หลัง แขน และขาชัดเจนเพื่อให้ AI ประเมินได้ดี'
            ),
            (
              '3. การกรอกข้อมูล',
              'ระบุน้ำหนัก ความถี่ ระยะเวลา และแรงที่ใช้ตามความเป็นจริง'
            ),
            (
              '4. การอ่านผล',
              'เขียวคือเสี่ยงต่ำ เหลืองคือควรปรับปรุง แดงคือควรแก้ไขโดยเร็ว'
            ),
            (
              '5. ประวัติ',
              'ดูผลประเมินย้อนหลังและความสูญเสียที่ลดลงได้ในเมนูผลตรวจ'
            ),
          ]
        : const [
            (
              '1. How to start',
              'Open Home, tap Start Evaluation, and choose a farming activity.'
            ),
            (
              '2. Taking photos',
              'Use side-view photos that clearly show head, back, arms, and legs.'
            ),
            (
              '3. Entering data',
              'Enter weight, frequency, duration, and force values as accurately as possible.'
            ),
            (
              '4. Reading results',
              'Green is low risk, yellow needs improvement, and red needs fast action.'
            ),
            (
              '5. History',
              'Open History to review saved assessments and potential savings.'
            ),
          ];
    return _InfoListScreen(
      title: thai ? 'ความช่วยเหลือ' : 'Help',
      subtitle: thai ? 'คำแนะนำการใช้งาน' : 'Usage Guide',
      items: items,
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
    final items = thai
        ? const [
            (
              '1. บทนำ',
              'การใช้งานแอปสุขท่าถือว่าผู้ใช้ยอมรับข้อกำหนดและเงื่อนไขเหล่านี้'
            ),
            (
              '2. วัตถุประสงค์',
              'แอปใช้ประเมินความเสี่ยงทางการยศาสตร์เบื้องต้นสำหรับเกษตรกร'
            ),
            (
              '3. ข้อควรระวัง',
              'ผลประเมินเป็นคำแนะนำเบื้องต้น ไม่ใช่การวินิจฉัยทางการแพทย์'
            ),
            (
              '4. ข้อมูลส่วนบุคคล',
              'ข้อมูลโปรไฟล์และประวัติใช้เพื่อคำนวณและแสดงผลภายในแอป'
            ),
            (
              '5. ลิขสิทธิ์',
              'เนื้อหาและองค์ประกอบของแอปเป็นของผู้พัฒนาโครงการ'
            ),
          ]
        : const [
            (
              '1. Introduction',
              'Using Sookta means you accept these terms and conditions.'
            ),
            (
              '2. Purpose',
              'The app provides preliminary ergonomic risk assessment for farmers.'
            ),
            (
              '3. Disclaimer',
              'Results are recommendations only and not medical diagnosis.'
            ),
            (
              '4. Privacy',
              'Profile and assessment data are used to calculate and display app results.'
            ),
            (
              '5. Copyright',
              'App content and assets belong to the project owner.'
            ),
          ];
    return _InfoListScreen(
      title: thai ? 'ข้อกำหนดและเงื่อนไข' : 'Terms and Conditions',
      subtitle: thai
          ? 'กรุณาอ่านและยอมรับเงื่อนไข'
          : 'Please read and accept the terms',
      items: items,
    );
  }
}

class _InfoListScreen extends StatelessWidget {
  const _InfoListScreen({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Card(
                child: ListTile(
                  leading: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(item.$2)),
                      );
                    },
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                  title: Text(item.$1,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.$2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
