import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalImageStore {
  const LocalImageStore._();

  static Future<String> saveImageFile(
    String sourcePath, {
    String prefix = 'sookta_image',
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) return sourcePath;

    final directory = await getApplicationDocumentsDirectory();
    final extension =
        p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final fileName =
        '${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File(p.join(directory.path, fileName));
    final copied = await source.copy(destination.path);
    return copied.path;
  }
}
