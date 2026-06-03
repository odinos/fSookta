import 'dart:math' as math;

import '../models/evaluation_models.dart';
import '../models/pose_models.dart';
import 'economic_impact_service.dart';

class ErgoCalculator {
  const ErgoCalculator._();

  static const _userScoreColors = <int>[
    0xFF8BC34A,
    0xFF9CCC65,
    0xFFAED581,
    0xFFDCE775,
    0xFFFFF176,
    0xFFFFD54F,
    0xFFFFB74D,
    0xFFFF8A65,
    0xFFFF5252,
  ];

  static const _refMassMale = 25.0;
  static const _refMassFemale = 20.0;
  static const _minIsoMultiplier = 0.7;
  static const _minFrequencyMultiplier = 0.5;
  static const _thaiMinWage = 350.0;

  static RebaInputData calculateRebaInputFromPose(
    Person person,
    RebaInputData currentData,
  ) {
    Point2D? point(PoseLandmark landmark) {
      for (final keyPoint in person.keyPoints) {
        if (keyPoint.bodyPart == landmark && keyPoint.score > 0.3) {
          return keyPoint.coordinate;
        }
      }
      return null;
    }

    final ear = point(PoseLandmark.rightEar) ?? point(PoseLandmark.leftEar);
    final shoulder =
        point(PoseLandmark.rightShoulder) ?? point(PoseLandmark.leftShoulder);
    final hip = point(PoseLandmark.rightHip) ?? point(PoseLandmark.leftHip);
    final knee = point(PoseLandmark.rightKnee) ?? point(PoseLandmark.leftKnee);
    final elbow =
        point(PoseLandmark.rightElbow) ?? point(PoseLandmark.leftElbow);
    final wrist =
        point(PoseLandmark.rightWrist) ?? point(PoseLandmark.leftWrist);
    final ankle =
        point(PoseLandmark.rightAnkle) ?? point(PoseLandmark.leftAnkle);

    var newTrunk = currentData.trunkScore;
    var newNeck = currentData.neckScore;
    var newUpperArm = currentData.upperArmScore;
    var newLowerArm = currentData.lowerArmScore;
    var newLeg = currentData.legScore;

    if (shoulder != null && hip != null) {
      final angle = _verticalAngle(hip, shoulder);
      newTrunk = switch (angle) {
        <= 5 => 1,
        <= 20 => 2,
        <= 60 => 3,
        _ => 4,
      };
    }

    if (ear != null && shoulder != null) {
      final angle = _verticalAngle(shoulder, ear);
      newNeck = angle <= 20 ? 1 : 2;
    }

    if (shoulder != null && elbow != null) {
      final angle = _verticalAngle(shoulder, elbow);
      newUpperArm = switch (angle) {
        <= 20 => 1,
        <= 45 => 2,
        <= 90 => 3,
        _ => 4,
      };
    }

    if (shoulder != null && elbow != null && wrist != null) {
      final angle = _threePointAngle(shoulder, elbow, wrist);
      newLowerArm = angle >= 60 && angle <= 100 ? 1 : 2;
    }

    if (hip != null && knee != null && ankle != null) {
      final kneeAngle = _threePointAngle(hip, knee, ankle);
      newLeg = kneeAngle < 150 ? 2 : 1;
    }

    return currentData.copyWith(
      trunkScore: newTrunk,
      neckScore: newNeck,
      upperArmScore: newUpperArm,
      lowerArmScore: newLowerArm,
      legScore: newLeg,
    );
  }

