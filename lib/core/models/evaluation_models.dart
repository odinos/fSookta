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

enum AssessmentMethod {
  rebaIsoCombined,
  reba,
  iso11228Lifting,
  iso11228PushPull,
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
    this.workDaysPerWeek = 3,
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
  final double workDaysPerWeek;
  final double transportDistance;
  final double initialForce;
  final double sustainForce;

  Map<String, Object?> toJson() {
    return {
      'jobType': jobType.name,
      'gender': gender,
      'dailyIncome': dailyIncome,
      'loadWeight': loadWeight,
      'horizontalDist': horizontalDist,
      'verticalHeight': verticalHeight,
      'liftFrequency': liftFrequency,
      'durationHours': durationHours,
      'workDaysPerWeek': workDaysPerWeek,
      'transportDistance': transportDistance,
      'initialForce': initialForce,
      'sustainForce': sustainForce,
    };
  }

  factory ErgoInputData.fromJson(Map<String, Object?> json) {
    return ErgoInputData(
      jobType: _jobTypeFromName(json['jobType'] as String?),
      gender: json['gender'] as String? ?? 'male',
      dailyIncome: _asDouble(json['dailyIncome'], 300),
      loadWeight: _asDouble(json['loadWeight'], 0),
      horizontalDist: _asDouble(json['horizontalDist'], 25),
      verticalHeight: _asDouble(json['verticalHeight'], 75),
      liftFrequency: _asDouble(json['liftFrequency'], 0.2),
      durationHours: _asDouble(json['durationHours'], 1),
      workDaysPerWeek: _asDouble(json['workDaysPerWeek'], 3),
      transportDistance: _asDouble(json['transportDistance'], 0),
      initialForce: _asDouble(json['initialForce'], 0),
      sustainForce: _asDouble(json['sustainForce'], 0),
    );
  }
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

  Map<String, Object?> toJson() {
    return {
      'dailyIncome': dailyIncome,
      'trunkScore': trunkScore,
      'neckScore': neckScore,
      'legScore': legScore,
      'upperArmScore': upperArmScore,
      'lowerArmScore': lowerArmScore,
      'wristScore': wristScore,
      'trunkTwist': trunkTwist,
      'trunkSideFlex': trunkSideFlex,
      'wristTwist': wristTwist,
      'loadScore': loadScore,
      'couplingScore': couplingScore,
      'activityScore': activityScore,
    };
  }

  factory RebaInputData.fromJson(Map<String, Object?> json) {
    return RebaInputData(
      dailyIncome: _asDouble(json['dailyIncome'], 300),
      trunkScore: _asInt(json['trunkScore'], 1),
      neckScore: _asInt(json['neckScore'], 1),
      legScore: _asInt(json['legScore'], 1),
      upperArmScore: _asInt(json['upperArmScore'], 1),
      lowerArmScore: _asInt(json['lowerArmScore'], 1),
      wristScore: _asInt(json['wristScore'], 1),
      trunkTwist: json['trunkTwist'] as bool? ?? false,
      trunkSideFlex: json['trunkSideFlex'] as bool? ?? false,
      wristTwist: json['wristTwist'] as bool? ?? false,
      loadScore: _asInt(json['loadScore'], 0),
      couplingScore: _asInt(json['couplingScore'], 0),
      activityScore: _asInt(json['activityScore'], 0),
    );
  }
}

class PoseRebaFrameAnalysis {
  const PoseRebaFrameAnalysis({
    required this.imageIndex,
    required this.rebaInput,
    required this.rebaScore,
    required this.riskLevel,
    this.neckFlexionDeg,
    this.trunkFlexionDeg,
    this.upperArmFlexionDeg,
    this.lowerArmAngleDeg,
    this.kneeAngleDeg,
    this.neckSideBending = false,
    this.neckTwisting = false,
    this.trunkSideBending = false,
    this.trunkTwisting = false,
    this.upperArmAbduction = false,
    this.shoulderElevation = false,
    this.jointFeatures = const [],
  });

