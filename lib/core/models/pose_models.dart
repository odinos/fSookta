class Point2D {
  const Point2D(this.x, this.y);

  final double x;
  final double y;
}

enum PoseLandmark {
  nose(0),
  leftEye(1),
  rightEye(2),
  leftEar(3),
  rightEar(4),
  leftShoulder(5),
  rightShoulder(6),
  leftElbow(7),
  rightElbow(8),
  leftWrist(9),
  rightWrist(10),
  leftHip(11),
  rightHip(12),
  leftKnee(13),
  rightKnee(14),
  leftAnkle(15),
  rightAnkle(16);

  const PoseLandmark(this.position);

  final int position;

  static PoseLandmark fromInt(int position) {
    return PoseLandmark.values.firstWhere(
      (landmark) => landmark.position == position,
      orElse: () => PoseLandmark.nose,
    );
  }
}

class KeyPoint {
  const KeyPoint({
    required this.bodyPart,
    required this.coordinate,
    required this.score,
  });

  final PoseLandmark bodyPart;
  final Point2D coordinate;
  final double score;
}

class Person {
  const Person({
    this.id = -1,
    required this.keyPoints,
    required this.score,
  });

  final int id;
  final List<KeyPoint> keyPoints;
  final double score;
}
