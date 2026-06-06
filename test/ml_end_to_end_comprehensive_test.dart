import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/app/app_state.dart' as app;
import 'package:fsookta/core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart'
    as ml;
import 'package:fsookta/core/ergonomics_risk_prediction/data/models/logistic_regression_weights.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart' as eval;
import 'package:fsookta/core/models/pose_models.dart';
import 'package:fsookta/core/services/daily_injury_prediction_service.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';
import 'package:fsookta/core/services/pose_estimation_service.dart';
import 'package:fsookta/core/services/risk_alert_model_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ML-COMP feature schema and feature extraction', () {
    test('ML-001 canonical MoveNet schema is complete and ordered', () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();

      expect(schema.schemaId, 'movenet-thunder-v1-17x3-normalized');
      expect(schema.featureCount, 51);
      expect(schema.featureNames, hasLength(51));
      expect(schema.featureNames.first, 'nose_x');
      expect(schema.featureNames.last, 'rightAnkle_score');
    });

    test('ML-002 MoveNet extractor clamps coordinates and fills missing joints',
        () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();
      final extractor = ml.MoveNetJointFeatureExtractor(schema);

      const person = Person(
        score: 0.8,
        keyPoints: [
          KeyPoint(
            bodyPart: PoseLandmark.nose,
            coordinate: Point2D(-0.25, 1.25),
            score: 1.2,
          ),
          KeyPoint(
            bodyPart: PoseLandmark.rightAnkle,
            coordinate: Point2D(0.75, 0.8),
            score: 0.6,
          ),
        ],
      );

      final features = extractor.extract(person);

      expect(features, hasLength(51));
      expect(features.take(3), [0, 1, 1]);
      expect(features.skip(3).take(3), [0, 0, 0]);
      expect(features.skip(48).take(3), [0.75, 0.8, 0.6]);
    });
  });

  group('ML-COMP XGBoost ONNX predictor', () {
    test('ML-003 rejects inference before initModel()', () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();
      final predictor = ml.XGBoostOnnxPredictor(featureSchema: schema);

      expect(
        () => predictor.predictRiskLevel(_neutralMoveNetFeatures()),
        throwsA(isA<ml.ModelLoadException>()),
      );
    });

    test('ML-004 loads ONNX artifact when host runtime is available', () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();
      final predictor = ml.XGBoostOnnxPredictor(featureSchema: schema);
      var shouldDispose = false;
      addTearDown(() {
        if (shouldDispose) predictor.dispose();
      });

      try {
        await predictor.initModel();
        shouldDispose = true;
      } on ml.ModelLoadException catch (error) {
        expect(error.toString(), contains('libonnxruntime'));
        return;
      }
      await predictor.initModel();

      final neutral =
          await predictor.predictRiskLevel(_neutralMoveNetFeatures());
      final repeated =
          await predictor.predictRiskLevel(_neutralMoveNetFeatures());
      final bent = await predictor.predictRiskLevel(_deepBendMoveNetFeatures());

      expect(neutral.confidenceScore, inInclusiveRange(0, 1));
      expect(repeated.confidenceScore, closeTo(neutral.confidenceScore, 1e-9));
      expect(bent.confidenceScore, inInclusiveRange(0, 1));
      expect(bent.actionRecommendation, isNotEmpty);
    });

    test('ML-005 rejects malformed ONNX feature vectors', () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();
      final predictor = ml.XGBoostOnnxPredictor(featureSchema: schema);
      var shouldDispose = false;
      addTearDown(() {
        if (shouldDispose) predictor.dispose();
      });
      try {
        await predictor.initModel();
        shouldDispose = true;
      } on ml.ModelLoadException catch (error) {
        expect(error.toString(), contains('libonnxruntime'));
        return;
      }

      expect(
        () => predictor.predictRiskLevel(const []),
        throwsA(isA<ml.InvalidJointFeaturesException>()),
      );
      expect(
        () => predictor.predictRiskLevel(List<double>.filled(50, 0.5)),
        throwsA(isA<ml.InvalidJointFeaturesException>()),
      );
      expect(
        () => predictor.predictRiskLevel([
          ...List<double>.filled(50, 0.5),
          double.nan,
        ]),
        throwsA(isA<ml.InvalidJointFeaturesException>()),
      );
    });
  });

  group('ML-COMP Logistic Regression predictors', () {
    test('ML-006 canonical Logistic Regression asset predicts valid input',
        () async {
      final schema = await const ml.JointFeatureSchemaLoader().load();
      final predictor = ml.LogisticRegressionPredictor(featureSchema: schema);

      await predictor.initModel();
      final neutral =
          await predictor.predictRiskLevel(_neutralMoveNetFeatures());
      final bent = await predictor.predictRiskLevel(_deepBendMoveNetFeatures());

      expect(neutral.confidenceScore, inInclusiveRange(0, 1));
      expect(bent.confidenceScore, inInclusiveRange(0, 1));
      expect(neutral.actionRecommendation, isNotEmpty);
      expect(bent.actionRecommendation, isNotEmpty);
    });

    test('ML-007 controlled Logistic Regression covers all risk thresholds',
        () async {
      Future<ml.RiskLevel> levelForProbability(double probability) async {
        final predictor = ml.LogisticRegressionPredictor.fromWeights(
          LogisticRegressionWeights(
            version: 'threshold-test',
            featureSchemaId: 'test',
            modelSource: 'unit-test',
            intercept: _logit(probability),
            weights: const [0],
            thresholds: const ml.RiskThresholds(
                medium: 0.35, high: 0.6, veryHigh: 0.82),
          ),
        );
        final result = await predictor.predictRiskLevel([0]);
        return result.level;
      }

      expect(await levelForProbability(0.34), ml.RiskLevel.low);
      expect(await levelForProbability(0.35), ml.RiskLevel.medium);
      expect(await levelForProbability(0.6), ml.RiskLevel.high);
      expect(await levelForProbability(0.82), ml.RiskLevel.veryHigh);
    });

    test('ML-008 Logistic Regression rejects malformed input', () async {
      final predictor = ml.LogisticRegressionPredictor.fromWeights(
        const LogisticRegressionWeights(
          version: 'validation-test',
          featureSchemaId: 'test',
          modelSource: 'unit-test',
          intercept: 0,
          weights: [1, 1],
          thresholds: ml.RiskThresholds(),
        ),
      );

      expect(
        () => predictor.predictRiskLevel([1]),
        throwsA(isA<ml.InvalidJointFeaturesException>()),
      );
      expect(
        () => predictor.predictRiskLevel([1, double.infinity]),
        throwsA(isA<ml.InvalidJointFeaturesException>()),
      );
    });

    test(
        'ML-009 feature-engineered Logistic Regression expands 51 to 71 inputs',
        () async {
      final predictor = ml.LogisticRegressionPredictor.fromWeights(
        LogisticRegressionWeights(
          version: 'feature-engineering-test',
          featureSchemaId: 'test',
          modelSource: 'unit-test',
          inputFeatureCount: 51,
          featureEngineering: 'reba_angle_features_v1',
          intercept: 0,
          weights: List<double>.filled(71, 0.01),
          thresholds: const ml.RiskThresholds(),
          mean: List<double>.filled(71, 0),
          standardDeviation: List<double>.filled(71, 1),
        ),
      );

      final result =
          await predictor.predictRiskLevel(_neutralMoveNetFeatures());

      expect(result.confidenceScore, inInclusiveRange(0, 1));
    });
  });

  group('ML-COMP Daily Logistic Regression 7-transaction predictor', () {
    test('ML-010 returns insufficient for zero to six transactions', () {
      final service = _dailyServiceAtProbability(0.9);

      for (var count = 0; count < 7; count += 1) {
        final prediction = service.predictForRecords([
          for (var day = 1; day <= count; day++) _record(day, score: 6),
        ]);

        expect(prediction.hasEnoughData, isFalse);
        expect(prediction.usedTransactions, count);
        expect(prediction.level, DailyInjuryPredictionLevel.insufficient);
      }
    });

    test('ML-011 controlled daily model covers low/watch/high/critical levels',
        () {
      final records = [for (var day = 1; day <= 7; day++) _record(day)];

      expect(
        _dailyServiceAtProbability(0.44).predictForRecords(records).level,
        DailyInjuryPredictionLevel.low,
      );
      expect(
        _dailyServiceAtProbability(0.46).predictForRecords(records).level,
        DailyInjuryPredictionLevel.watch,
      );
      expect(
        _dailyServiceAtProbability(0.66).predictForRecords(records).level,
        DailyInjuryPredictionLevel.high,
      );
      expect(
        _dailyServiceAtProbability(0.83).predictForRecords(records).level,
        DailyInjuryPredictionLevel.critical,
      );
    });

    test('ML-012 daily predictor sorts records and uses only latest seven', () {
      final service = _dailyServiceAtProbability(0.5);
      final records = [
        _record(8, score: 8),
        _record(1, score: 9),
        for (var day = 2; day <= 7; day++) _record(day, score: day),
      ];

      final prediction = service.predictForRecords(records);

      expect(prediction.hasEnoughData, isTrue);
      expect(prediction.chartScores, [2, 3, 4, 5, 6, 7, 8]);
      expect(prediction.windowStart, DateTime(2026, 6, 2));
      expect(prediction.windowEnd, DateTime(2026, 6, 8));
    });

    test('ML-013 actual daily asset flags repeated high trunk-risk history',
        () async {
      final service = await DailyInjuryPredictionService.load();
      final prediction = service.predictForRecords([
        for (var day = 1; day <= 7; day++)
          _record(
            day,
            score: 9,
            afterScore: 8,
            risk: eval.RiskLevel.high,
            bodyPartRisks: const {eval.BodyPart.trunk: eval.RiskLevel.high},
            economicLoss: 20000,
          ),
      ]);

      expect(prediction.hasEnoughData, isTrue);
      expect(prediction.probability, inInclusiveRange(0, 1));
      expect(prediction.requiresCareAlert, isTrue);
      expect(prediction.featureValues, contains('trunk_high_days_norm'));
    });
  });

  group('ML-COMP REBA/ISO guardrail and pose-derived inputs', () {
    test(
        'ML-014 risk alert model returns bounded probabilities for all job types',
        () async {
      final model = await RiskAlertModelService.load();
      final cases =
          <eval.JobType, ({eval.ErgoInputData ergo, eval.RebaInputData reba})>{
        eval.JobType.reba: (
          ergo: const eval.ErgoInputData(jobType: eval.JobType.reba),
          reba: _highRebaInput(),
        ),
        eval.JobType.lifting: (
          ergo: const eval.ErgoInputData(
            jobType: eval.JobType.lifting,
            loadWeight: 20,
            horizontalDist: 55,
            verticalHeight: 25,
            liftFrequency: 6.5,
            durationHours: 4,
            transportDistance: 8,
          ),
          reba: _highRebaInput(),
        ),
        eval.JobType.pushPull: (
          ergo: const eval.ErgoInputData(
            jobType: eval.JobType.pushPull,
            initialForce: 40,
            sustainForce: 24,
            durationHours: 8,
          ),
          reba: _highRebaInput(),
        ),
      };

      for (final entry in cases.entries) {
        final result = switch (entry.key) {
          eval.JobType.reba =>
            ErgoCalculator.calculateRebaRisk(entry.value.reba),
          eval.JobType.lifting =>
            ErgoCalculator.calculateLiftingRisk(entry.value.ergo),
          eval.JobType.pushPull =>
            ErgoCalculator.calculatePushPullRisk(entry.value.ergo),
        };
        final alert = model.predict(
          jobType: entry.key,
          result: result,
          ergoInput: entry.value.ergo,
          rebaInput: entry.value.reba,
        );

        expect(alert.probability, inInclusiveRange(0, 1));
        expect(alert.logisticProbability, inInclusiveRange(0, 1));
        expect(alert.xgBoostProbability, inInclusiveRange(0, 1));
        expect(alert.featureImportance, isNotEmpty);
      }
    });

    test(
        'ML-015 deep bending pose maps to trunk risk and relevant recommendation',
        () {
      final input = ErgoCalculator.calculateRebaInputFromPose(
        _deepBendingPerson(),
        const eval.RebaInputData(activityScore: 1),
      );
      final result = ErgoCalculator.calculateRebaRisk(input);

      expect(input.trunkScore, 4);
      expect(input.neckScore, 2);
      expect(result.bodyPartRisks[eval.BodyPart.trunk], eval.RiskLevel.high);
      expect(result.suggestionKeys, contains('act_avoid_bend'));
    });

    test('ML-016 combined REBA and ISO keeps the higher real-task risk', () {
      final reba = ErgoCalculator.calculateRebaRisk(_highRebaInput());
      final iso = ErgoCalculator.calculateLiftingRisk(
        const eval.ErgoInputData(
          jobType: eval.JobType.lifting,
          dailyIncome: 500,
          loadWeight: 25,
          horizontalDist: 65,
          verticalHeight: 15,
          liftFrequency: 6.5,
          durationHours: 8,
          transportDistance: 12,
        ),
      );
      final combined = ErgoCalculator.calculateCombinedRebaIsoRisk(
        rebaResult: reba,
        isoResult: iso,
        dailyIncome: 500,
      );

      expect(
          combined.riskLevel.index, greaterThanOrEqualTo(reba.riskLevel.index));
      expect(
          combined.riskLevel.index, greaterThanOrEqualTo(iso.riskLevel.index));
    });

    test('ML-017 lifting dimension estimator handles usable and missing poses',
        () {
      final service = PoseEstimationService();
      addTearDown(service.dispose);

      final dimensions = service.estimateLiftingDimensions(
        PoseEstimate(
          person: _liftingPerson(),
          imageWidth: 1080,
          imageHeight: 1440,
        ),
      );
      final missing = service.estimateLiftingDimensions(
        const PoseEstimate(
          person: Person(score: 0.1, keyPoints: []),
          imageWidth: 1080,
          imageHeight: 1440,
        ),
      );

      expect(dimensions, isNotNull);
      expect(dimensions!.horizontalCm, inInclusiveRange(25, 65));
      expect(dimensions.verticalCm, inInclusiveRange(0, 175));
      expect(missing, isNull);
    });

    test('ML-018 invalid image bytes return no pose estimate', () async {
      final service = PoseEstimationService();
      addTearDown(service.dispose);
      final file = File(
        '${Directory.systemTemp.path}/sookta-invalid-pose-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      await file.writeAsString('not an image');

      final estimate = await service.estimatePoseFromFile(file.path);

      expect(estimate, isNull);
    });
  });
}

