import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/assets.dart';

class ManualDocumentService {
  const ManualDocumentService._();

  static Future<File> copyManualToTemporaryFile() async {
    final data = await rootBundle.load(SooktaAssets.userManualPdf);
    final directory = await getTemporaryDirectory();
    final file = File(p.join(directory.path, 'sookta_user_manual.pdf'));
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file;
  }

  static Future<void> openManual({required bool thai}) async {
    final file = await copyManualToTemporaryFile();
    await SharePlus.instance.share(
      ShareParams(
        title: thai ? 'คู่มือการใช้งาน Sookta' : 'Sookta User Manual',
        subject: thai ? 'คู่มือการใช้งาน Sookta' : 'Sookta User Manual',
        text: thai
            ? 'เปิดคู่มือการใช้งาน Sookta เพื่อดูขั้นตอนการใช้งานทุกหน้า'
            : 'Open the Sookta user manual for step-by-step app guidance.',
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }
}
