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
    this.trunkTwist = false,
    this.trunkSideFlex = false,
    this.wristTwist = false,
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
  final bool trunkTwist;
  final bool trunkSideFlex;
  final bool wristTwist;
  final int loadScore;
  final int couplingScore;
  final int activityScore;

  int get adjustedTrunkScore =>
      trunkScore + (trunkTwist ? 1 : 0) + (trunkSideFlex ? 1 : 0);

  int get adjustedWristScore => wristScore + (wristTwist ? 1 : 0);

  RebaInputData copyWith({
    double? dailyIncome,
    int? trunkScore,
    int? neckScore,
    int? legScore,
    int? upperArmScore,
    int? lowerArmScore,
    int? wristScore,
    bool? trunkTwist,
    bool? trunkSideFlex,
    bool? wristTwist,
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
      trunkTwist: trunkTwist ?? this.trunkTwist,
      trunkSideFlex: trunkSideFlex ?? this.trunkSideFlex,
      wristTwist: wristTwist ?? this.wristTwist,
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
    this.aiRiskAlert,
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
  final AiRiskAlert? aiRiskAlert;

  ErgoResult copyWith({
    RiskLevel? riskLevel,
    double? techScore,
    int? userScore,
    int? userScoreColor,
    double? limitValue,
    String? suggestionKey,
    int? economicLoss,
    List<String>? suggestionKeys,
    Map<BodyPart, RiskLevel>? bodyPartRisks,
    AiRiskAlert? aiRiskAlert,
  }) {
    return ErgoResult(
      riskLevel: riskLevel ?? this.riskLevel,
      techScore: techScore ?? this.techScore,
      userScore: userScore ?? this.userScore,
      userScoreColor: userScoreColor ?? this.userScoreColor,
      limitValue: limitValue ?? this.limitValue,
      suggestionKey: suggestionKey ?? this.suggestionKey,
      economicLoss: economicLoss ?? this.economicLoss,
      suggestionKeys: suggestionKeys ?? this.suggestionKeys,
      bodyPartRisks: bodyPartRisks ?? this.bodyPartRisks,
      aiRiskAlert: aiRiskAlert ?? this.aiRiskAlert,
    );
  }
}

enum AiAlertLevel {
  low,
  watch,
  high,
  critical,
}

class AiFeatureImportance {
  const AiFeatureImportance({
    required this.key,
    required this.labelTh,
    required this.labelEn,
    required this.score,
  });

  final String key;
  final String labelTh;
  final String labelEn;
  final double score;

  String label({required bool thai}) => thai ? labelTh : labelEn;
}

class AiRiskAlert {
  const AiRiskAlert({
    required this.probability,
    required this.logisticProbability,
    required this.xgBoostProbability,
    required this.level,
    required this.modelVersion,
    required this.modelSource,
    required this.featureImportance,
  });

  final double probability;
  final double logisticProbability;
  final double xgBoostProbability;
  final AiAlertLevel level;
  final String modelVersion;
  final String modelSource;
  final List<AiFeatureImportance> featureImportance;

  bool get usesResearchTrainedModel => modelSource == 'research_trained';
}