List<double> _neutralMoveNetFeatures() {
  final values = List<double>.filled(51, 0);
  for (var index = 0; index < values.length; index += 3) {
    values[index] = 0.5;
    values[index + 1] = 0.5;
    values[index + 2] = 0.9;
  }
  return values;
}

List<double> _deepBendMoveNetFeatures() {
  final values = _neutralMoveNetFeatures();
  void setPoint(int landmarkIndex, double x, double y, double score) {
    final offset = landmarkIndex * 3;
    values[offset] = x;
    values[offset + 1] = y;
    values[offset + 2] = score;
  }

  setPoint(PoseLandmark.leftShoulder.position, 0.82, 0.63, 0.95);
  setPoint(PoseLandmark.rightShoulder.position, 0.84, 0.65, 0.95);
  setPoint(PoseLandmark.leftHip.position, 0.35, 0.62, 0.95);
  setPoint(PoseLandmark.rightHip.position, 0.38, 0.64, 0.95);
  setPoint(PoseLandmark.leftEar.position, 0.92, 0.72, 0.9);
  setPoint(PoseLandmark.leftElbow.position, 0.72, 0.78, 0.9);
  setPoint(PoseLandmark.leftWrist.position, 0.66, 0.9, 0.9);
  setPoint(PoseLandmark.leftKnee.position, 0.36, 0.82, 0.9);
  setPoint(PoseLandmark.leftAnkle.position, 0.34, 0.98, 0.9);
  return values;
}

