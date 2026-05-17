import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../../domain/entities/risk_assessment_result.dart';
import '../../domain/exceptions/risk_prediction_exception.dart';
import '../../domain/predictors/ergonomic_risk_predictor.dart';

class XGBoostOnnxPredictor implements ErgonomicRiskPredictor {
  XGBoostOnnxPredictor({
    this.assetPath = 'assets/models/xgboost_model.onnx',
    this.inputName = 'input',
    this.outputNames,
    this.thresholds = const RiskThresholds(),
  });

  final String assetPath;
  final String inputName;
  final List<String>? outputNames;
  final RiskThresholds thresholds;

  OrtSession? _session;

  @override
  Future<void> initModel() async {
    if (_session != null) return;

    try {
      OrtEnv.instance.init();
      final rawAssetFile = await rootBundle.load(assetPath);
      final bytes = rawAssetFile.buffer.asUint8List(
        rawAssetFile.offsetInBytes,
        rawAssetFile.lengthInBytes,
      );
      final sessionOptions = OrtSessionOptions();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
    } catch (error, stackTrace) {
      throw ModelLoadException(
        'Failed to load XGBoost ONNX model from $assetPath.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<RiskAssessmentResult> predictRiskLevel(
    List<double> jointFeatures,
  ) async {
    final session = _session;
    if (session == null) {
      throw const ModelLoadException(
        'XGBoost ONNX model is not initialized. Call initModel() first.',
      );
    }

    OrtValueTensor? inputTensor;
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;

    try {
      final features = _preprocessJointFeatures(jointFeatures);
      inputTensor = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(features),
        [1, features.length],
      );
      runOptions = OrtRunOptions();
      final outputFuture = session.runAsync(
        runOptions,
        {inputName: inputTensor},
        outputNames,
      );
      if (outputFuture == null) {
        throw const ModelInferenceException(
          'ONNX runtime did not return an inference future.',
        );
      }

      outputs = await outputFuture;
      final probability = _probabilityFromOutputs(outputs);
      return RiskAssessmentResult.fromProbability(
        probability,
        thresholds: thresholds,
      );
    } on RiskPredictionException {
      rethrow;
    } catch (error, stackTrace) {
      throw ModelInferenceException(
        'XGBoost ONNX inference failed.',
        cause: error,
        stackTrace: stackTrace,
      );
    } finally {
      inputTensor?.release();
      runOptions?.release();
      outputs?.forEach((output) => output?.release());
    }
  }

  List<double> _preprocessJointFeatures(List<double> jointFeatures) {
    if (jointFeatures.isEmpty) {
      throw const InvalidJointFeaturesException(
        'Joint features must not be empty.',
      );
    }

    // ONNX models expect a dense Float32 tensor. This step validates the MoveNet
    // joint feature vector and converts every value to a finite double before
    // packing it as a [1, featureCount] tensor for on-device inference.
    return jointFeatures.map((value) {
      if (!value.isFinite) {
        throw const InvalidJointFeaturesException(
          'Joint features must contain finite numeric values only.',
        );
      }
      return value;
    }).toList(growable: false);
  }

  double _probabilityFromOutputs(List<OrtValue?> outputs) {
    final numbers = <double>[];
    for (final output in outputs) {
      if (output is OrtValueTensor) {
        _collectNumbers(output.value, numbers);
      }
    }
    if (numbers.isEmpty) {
      throw const ModelInferenceException(
        'ONNX output does not contain numeric probabilities.',
      );
    }

    final rawProbability = numbers.length >= 2 ? numbers[1] : numbers.first;
    if (rawProbability >= 0 && rawProbability <= 1) {
      return rawProbability;
    }
    return 1 / (1 + math.exp(-rawProbability));
  }

  void _collectNumbers(Object? value, List<double> output) {
    if (value is num) {
      output.add(value.toDouble());
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        _collectNumbers(item, output);
      }
    }
  }

  void dispose() {
    _session?.release();
    _session = null;
    OrtEnv.instance.release();
  }
}