  static ErgoResult calculateLiftingRisk(ErgoInputData data) {
    final isFemale = data.gender.toLowerCase() == 'female';
    final refMass = isFemale ? _refMassFemale : _refMassMale;
    final h = math.max(data.horizontalDist, 25.0);
    final hm = (25.0 / h).clamp(_minIsoMultiplier, 1.0).toDouble();
    final vm = (1.0 - (0.003 * (data.verticalHeight - 75.0).abs()))
        .clamp(_minIsoMultiplier, 1.0)
        .toDouble();

    final fm = switch (data.liftFrequency) {
      <= 0.2 => 1.0,
      <= 1.0 => 0.94,
      <= 4.0 => 0.84,
      <= 6.0 => 0.75,
      _ => _minFrequencyMultiplier,
    };

    final dm = switch (data.transportDistance) {
      <= 2.0 => 1.0,
      <= 10.0 => 0.85,
      <= 20.0 => 0.75,
      _ => 0.6,
    };

    final rwl = refMass * vm * hm * fm * dm;
    final li = rwl > 0 ? data.loadWeight / rwl : 99.0;
    final userScore = _mapLiToUserScore(li);
    final risk = _mapLiToRiskLevel(li);
    final suggestionKeys = <String>[
      if (risk >= RiskLevel.medium) 'act_reduce_weight',
      if (data.horizontalDist > 40.0) 'act_iso_keep_load_close',
      if (data.verticalHeight < 50.0 || data.verticalHeight > 120.0)
        'act_iso_lift_height',
      if (data.liftFrequency > 4.0 || data.durationHours >= 4.0)
        'act_iso_reduce_frequency',
      if (risk >= RiskLevel.medium) 'act_iso_improve_grip',
      if (data.liftFrequency > 1.0 || data.durationHours >= 2.0)
        'act_iso_plan_recovery',
      if (data.transportDistance > 10.0) 'act_use_cart_distance',
    ];

    final bodyPartRisks = {BodyPart.trunk: risk};

    return ErgoResult(
      riskLevel: risk,
      techScore: li,
      userScore: userScore,
      userScoreColor: _colorForScore(userScore),
      limitValue: rwl,
      suggestionKey: risk == RiskLevel.low ? 'sugg_safe' : 'sugg_improve',
      economicLoss: _calculateHybridEconomicLoss(
        risk,
        data.dailyIncome,
        bodyPartRisks,
      ),
      suggestionKeys: suggestionKeys,
      bodyPartRisks: bodyPartRisks,
    );
  }

  static ErgoResult calculatePushPullRisk(ErgoInputData data) {
    final isFemale = data.gender.toLowerCase() == 'female';
    final limitInitial = isFemale ? 20.0 : 25.0;
    final limitSustain = isFemale ? 12.0 : 15.0;
    final riskScore = math.max(
      data.initialForce / limitInitial,
      data.sustainForce / limitSustain,
    );
    final userScore = _mapRatioToUserScore(riskScore);
    final risk = _mapRatioToRiskLevel(riskScore);

    final suggestionKey = switch (risk) {
      RiskLevel.low => 'sugg_force_ok',
      RiskLevel.medium => 'sugg_force_warn',
      RiskLevel.high => 'sugg_force_danger',
      RiskLevel.veryHigh => 'sugg_force_ok',
    };

    final bodyPartRisks = {BodyPart.arms: risk, BodyPart.trunk: risk};

    return ErgoResult(
      riskLevel: risk,
      techScore: riskScore,
      userScore: userScore,
      userScoreColor: _colorForScore(userScore),
      limitValue: limitInitial,
      suggestionKey: suggestionKey,
      economicLoss: _calculateHybridEconomicLoss(
        risk,
        data.dailyIncome,
        bodyPartRisks,
      ),
      suggestionKeys: [
        if (risk >= RiskLevel.medium) ...[
          'act_check_wheels',
          'act_use_legs',
          'act_iso_push_smooth',
          'act_iso_push_handle_height',
          'act_iso_floor_level',
        ],
        if (data.transportDistance > 10.0) 'act_iso_reduce_push_distance',
        if (risk >= RiskLevel.high) 'act_iso_push_not_pull',
      ],
      bodyPartRisks: bodyPartRisks,
    );
  }

