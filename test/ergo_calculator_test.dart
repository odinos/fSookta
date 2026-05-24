import 'package:flutter_test/flutter_test.dart';
import 'package:fsookta/core/localization/sookta_strings.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/models/pose_models.dart';
import 'package:fsookta/core/services/ergo_calculator.dart';

void main() {
  group('REBA calculation parity', () {
    test('light work remains low risk', () {
      const input = RebaInputData(
        dailyIncome: 300,
        trunkScore: 3,
        neckScore: 1,
        legScore: 1,
        upperArmScore: 2,
        lowerArmScore: 1,
        wristScore: 1,
        loadScore: 0,
        couplingScore: 0,
        activityScore: 0,
      );

      final result = ErgoCalculator.calculateRebaRisk(input);

      expect(result.userScore, lessThanOrEqualTo(3));
      expect(result.riskLevel, RiskLevel.low);
      expect(result.economicLoss, 0);
    });

    test('heavy twist uses survey-based economic impact model', () {
      const input = RebaInputData(
        dailyIncome: 500,
        trunkScore: 5,
        neckScore: 2,
        legScore: 2,
        upperArmScore: 3,
        lowerArmScore: 2,
        wristScore: 2,
        loadScore: 2,
        couplingScore: 1,
        activityScore: 1,
      );

      final result = ErgoCalculator.calculateRebaRisk(input);

      expect(result.techScore, greaterThanOrEqualTo(8));
      expect(result.userScore, 9);
      expect({RiskLevel.high, RiskLevel.veryHigh}, contains(result.riskLevel));
      expect(result.economicLoss, 32244);
    });

    test('upper limb strain keeps medium/high risk behavior', () {
      const input = RebaInputData(
        dailyIncome: 300,
        trunkScore: 2,
        neckScore: 2,
        legScore: 1,
        upperArmScore: 4,
        lowerArmScore: 1,
        wristScore: 3,
        loadScore: 1,
        couplingScore: 1,
        activityScore: 1,
      );

      final result = ErgoCalculator.calculateRebaRisk(input);

      expect(result.techScore, greaterThanOrEqualTo(4));
      expect(result.userScore, greaterThanOrEqualTo(4));
      if (result.riskLevel == RiskLevel.medium) {
        expect(result.economicLoss, greaterThan(900));
      }
    });

    test('Notion ERGO twist and side flex adjustments raise trunk risk', () {
      const neutral = RebaInputData(
        trunkScore: 2,
        neckScore: 1,
        legScore: 1,
        upperArmScore: 1,
        lowerArmScore: 1,
        wristScore: 1,
      );
      const twisted = RebaInputData(
        trunkScore: 2,
        trunkTwist: true,
        trunkSideFlex: true,
        neckScore: 1,
        legScore: 1,
        upperArmScore: 1,
        lowerArmScore: 1,
        wristScore: 1,
      );

      final neutralResult = ErgoCalculator.calculateRebaRisk(neutral);
      final twistedResult = ErgoCalculator.calculateRebaRisk(twisted);

      expect(twisted.adjustedTrunkScore, neutral.trunkScore + 2);
      expect(twistedResult.techScore, greaterThan(neutralResult.techScore));
      expect(twistedResult.suggestionKeys, contains('act_avoid_twist'));
      expect(twistedResult.bodyPartRisks[BodyPart.trunk], RiskLevel.high);
    });

    test('Notion ERGO wrist twist adjustment raises wrist risk', () {
      const input = RebaInputData(
        trunkScore: 1,
        neckScore: 1,
        legScore: 1,
        upperArmScore: 1,
        lowerArmScore: 1,
        wristScore: 1,
        wristTwist: true,
      );

      final result = ErgoCalculator.calculateRebaRisk(input);

      expect(input.adjustedWristScore, 2);
      expect(result.suggestionKeys, contains('act_adj_wrist'));
      expect(result.bodyPartRisks[BodyPart.wrists], RiskLevel.high);
    });
  });

  group('ISO lifting and push/pull calculation parity', () {
    test('long transport distance adds localized cart suggestion key', () {
      const input = ErgoInputData(
        jobType: JobType.lifting,
        loadWeight: 20,
        transportDistance: 12,
      );

      final result = ErgoCalculator.calculateLiftingRisk(input);

      expect(result.suggestionKeys, contains('act_use_cart_distance'));
      expect(
        const SooktaStrings(SooktaLocale.th).get('act_use_cart_distance'),
        isNot('act_use_cart_distance'),
      );
    });

    test('push/pull over limit becomes high risk', () {
      const input = ErgoInputData(
        jobType: JobType.pushPull,
        initialForce: 30,
        sustainForce: 10,
      );

      final result = ErgoCalculator.calculatePushPullRisk(input);

      expect(result.riskLevel, RiskLevel.high);
      expect(result.suggestionKeys,
          containsAll(['act_check_wheels', 'act_use_legs']));
    });

    test('Notion ISO lifting multiplier floor keeps RWL in expected range', () {
      const input = ErgoInputData(
        jobType: JobType.lifting,
        gender: 'male',
        loadWeight: 20,
        horizontalDist: 80,
        verticalHeight: 0,
        liftFrequency: 10,
        transportDistance: 0,
      );

      final result = ErgoCalculator.calculateLiftingRisk(input);

      expect(result.limitValue, closeTo(25 * 0.7 * 0.775 * 0.5, 0.001));
      expect(result.techScore, closeTo(20 / result.limitValue, 0.001));
    });
  });

  test('activity-specific recommendation text is bundled in both languages',
      () {
    const th = SooktaStrings(SooktaLocale.th);
    const en = SooktaStrings(SooktaLocale.en);
    const keys = [
      'act_transplant_raise_bed',
      'act_transplant_low_stool',
      'act_spray_extension',
      'act_harvest_empty_often',
      'act_harvest_move_closer',
      'act_fert_split_load',
      'act_transport_two_person',
      'act_transport_clear_path',
    ];

    for (final key in keys) {
      expect(th.get(key), isNot(key));
      expect(en.get(key), isNot(key));
    }
  });

  test('pose landmarks can auto-fill REBA posture scores', () {
    const person = Person(
      score: 0.9,
      keyPoints: [
        KeyPoint(
          bodyPart: PoseLandmark.rightShoulder,
          coordinate: Point2D(0.5, 0.3),
          score: 0.9,
        ),
        KeyPoint(
          bodyPart: PoseLandmark.rightHip,
          coordinate: Point2D(0.5, 0.6),
          score: 0.9,
        ),
        KeyPoint(
          bodyPart: PoseLandmark.rightEar,
          coordinate: Point2D(0.5, 0.2),
          score: 0.9,
        ),
      ],
    );

    final result = ErgoCalculator.calculateRebaInputFromPose(
      person,
      const RebaInputData(trunkScore: 4, neckScore: 2),
    );

    expect(result.trunkScore, 1);
    expect(result.neckScore, 1);
  });
}