  final int imageIndex;
  final RebaInputData rebaInput;
  final int rebaScore;
  final RiskLevel riskLevel;
  final double? neckFlexionDeg;
  final double? trunkFlexionDeg;
  final double? upperArmFlexionDeg;
  final double? lowerArmAngleDeg;
  final double? kneeAngleDeg;
  final bool neckSideBending;
  final bool neckTwisting;
  final bool trunkSideBending;
  final bool trunkTwisting;
  final bool upperArmAbduction;
  final bool shoulderElevation;
  final List<double> jointFeatures;

  Map<String, Object?> toJson() {
    return {
      'imageIndex': imageIndex,
      'rebaInput': rebaInput.toJson(),
      'rebaScore': rebaScore,
      'riskLevel': riskLevel.name,
      'neckFlexionDeg': neckFlexionDeg,
      'trunkFlexionDeg': trunkFlexionDeg,
      'upperArmFlexionDeg': upperArmFlexionDeg,
      'lowerArmAngleDeg': lowerArmAngleDeg,
      'kneeAngleDeg': kneeAngleDeg,
      'neckSideBending': neckSideBending,
      'neckTwisting': neckTwisting,
      'trunkSideBending': trunkSideBending,
      'trunkTwisting': trunkTwisting,
      'upperArmAbduction': upperArmAbduction,
      'shoulderElevation': shoulderElevation,
      'jointFeatures': jointFeatures,
    };
  }

  factory PoseRebaFrameAnalysis.fromJson(Map<String, Object?> json) {
    return PoseRebaFrameAnalysis(
      imageIndex: _asInt(json['imageIndex'], 1),
      rebaInput: _inputFromJson(
        json['rebaInput'],
        RebaInputData.fromJson,
        const RebaInputData(),
      ),
      rebaScore: _asInt(json['rebaScore'], 1),
      riskLevel: _riskFromName(json['riskLevel'] as String?),
      neckFlexionDeg: _nullableDouble(json['neckFlexionDeg']),
      trunkFlexionDeg: _nullableDouble(json['trunkFlexionDeg']),
      upperArmFlexionDeg: _nullableDouble(json['upperArmFlexionDeg']),
      lowerArmAngleDeg: _nullableDouble(json['lowerArmAngleDeg']),
      kneeAngleDeg: _nullableDouble(json['kneeAngleDeg']),
      neckSideBending: _asBool(json['neckSideBending']),
      neckTwisting: _asBool(json['neckTwisting']),
      trunkSideBending: _asBool(json['trunkSideBending']),
      trunkTwisting: _asBool(json['trunkTwisting']),
      upperArmAbduction: _asBool(json['upperArmAbduction']),
      shoulderElevation: _asBool(json['shoulderElevation']),
      jointFeatures: (json['jointFeatures'] as List?)
              ?.map((value) => _asDouble(value, 0))
              .toList(growable: false) ??
          const [],
    );
  }
}

class RebaScoreBreakdown {
  const RebaScoreBreakdown({
    required this.adjustedTrunkScore,
    required this.adjustedWristScore,
    required this.tableAScore,
    required this.scoreA,
    required this.tableBScore,
    required this.scoreB,
    required this.scoreC,
    required this.activityScore,
    required this.finalScore,
    required this.riskLevel,
  });

  final int adjustedTrunkScore;
  final int adjustedWristScore;
  final int tableAScore;
  final int scoreA;
  final int tableBScore;
  final int scoreB;
  final int scoreC;
  final int activityScore;
  final int finalScore;
  final RiskLevel riskLevel;
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

class AssessmentBreakdown {
  const AssessmentBreakdown({
    required this.primaryMethod,
    required this.rebaInput,
    required this.rebaResult,
    required this.ergoInput,
    this.isoMethod,
    this.isoResult,
    this.poseFrames = const [],
    this.worstPoseImageIndex,
  });

  final AssessmentMethod primaryMethod;
  final RebaInputData rebaInput;
  final ErgoResult rebaResult;
  final ErgoInputData ergoInput;
  final AssessmentMethod? isoMethod;
  final ErgoResult? isoResult;
  final List<PoseRebaFrameAnalysis> poseFrames;
  final int? worstPoseImageIndex;