  static ErgoResult calculateRebaRisk(RebaInputData input) {
    final adjustedTrunkScore = input.adjustedTrunkScore;
    final adjustedWristScore = input.adjustedWristScore;
    final scoreTableA = _rebaTableAScore(
      adjustedTrunkScore,
      input.neckScore,
      input.legScore,
    );
    final scoreA = scoreTableA + input.loadScore;
    final scoreTableB = _rebaTableBScore(
      input.upperArmScore,
      input.lowerArmScore,
      adjustedWristScore,
    );
    final scoreB = scoreTableB + input.couplingScore;
    final scoreC = _rebaTableCScore(scoreA, scoreB);
    final finalScore = _applyRebaSafetyFloors(
      scoreC + input.activityScore,
      input,
      adjustedTrunkScore: adjustedTrunkScore,
      adjustedWristScore: adjustedWristScore,
    );
    final userScore = _mapRebaToUserScore(finalScore);
    final risk = _mapRebaToRiskLevel(finalScore);

    final suggestionKeys = <String>[
      if (input.loadScore >= 1) 'act_reduce_load_tool',
      if (adjustedTrunkScore >= 3) 'act_avoid_bend',
      if (input.trunkTwist || input.trunkSideFlex) 'act_avoid_twist',
      if (input.neckScore >= 2) 'act_adj_eye_level',
      if (input.upperArmScore >= 3) 'act_reduce_arm_raise',
      if (adjustedWristScore >= 2) 'act_adj_wrist',
      if (input.activityScore >= 1) ...[
        'act_iso_plan_recovery',
        'act_iso_job_rotation',
      ],
      if (input.upperArmScore >= 3 || adjustedWristScore >= 2)
        'act_iso_neutral_reach',
      if (adjustedWristScore >= 2 || input.couplingScore >= 1)
        'act_iso_tool_handle_fit',
    ];
    if (suggestionKeys.isEmpty && risk != RiskLevel.low) {
      suggestionKeys.add('act_rest_stretch');
    }

    final suggestionKey = switch (risk) {
      RiskLevel.low => 'sugg_reba_low',
      RiskLevel.medium => 'sugg_reba_med',
      RiskLevel.high => 'sugg_reba_high',
      RiskLevel.veryHigh => 'sugg_reba_vhigh',
    };

    final bodyPartRisks = {
      BodyPart.trunk: _partRisk(adjustedTrunkScore, 4),
      BodyPart.neck: _partRisk(input.neckScore, 2),
      BodyPart.legs: _partRisk(input.legScore, 2),
      BodyPart.arms: _partRisk(
        math.max(input.upperArmScore, input.lowerArmScore),
        3,
      ),
      BodyPart.wrists: _partRisk(adjustedWristScore, 2),
    };

    return ErgoResult(
      riskLevel: risk,
      techScore: finalScore.toDouble(),
      userScore: userScore,
      userScoreColor: _colorForScore(userScore),
      limitValue: 15,
      suggestionKey: suggestionKey,
      economicLoss: _calculateHybridEconomicLoss(
        risk,
        input.dailyIncome,
        bodyPartRisks,
      ),
      suggestionKeys: suggestionKeys,
      bodyPartRisks: bodyPartRisks,
    );
  }

  static ErgoResult calculateCombinedRebaIsoRisk({
    required ErgoResult rebaResult,
    required ErgoResult isoResult,
    required double dailyIncome,
  }) {
    final combinedRisk = rebaResult.riskLevel.index >= isoResult.riskLevel.index
        ? rebaResult.riskLevel
        : isoResult.riskLevel;
    final combinedScore = math.max(rebaResult.userScore, isoResult.userScore);
    final combinedBodyRisks = <BodyPart, RiskLevel>{
      ...rebaResult.bodyPartRisks
    };
    for (final entry in isoResult.bodyPartRisks.entries) {
      final current = combinedBodyRisks[entry.key];
      if (current == null || entry.value.index > current.index) {
        combinedBodyRisks[entry.key] = entry.value;
      }
    }
    final suggestionKeys = <String>{
      ...rebaResult.suggestionKeys,
      ...isoResult.suggestionKeys,
    }.toList(growable: false);

    return ErgoResult(
      riskLevel: combinedRisk,
      techScore: combinedScore.toDouble(),
      userScore: combinedScore,
      userScoreColor: _colorForScore(combinedScore),
      limitValue: isoResult.limitValue,
      suggestionKey:
          combinedRisk == RiskLevel.low ? 'sugg_safe' : 'sugg_improve',
      economicLoss: _calculateHybridEconomicLoss(
        combinedRisk,
        dailyIncome,
        combinedBodyRisks,
      ),
      suggestionKeys: suggestionKeys,
      bodyPartRisks: combinedBodyRisks,
    );
  }

  static int _mapLiToUserScore(double li) => switch (li) {
        <= 0.5 => 1,
        <= 0.75 => 2,
        <= 1.0 => 3,
        <= 1.5 => 4,
        <= 2.0 => 5,
        <= 3.0 => 6,
        <= 4.0 => 7,
        <= 5.0 => 8,
        _ => 9,
      };