eval.RebaInputData _highRebaInput() {
  return const eval.RebaInputData(
    dailyIncome: 500,
    trunkScore: 4,
    neckScore: 2,
    legScore: 2,
    upperArmScore: 4,
    lowerArmScore: 2,
    wristScore: 2,
    trunkTwist: true,
    trunkSideFlex: true,
    wristTwist: true,
    loadScore: 2,
    couplingScore: 1,
    activityScore: 2,
  );
}

Person _deepBendingPerson() {
  return const Person(
    score: 0.9,
    keyPoints: [
      KeyPoint(
        bodyPart: PoseLandmark.leftHip,
        coordinate: Point2D(0.35, 0.62),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.rightHip,
        coordinate: Point2D(0.38, 0.64),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftShoulder,
        coordinate: Point2D(0.82, 0.63),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.rightShoulder,
        coordinate: Point2D(0.84, 0.65),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftEar,
        coordinate: Point2D(0.92, 0.72),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftElbow,
        coordinate: Point2D(0.72, 0.78),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftWrist,
        coordinate: Point2D(0.66, 0.9),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftKnee,
        coordinate: Point2D(0.36, 0.82),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.leftAnkle,
        coordinate: Point2D(0.34, 0.98),
        score: 0.9,
      ),
    ],
  );
}

