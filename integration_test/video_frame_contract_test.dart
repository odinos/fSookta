import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/services/video_frame_extraction_service.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VIDEO-CONTRACT-001 extracts equivalent portrait samples',
      (tester) async {
    const assetPath =
        'assets/test_fixtures/video/portrait_h264_4s.mp4';
    final bytes = await rootBundle.load(assetPath);
    final directory = await getTemporaryDirectory();
    final video = File('${directory.path}/sookta-video-contract.mp4');
    await video.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    addTearDown(() async {
      if (video.existsSync()) await video.delete();
    });

    const service = VideoFrameExtractionService();
    final result = await service.extractFrames(
      video.path,
      maxFrames: 4,
    );

    expect(result.durationMs, inInclusiveRange(4000, 9000));
    expect(result.framePaths, hasLength(4));
    expect(result.frameTimestampMs, hasLength(4));

    for (var index = 0; index < result.framePaths.length; index += 1) {
      final expected =
          (result.durationMs * (index + 1) / 5).round();
      expect(
        result.frameTimestampMs[index],
        closeTo(expected, 300),
      );

      final frame = img.decodeImage(
        await File(result.framePaths[index]).readAsBytes(),
      );
      expect(frame, isNotNull);
      expect(frame!.width, lessThanOrEqualTo(720));
      expect(frame.height, lessThanOrEqualTo(720));
      expect(frame.height, greaterThan(frame.width));
    }
  });
}