  static RiskLevel _mapLiToRiskLevel(double li) {
    if (li <= 1.0) return RiskLevel.low;
    if (li <= 3.0) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static int _mapRatioToUserScore(double ratio) => switch (ratio) {
        <= 0.4 => 1,
        <= 0.6 => 2,
        < 0.8 => 3,
        <= 0.9 => 4,
        <= 1.0 => 5,
        <= 1.2 => 6,
        <= 1.5 => 7,
        <= 2.0 => 8,
        _ => 9,
      };

  static RiskLevel _mapRatioToRiskLevel(double ratio) {
    if (ratio > 1.0) return RiskLevel.high;
    if (ratio >= 0.8) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static int _mapRebaToUserScore(int score) => switch (score) {
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 4,
        5 => 5,
        6 || 7 => 6,
        8 => 7,
        9 || 10 => 8,
        _ => 9,
      };

  static RiskLevel _mapRebaToRiskLevel(int score) {
    if (score <= 3) return RiskLevel.low;
    if (score <= 7) return RiskLevel.medium;
    if (score <= 10) return RiskLevel.high;
    return RiskLevel.veryHigh;
  }

  static int _applyRebaSafetyFloors(
    int score,
    RebaInputData input, {
    required int adjustedTrunkScore,
    required int adjustedWristScore,
  }) {
    var calibrated = score;
    final severeTrunkFlexion = adjustedTrunkScore >= 4;
    final neckFlexion = input.neckScore >= 2;
    final nonNeutralLegs = input.legScore >= 2;
    final repetitiveOrStatic = input.activityScore >= 1;
    final upperLimbDemand = input.upperArmScore >= 2 ||
        input.lowerArmScore >= 2 ||
        adjustedWristScore >= 2;

    // Field photos can show a very deep bend while some secondary REBA
    // modifiers remain unknown. Do not let a severe forward-bending posture
    // be reported as low/medium simply because load, coupling, twist, or
    // repetition were not manually entered.
    if (severeTrunkFlexion && neckFlexion && repetitiveOrStatic) {
      calibrated = math.max(calibrated, 9);
    } else if (severeTrunkFlexion &&
        (neckFlexion ||
            repetitiveOrStatic ||
            nonNeutralLegs ||
            upperLimbDemand)) {
      calibrated = math.max(calibrated, 8);
    } else if (severeTrunkFlexion) {
      calibrated = math.max(calibrated, 6);
    }

    if (adjustedTrunkScore >= 3 &&
        neckFlexion &&
        repetitiveOrStatic &&
        upperLimbDemand) {
      calibrated = math.max(calibrated, 8);
    }

    return calibrated.clamp(1, 12).toInt();
  }

  static int _colorForScore(int score) {
    return _userScoreColors[(score - 1).clamp(0, 8).toInt()];
  }

  static int _calculateHybridEconomicLoss(
    RiskLevel risk,
    double dailyIncome,
    Map<BodyPart, RiskLevel> bodyPartRisks,
  ) {
    final impact = EconomicImpactService.estimate(
      overallRisk: risk,
      dailyIncome: dailyIncome > 0 ? dailyIncome : _thaiMinWage,
      bodyPartRisks: bodyPartRisks,
    );
    return impact.totalCost;
  }

  static RiskLevel _partRisk(int score, int highThreshold) {
    if (score >= highThreshold) return RiskLevel.high;
    if (score >= highThreshold - 1) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static int _rebaTableAScore(int trunk, int neck, int leg) {
    var score = trunk + (neck >= 2 ? 1 : 0) + (leg >= 2 ? 1 : 0);
    if (trunk >= 4 && neck >= 3) score += 1;
    return math.min(score, 9);
  }

  static int _rebaTableBScore(int upper, int lower, int wrist) {
    var score = upper;
    if (lower >= 2) score += 1;
    if (wrist >= 2) score += 1;
    if (upper >= 4 && wrist >= 3) score += 1;
    return math.min(score, 9);
  }

  static int _rebaTableCScore(int scoreA, int scoreB) {
    final maxScore = math.max(scoreA, scoreB);
    final minScore = math.min(scoreA, scoreB);
    var score = maxScore;
    if (minScore >= 6) score += 1;
    return math.min(score, 12);
  }

  static double _verticalAngle(Point2D p1, Point2D p2) {
    final dx = p2.x - p1.x;
    final dy = p1.y - p2.y;
    return math.atan2(dx.abs(), dy.abs()) * 180 / math.pi;
  }

  static double _threePointAngle(Point2D p1, Point2D p2, Point2D p3) {
    final a1 = math.atan2(p1.y - p2.y, p1.x - p2.x);
    final a2 = math.atan2(p3.y - p2.y, p3.x - p2.x);
    var angle = (a1 - a2) * 180 / math.pi;
    if (angle < 0) angle += 360;
    if (angle > 180) angle = 360 - angle;
    return angle;
  }
}
