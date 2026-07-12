import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fsookta/core/services/multi_person_pose_detector.dart';

void main() {
  test('bundled multipose model asset is present and non-empty', () {
    final model = File('assets/ml/movenet_multipose_lightning.tflite');

    expect(model.existsSync(), isTrue);
    expect(model.lengthSync(), greaterThan(8 * 1024 * 1024));
  });

  test('counts only poses above the person confidence threshold', () {
    final output = List.generate(
      6,
      (index) => List<double>.filled(56, 0),
    );
    output[0][55] = 0.92;
    output[1][55] = 0.71;
    output[2][55] = 0.19;

    expect(
      MultiPersonPoseDetector.countConfidentPeople(
        output,
        confidenceThreshold: 0.3,
      ),
      2,
    );
  });

  test('requires replacement when more than one person is detected', () {
    expect(MultiPersonPoseDetector.requiresSinglePersonReplacement(0), isTrue);
    expect(MultiPersonPoseDetector.requiresSinglePersonReplacement(1), isFalse);
    expect(MultiPersonPoseDetector.requiresSinglePersonReplacement(2), isTrue);
  });
}
