import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/services/firebase_telemetry_service.dart';
import '../../core/services/training_data_export_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';

class TrainingDataExportScreen extends StatefulWidget {
  const TrainingDataExportScreen({super.key});

  static const routeName = '/training-data-export';

  @override
  State<TrainingDataExportScreen> createState() =>
      _TrainingDataExportScreenState();
}

class _TrainingDataExportScreenState extends State<TrainingDataExportScreen> {
  var exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final records = state.history;
    final dailyRows = TrainingDataExportService.dailyLogisticWindowCount(
      records,
    );
    final xgbRows = TrainingDataExportService.xGBoostPoseRowCount(records);
    final hasHistory = records.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          thai ? 'ส่งออกข้อมูลสำหรับเทรนโมเดล' : 'Export Training Data',
        ),
      ),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 680,
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(thai: thai),
            const SizedBox(height: 12),
            _TrainingFileCard(
              icon: Icons.timeline_outlined,
              title: thai
                  ? 'Logistic Regression: ประวัติครบ 7 transaction'
                  : 'Logistic Regression: 7-transaction windows',
              description: thai
                  ? 'ไฟล์นี้รวม feature จากผลประเมิน 7 ครั้งล่าสุดของชาวสวนแต่ละคน ทีมวิจัยเติม outcome label ภายหลัง เช่น ต้องรักษาหรือไม่ แล้วนำไป train โมเดลทำนายรายวัน'
                  : 'This file groups each farmer into 7-assessment windows. Researchers fill outcome labels later, such as whether treatment was required, then use it to train the daily prediction model.',
              rowCount: dailyRows,
              rowLabel: thai ? 'windows พร้อมส่งออก' : 'windows ready',
            ),
            const SizedBox(height: 12),
            _TrainingFileCard(
              icon: Icons.accessibility_new_outlined,
              title: thai
                  ? 'XGBoost/ONNX: ท่าทางและ MoveNet features'
                  : 'XGBoost/ONNX: posture and MoveNet features',
              description: thai
                  ? 'ไฟล์นี้รวมข้อมูลท่าทางรายภาพและ raw MoveNet 51 features สำหรับประวัติที่สร้างหลังรุ่นนี้ ทีมวิจัยสามารถเติมคะแนน REBA/ISO จริงเพื่อเทรนโมเดลประเมินท่าทางรอบต่อไป'
                  : 'This file contains per-photo posture rows and raw 51-value MoveNet features for records created after this version. Researchers can add expert REBA/ISO labels for the next posture-model training round.',
              rowCount: xgbRows,
              rowLabel: thai ? 'pose rows พร้อมส่งออก' : 'pose rows ready',
            ),
            const SizedBox(height: 12),
            _SafetyNote(thai: thai),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: !hasHistory || exporting
                  ? null
                  : () => _exportTrainingFiles(context, thai),
              icon: exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_outlined),
              label: Text(
                exporting
                    ? (thai ? 'กำลังสร้างไฟล์...' : 'Creating files...')
                    : (thai ? 'ส่งออกไฟล์สำหรับเทรน' : 'Export training files'),
              ),
            ),
            if (!hasHistory) ...[
              const SizedBox(height: 10),
              Text(
                thai
                    ? 'ยังไม่มีประวัติการประเมิน กรุณาประเมินอย่างน้อย 1 ครั้งก่อนส่งออก'
                    : 'No assessment history yet. Run at least one assessment before exporting.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportTrainingFiles(BuildContext context, bool thai) async {
    final shareOrigin = _shareOrigin(context);
    setState(() => exporting = true);
    try {
      final state = AppStateScope.of(context);
      final bundle = await TrainingDataExportService.exportTrainingFiles(
        records: state.history,
        profilesByRecordId: {
          for (final record in state.history)
            record.id: state.profileForRecord(record),
        },
        thai: thai,
      );
      await FirebaseTelemetryService.logExportCreated(
        exportType: 'training_dataset_csv_bundle',
        recordCount: state.history.length,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: thai ? 'ไฟล์ข้อมูลสำหรับเทรน Sookta' : 'Sookta training data',
          subject:
              thai ? 'ไฟล์ข้อมูลสำหรับเทรน Sookta' : 'Sookta training data',
          text: thai
              ? 'ไฟล์ CSV สำหรับทีมวิจัยใช้เติม label และนำไป train โมเดลรอบต่อไป'
              : 'CSV files for researchers to label and train the next model round.',
          files: [
            XFile(bundle.dailyLogisticFile.path, mimeType: 'text/csv'),
            XFile(bundle.xgBoostFile.path, mimeType: 'text/csv'),
          ],
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'สร้างไฟล์แล้ว: Logistic ${bundle.dailyLogisticRows} แถว, XGBoost ${bundle.xgBoostRows} แถว'
                : 'Files created: Logistic ${bundle.dailyLogisticRows} rows, XGBoost ${bundle.xgBoostRows} rows',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังส่งออกไฟล์ไม่ได้ กรุณาลองใหม่อีกครั้ง'
                : 'Could not export training files. Please try again.',
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(
                Icons.science_outlined,
                color: SooktaColors.darkGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              thai
                  ? 'ไฟล์นี้ใช้ขอข้อมูลเพื่อเทรนโมเดลรอบต่อไป'
                  : 'Use this to collect data for the next training round',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'แอปจะสร้าง CSV 2 ไฟล์จากประวัติที่บันทึกไว้ เจ้าหน้าที่หรือทีมวิจัยสามารถนำไปเติม label ตรวจสอบคุณภาพ และใช้ train Logistic Regression หรือ XGBoost ต่อได้'
                  : 'The app creates two CSV files from saved history. Research staff can fill labels, review quality, and use them to retrain Logistic Regression or XGBoost.',
              style: const TextStyle(color: Colors.black87, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingFileCard extends StatelessWidget {
  const _TrainingFileCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.rowCount,
    required this.rowLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final int rowCount;
  final String rowLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SooktaColors.darkGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black54, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$rowCount $rowLabel',
                    style: const TextStyle(
                      color: SooktaColors.darkGreen,
                      fontWeight: FontWeight.w700,
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

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF8A6D00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thai
                    ? 'ข้อมูลและผลประเมินใช้เพื่อสื่อสารความเสี่ยง การเรียนรู้ และงานวิจัยเท่านั้น ไม่ใช่การวินิจฉัยทางการแพทย์หรือการยืนยันการบาดเจ็บ'
                    : 'Assessment data supports risk communication, learning, and research only. It is not medical diagnosis or injury confirmation.',
                style: const TextStyle(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
