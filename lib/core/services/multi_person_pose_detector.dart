import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'pose_image_preprocessor.dart';

class MultiPersonPoseDetector {
  Interpreter? _interpreter;

  static const _inputSize = 256;
  static const _maxPeople = 6;
  static const _valuesPerPose = 56;
  static const _personScoreIndex = 55;
  static const defaultConfidenceThreshold = 0.3;

  Future<int?> countPeopleFromFile(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final interpreter = await _ensureInterpreter();
    final resized = letterboxPoseImage(decoded, size: _inputSize);
    final input = _buildInput(resized, interpreter.getInputTensor(0).type);
    final output = List.generate(
      1,
      (_) => List.generate(
        _maxPeople,
        (_) => List<double>.filled(_valuesPerPose, 0),
      ),
    );

    interpreter.run(input, output);
    return countConfidentPeople(output.first);
  }

  static int countConfidentPeople(
    List<List<double>> poses, {
    double confidenceThreshold = defaultConfidenceThreshold,
  }) {
    return poses.where((pose) {
      return pose.length > _personScoreIndex &&
          pose[_personScoreIndex] >= confidenceThreshold;
    }).length;
  }

  static bool requiresSinglePersonReplacement(int personCount) {
    return personCount != 1;
  }

  Future<Interpreter> _ensureInterpreter() async {
    final existing = _interpreter;
    if (existing != null) return existing;

    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(
      'assets/ml/movenet_multipose_lightning.tflite',
      options: options,
    );
    interpreter.resizeInputTensor(0, [1, _inputSize, _inputSize, 3]);
    interpreter.allocateTensors();
    _interpreter = interpreter;
    return interpreter;
  }

  Object _buildInput(img.Image image, TensorType type) {
    final wantsFloat = type == TensorType.float32;
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            final red = pixel.r.toInt();
            final green = pixel.g.toInt();
            final blue = pixel.b.toInt();
            if (wantsFloat) {
              return <double>[
                red.toDouble(),
                green.toDouble(),
                blue.toDouble(),
              ];
            }
            return <int>[red, green, blue];
          },
        ),
      ),
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
