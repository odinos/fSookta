import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/pose_models.dart';

class PoseEstimate {
  const PoseEstimate({
    required this.person,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Person person;
  final int imageWidth;
  final int imageHeight;
}

class LiftingDimensions {
  const LiftingDimensions({
    required this.horizontalCm,
    required this.verticalCm,
  });

  final double horizontalCm;
  final double verticalCm;
}

class PoseEstimationService {
  Interpreter? _interpreter;

  static const _inputSize = 256;
  static const _landmarkCount = 17;

  Future<PoseEstimate?> estimatePoseFromFile(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final interpreter = await _ensureInterpreter();
    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = _buildInput(resized, interpreter.getInputTensor(0).type);
    final output = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(_landmarkCount, (_) => List<double>.filled(3, 0)),
      ),
    );

    interpreter.run(input, output);
    final person = _personFromOutput(output[0][0]);
    if (person.score <= 0.2) return null;

    return PoseEstimate(
      person: person,
      imageWidth: decoded.width,
      imageHeight: decoded.height,
    );
  }

  LiftingDimensions? estimateLiftingDimensions(PoseEstimate estimate) {
    Point2D? point(PoseLandmark landmark) {
      for (final keyPoint in estimate.person.keyPoints) {
        if (keyPoint.bodyPart == landmark && keyPoint.score > 0.3) {
          return keyPoint.coordinate;
        }
      }
      return null;
    }

    final shoulder =
        point(PoseLandmark.rightShoulder) ?? point(PoseLandmark.leftShoulder);
    final hip = point(PoseLandmark.rightHip) ?? point(PoseLandmark.leftHip);
    final wrist =
        point(PoseLandmark.rightWrist) ?? point(PoseLandmark.leftWrist);
    final ankle =
        point(PoseLandmark.rightAnkle) ?? point(PoseLandmark.leftAnkle);
    if (shoulder == null || hip == null || wrist == null || ankle == null) {
      return null;
    }

    final torsoDistance = _distance(shoulder, hip);
    if (torsoDistance <= 0) return null;

    const torsoLengthCm = 53.0;
    final normalizedUnitsPerCm = torsoDistance / torsoLengthCm;
    final horizontalCm =
        ((wrist.x - ankle.x).abs() / normalizedUnitsPerCm).clamp(25.0, 65.0);
    final verticalCm =
        ((ankle.y - wrist.y) / normalizedUnitsPerCm).clamp(0.0, 175.0);

    return LiftingDimensions(
      horizontalCm: horizontalCm,
      verticalCm: verticalCm,
    );
  }

  Future<Interpreter> _ensureInterpreter() async {
    final existing = _interpreter;
    if (existing != null) return existing;

    final options = InterpreterOptions()..threads = 4;
    final interpreter = await Interpreter.fromAsset(
      'assets/ml/movenet_thunder.tflite',
      options: options,
    );
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
                blue.toDouble()
              ];
            }
            return <int>[red, green, blue];
          },
        ),
      ),
    );
  }

  Person _personFromOutput(List<List<double>> keyPointsData) {
    final keyPoints = <KeyPoint>[];
    var totalScore = 0.0;

    for (var i = 0; i < keyPointsData.length; i++) {
      final y = keyPointsData[i][0];
      final x = keyPointsData[i][1];
      final score = keyPointsData[i][2];
      keyPoints.add(
        KeyPoint(
          bodyPart: PoseLandmark.fromInt(i),
          coordinate: Point2D(x, y),
          score: score,
        ),
      );
      totalScore += score;
    }

    return Person(
      id: 0,
      keyPoints: keyPoints,
      score: totalScore / keyPoints.length,
    );
  }

  double _distance(Point2D a, Point2D b) {
    return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