Person _liftingPerson() {
  return const Person(
    score: 0.9,
    keyPoints: [
      KeyPoint(
        bodyPart: PoseLandmark.rightShoulder,
        coordinate: Point2D(0.52, 0.28),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.rightHip,
        coordinate: Point2D(0.5, 0.55),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.rightWrist,
        coordinate: Point2D(0.62, 0.72),
        score: 0.9,
      ),
      KeyPoint(
        bodyPart: PoseLandmark.rightAnkle,
        coordinate: Point2D(0.48, 0.92),
        score: 0.9,
      ),
    ],
  );
}

DailyInjuryPredictionService _dailyServiceAtProbability(double probability) {
  return DailyInjuryPredictionService.fromJson({
    'version': 'unit-threshold-test',
    'source': 'unit-test',
    'minTransactions': 7,
    'thresholds': {
      'watch': 0.45,
      'high': 0.65,
      'critical': 0.82,
    },
    'logisticRegression': {
      'intercept': _logit(probability),
      'coefficients': <String, double>{},
    },
  });
}

double _logit(double probability) {
  return math.log(probability / (1 - probability));
}

app.EvaluationHistoryRecord _record(
  int day, {
  int score = 5,
  int? afterScore,
  eval.RiskLevel risk = eval.RiskLevel.medium,
  Map<eval.BodyPart, eval.RiskLevel> bodyPartRisks = const {},
  int economicLoss = 0,
}) {
  return app.EvaluationHistoryRecord(
    id: day,
    farmerProfileId: 'farmer-1',
    farmerId: 'FSK-001',
    farmerName: 'Test Farmer',
    activity: SooktaActivity.transplanting,
    activityName: 'Transplanting',
    dateTime: DateTime(2026, 6, day),
    scoreBefore: score,
    scoreAfter: afterScore ?? (score - 1).clamp(1, 9).toInt(),
    riskBefore: risk,
    riskAfter: risk,
    economicLoss: economicLoss,
    moneySaved: 0,
    selectedSuggestions: const [],
    bodyPartRisks: bodyPartRisks,
  );
}
