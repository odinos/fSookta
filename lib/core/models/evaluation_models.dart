enum RiskLevel {
  low('ความเสี่ยงต่ำ', 0xFF4CAF50),
  medium('ความเสี่ยงปานกลาง', 0xFFFFC107),
  high('ความเสี่ยงสูง', 0xFFF44336),
  veryHigh('ความเสี่ยงสูงมาก', 0xFFB71C1C);

  const RiskLevel(this.label, this.colorHex);

  final String label;
  final int colorHex;
}

extension RiskLevelOrder on RiskLevel {
  bool operator >=(RiskLevel other) => index >= other.index;
}

enum BodyPart {
  neck,
  trunk,
  legs,
  arms,
  wrists,
}

enum JobType {
  lifting,
  pushPull,
  reba,
}

class ErgoInputData {
  const ErgoInputData({
    required this.jobType,
    this.gender = 'male',
    this.dailyIncome = 300,
    this.loadWeight = 0,
    this.horizontalDist = 25,
    this.verticalHeight = 75,
    this.liftFrequency = 0.2,
    this.durationHours = 1,
    this.transportDistance = 0,
    this.initialForce = 0,
    this.sustainForce = 0,
  });

  final JobType jobType;
  final String gender;
  final double dailyIncome;
  final double loadWeight;
  final double horizontalDist;
  final double verticalHeight;
  final double liftFrequency;
  final double durationHours;
  final double transportDistance;
  final double initialForce;
  final double sustainForce;
}

class RebaInputData {
  const RebaInputData({
    this.dailyIncome = 300,
    this.trunkScore = 1,
    this.neckScore = 1,
    this.legScore = 1,
    this.upperArmScore = 1,
    this.lowerArmScore = 1,
    this.wristScore = 1,
    this.loadScore = 0,
    this.couplingScore = 0,
    this.activityScore = 0,
  });

  final double dailyIncome;
  final int trunkScore;
  final int neckScore;
  final int legScore;
  final int upperArmScore;
  final int lowerArmScore;
  final int wristScore;
  final int loadScore;
  final int couplingScore;
  final int activityScore;

  RebaInputData copyWith({
    double? dailyIncome,
    int? trunkScore,
    int? neckScore,
    int? legScore,
    int? upperArmScore,
    int? lowerArmScore,
    int? wristScore,
    int? loadScore,
    int? couplingScore,
    int? activityScore,
  }) {
    return RebaInputData(
      dailyIncome: dailyIncome ?? this.dailyIncome,
      trunkScore: trunkScore ?? this.trunkScore,
      neckScore: neckScore ?? this.neckScore,
      legScore: legScore ?? this.legScore,
      upperArmScore: upperArmScore ?? this.upperArmScore,
      lowerArmScore: lowerArmScore ?? this.lowerArmScore,
      wristScore: wristScore ?? this.wristScore,
      loadScore: loadScore ?? this.loadScore,
      couplingScore: couplingScore ?? this.couplingScore,
      activityScore: activityScore ?? this.activityScore,
    );
  }
}

class ErgoResult {
  const ErgoResult({
    required this.riskLevel,
    required this.techScore,
    required this.userScore,
    required this.userScoreColor,
    required this.limitValue,
    required this.suggestionKey,
    this.economicLoss = 0,
    this.suggestionKeys = const [],
    this.bodyPartRisks = const {},
  });

  final RiskLevel riskLevel;
  final double techScore;
  final int userScore;
  final int userScoreColor;
  final double limitValue;
  final String suggestionKey;
  final int economicLoss;
  final List<String> suggestionKeys;
  final Map<BodyPart, RiskLevel> bodyPartRisks;
}