  Map<String, Object?> toJson() {
    return {
      'primaryMethod': primaryMethod.name,
      'rebaInput': rebaInput.toJson(),
      'rebaResult': _resultToJson(rebaResult),
      'ergoInput': ergoInput.toJson(),
      'isoMethod': isoMethod?.name,
      'isoResult': isoResult == null ? null : _resultToJson(isoResult!),
      'poseFrames': poseFrames.map((frame) => frame.toJson()).toList(),
      'worstPoseImageIndex': worstPoseImageIndex,
    };
  }

  factory AssessmentBreakdown.fromJson(Map<String, Object?> json) {
    return AssessmentBreakdown(
      primaryMethod: _methodFromName(json['primaryMethod'] as String?),
      rebaInput: _inputFromJson(
        json['rebaInput'],
        RebaInputData.fromJson,
        const RebaInputData(),
      ),
      rebaResult: _resultFromJson(json['rebaResult']),
      ergoInput: _inputFromJson(
        json['ergoInput'],
        ErgoInputData.fromJson,
        const ErgoInputData(jobType: JobType.reba),
      ),
      isoMethod: _nullableMethodFromName(json['isoMethod'] as String?),
      isoResult:
          json['isoResult'] is Map ? _resultFromJson(json['isoResult']) : null,
      poseFrames: (json['poseFrames'] as List?)
              ?.whereType<Map>()
              .map((item) => PoseRebaFrameAnalysis.fromJson(
                    Map<String, Object?>.from(item),
                  ))
              .toList() ??
          const [],
      worstPoseImageIndex: json['worstPoseImageIndex'] is num
          ? (json['worstPoseImageIndex'] as num).toInt()
          : null,
    );
  }

  static Map<String, Object?> _resultToJson(ErgoResult result) {
    return {
      'riskLevel': result.riskLevel.name,
      'techScore': result.techScore,
      'userScore': result.userScore,
      'userScoreColor': result.userScoreColor,
      'limitValue': result.limitValue,
      'suggestionKey': result.suggestionKey,
      'economicLoss': result.economicLoss,
    };
  }

  static ErgoResult _resultFromJson(Object? raw) {
    if (raw is! Map) {
      return const ErgoResult(
        riskLevel: RiskLevel.low,
        techScore: 0,
        userScore: 0,
        userScoreColor: 0xFF4CAF50,
        limitValue: 0,
        suggestionKey: '',
      );
    }
    final json = Map<String, Object?>.from(raw);
    final riskLevel = _riskFromName(json['riskLevel'] as String?);
    return ErgoResult(
      riskLevel: riskLevel,
      techScore: _asDouble(json['techScore'], 0),
      userScore: _asInt(json['userScore'], 0),
      userScoreColor: _asInt(json['userScoreColor'], riskLevel.colorHex),
      limitValue: _asDouble(json['limitValue'], 0),
      suggestionKey: json['suggestionKey'] as String? ?? '',
      economicLoss: _asInt(json['economicLoss'], 0),
    );
  }
}

T _inputFromJson<T>(
  Object? raw,
  T Function(Map<String, Object?> json) fromJson,
  T fallback,
) {
  if (raw is! Map) return fallback;
  return fromJson(Map<String, Object?>.from(raw));
}

double _asDouble(Object? raw, double fallback) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? fallback;
}

double? _nullableDouble(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '');
}

int _asInt(Object? raw, int fallback) {
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? fallback;
}

bool _asBool(Object? raw) {
  if (raw is bool) return raw;
  if (raw is String) return raw.toLowerCase() == 'true';
  return false;
}

JobType _jobTypeFromName(String? name) {
  return JobType.values.firstWhere(
    (jobType) => jobType.name == name,
    orElse: () => JobType.reba,
  );
}

RiskLevel _riskFromName(String? name) {
  return RiskLevel.values.firstWhere(
    (risk) => risk.name == name,
    orElse: () => RiskLevel.low,
  );
}

AssessmentMethod _methodFromName(String? name) {
  return AssessmentMethod.values.firstWhere(
    (method) => method.name == name,
    orElse: () => AssessmentMethod.reba,
  );
}

AssessmentMethod? _nullableMethodFromName(String? name) {
  if (name == null) return null;
  return AssessmentMethod.values.cast<AssessmentMethod?>().firstWhere(
        (method) => method?.name == name,
        orElse: () => null,
      );
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
