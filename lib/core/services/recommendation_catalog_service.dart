import '../recommendations/generated_recommendation_catalog.dart';
import '../recommendations/recommendation_catalog_models.dart';

class RecommendationCatalogService {
  const RecommendationCatalogService._();

  static List<RecommendationCatalogItem> resolve({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  }) {
    final contexts = <(String, String, String)>[
      if (activity != null && bodyPart != null && riskLevel != null)
        (activity, bodyPart, riskLevel),
      if (activity != null && riskLevel != null) (activity, 'any', riskLevel),
      if (bodyPart != null && riskLevel != null) ('any', bodyPart, riskLevel),
      if (activity != null) (activity, 'any', 'any'),
      if (bodyPart != null) ('any', bodyPart, 'any'),
      ('any', 'any', 'any'),
    ];

    final seenContexts = <(String, String, String)>{};
    for (final context in contexts) {
      if (!seenContexts.add(context)) continue;
      final matches = generatedRecommendationCatalog
          .where(
            (item) =>
                item.selectionKey == selectionKey &&
                item.activity == context.$1 &&
                item.bodyPart == context.$2 &&
                item.riskLevel == context.$3 &&
                item.text(language).trim().isNotEmpty,
          )
          .toList(growable: false)
        ..sort(
            (left, right) => left.displayOrder.compareTo(right.displayOrder));
      if (matches.isNotEmpty) {
        return List.unmodifiable(matches);
      }
    }
    return const [];
  }

  static String joinedText({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  }) {
    return tryJoinedText(
          selectionKey: selectionKey,
          language: language,
          activity: activity,
          bodyPart: bodyPart,
          riskLevel: riskLevel,
        ) ??
        '';
  }

  static String? tryJoinedText({
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  }) {
    final items = resolve(
      selectionKey: selectionKey,
      language: language,
      activity: activity,
      bodyPart: bodyPart,
      riskLevel: riskLevel,
    );
    if (items.isEmpty) return null;
    return items.map((item) => item.text(language)).join('\n');
  }

  static String? selectionKeyForLegacyText(String text) {
    return generatedRecommendationLegacyAliases[text];
  }
}
