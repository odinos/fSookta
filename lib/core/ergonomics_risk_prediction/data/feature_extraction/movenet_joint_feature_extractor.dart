import '../../../models/pose_models.dart';
import '../../domain/entities/joint_feature_schema.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';

class MoveNetJointFeatureExtractor {
  const MoveNetJointFeatureExtractor(this.schema);

  final JointFeatureSchema schema;

  List<double> extract(Person person) {
    schema.validate();
    final keyPoints = {
      for (final point in person.keyPoints) point.bodyPart.position: point,
    };

    final features = <double>[];
    for (final landmark in PoseLandmark.values) {
      final keyPoint = keyPoints[landmark.position];
      if (keyPoint == null) {
        features.addAll([
          schema.missingValue,
          schema.missingValue,
          schema.missingValue,
        ]);
        continue;
      }

      // Data preprocessing before model inference:
      // MoveNet already emits normalized image coordinates in the range 0..1
      // and a confidence score in the range 0..1. We clip values defensively
      // so downstream Logistic Regression and ONNX XGBoost receive a stable
      // dense vector even when an image produces slightly out-of-range values.
      features
        ..add(_bounded(keyPoint.coordinate.x))
        ..add(_bounded(keyPoint.coordinate.y))
        ..add(_bounded(keyPoint.score));
    }

    if (features.length != schema.featureCount) {
      throw InvalidJointFeaturesException(
        'Extracted ${features.length} features but schema expects ${schema.featureCount}.',
      );
    }
    return features;
  }

  double _bounded(double value) {
    if (!value.isFinite) {
      throw const InvalidJointFeaturesException(
        'MoveNet keypoint values must be finite.',
      );
    }
    return value.clamp(0.0, 1.0).toDouble();
  }
}
