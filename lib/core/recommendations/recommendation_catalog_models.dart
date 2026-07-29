enum RecommendationLanguage { th, en }

class RecommendationCatalogItem {
  const RecommendationCatalogItem({
    required this.id,
    required this.selectionKey,
    required this.displayOrder,
    required this.category,
    required this.activity,
    required this.bodyPart,
    required this.riskLevel,
    required this.thaiText,
    required this.englishText,
    required this.sourceId,
    required this.sourcePage,
  });

  final String id;
  final String selectionKey;
  final int displayOrder;
  final String category;
  final String activity;
  final String bodyPart;
  final String riskLevel;
  final String thaiText;
  final String englishText;
  final String sourceId;
  final String sourcePage;

  String text(RecommendationLanguage language) {
    return switch (language) {
      RecommendationLanguage.th => thaiText,
      RecommendationLanguage.en => englishText,
    };
  }
}
