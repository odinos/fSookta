import 'risk_level.dart';

class RiskAssessmentResult {
  const RiskAssessmentResult({
    required this.level,
    required this.confidenceScore,
    required this.actionRecommendation,
  });

  final RiskLevel level;
  final double confidenceScore;
  final String actionRecommendation;

  factory RiskAssessmentResult.fromProbability(
    double probability, {
    RiskThresholds thresholds = const RiskThresholds(),
  }) {
    final confidenceScore = probability.clamp(0.0, 1.0).toDouble();
    final level = thresholds.levelFor(confidenceScore);
    return RiskAssessmentResult(
      level: level,
      confidenceScore: confidenceScore,
      actionRecommendation: _recommendationFor(level),
    );
  }

  static String _recommendationFor(RiskLevel level) {
    return switch (level) {
      RiskLevel.low =>
        'ท่าทางมีความเสี่ยงต่ำ ควรรักษาท่าทางที่ดีและพักเป็นระยะ',
      RiskLevel.medium =>
        'ควรปรับความสูง ระยะเอื้อม หรือจังหวะการทำงานเพื่อลดแรงกดต่อร่างกาย',
      RiskLevel.high =>
        'ควรปรับสถานีงาน ลดน้ำหนัก/แรงที่ใช้ และหลีกเลี่ยงท่าซ้ำเป็นเวลานาน',
      RiskLevel.veryHigh =>
        'ควรหยุดประเมินท่านี้และปรับกระบวนการทำงานทันทีเพื่อลดความเสี่ยงสูงมาก',
    };
  }
}

class RiskThresholds {
  const RiskThresholds({
    this.medium = 0.35,
    this.high = 0.6,
    this.veryHigh = 0.82,
  });

  final double medium;
  final double high;
  final double veryHigh;

  RiskLevel levelFor(double probability) {
    if (probability >= veryHigh) return RiskLevel.veryHigh;
    if (probability >= high) return RiskLevel.high;
    if (probability >= medium) return RiskLevel.medium;
    return RiskLevel.low;
  }
}
