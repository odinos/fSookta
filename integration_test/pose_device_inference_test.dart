import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fsookta/core/services/pose_estimation_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('POSE-DEVICE-001 loads MoveNet TFLite runtime on device',
      (tester) async {
    final tempDir = await getTemporaryDirectory();
    final imageFile = File(
      '${tempDir.path}/sookta-pose-device-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    addTearDown(() {
      if (imageFile.existsSync()) {
        imageFile.deleteSync();
      }
    });

    final image = img.Image(width: 256, height: 256);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));
    imageFile.writeAsBytesSync(img.encodeJpg(image));

    final service = PoseEstimationService();
    addTearDown(service.dispose);

    final estimate = await service.estimatePoseFromFile(imageFile.path);

    // A blank image may legitimately return no person, but reaching this line
    // proves that the platform TFLite C symbols were loaded and inference ran.
    // ignore: avoid_print
    print(
      'POSE_DEVICE_RESULT: '
      'platform=${Platform.operatingSystem} '
      'estimate=${estimate == null ? 'none' : estimate.person.score.toStringAsFixed(4)}',
    );
  });
}
