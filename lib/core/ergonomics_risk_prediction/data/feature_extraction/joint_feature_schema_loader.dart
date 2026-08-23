import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/joint_feature_schema.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';

class JointFeatureSchemaLoader {
  const JointFeatureSchemaLoader({
    this.assetPath = 'assets/models/joint_feature_schema.json',
  });

  final String assetPath;

  Future<JointFeatureSchema> load() async {
    try {
      final jsonText = await rootBundle.loadString(assetPath);
      final schema = JointFeatureSchema.fromJson(
        Map<String, Object?>.from(jsonDecode(jsonText) as Map),
      );
      schema.validate();
      return schema;
    } catch (error, stackTrace) {
      throw ModelLoadException(
        'Failed to load joint feature schema from $assetPath.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
