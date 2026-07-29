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
    return resolveFromCatalog(
      catalog: generatedRecommendationCatalog,
      selectionKey: selectionKey,
      language: language,
      activity: activity,
      bodyPart: bodyPart,
      riskLevel: riskLevel,
    );
  }

  /// Resolves an explicit catalog for generic specificity-contract tests.
  ///
  /// Runtime consumers should use [resolve], which binds the approved catalog.
  static List<RecommendationCatalogItem> resolveFromCatalog({
    required Iterable<RecommendationCatalogItem> catalog,
    required String selectionKey,
    required RecommendationLanguage language,
    String? activity,
    String? bodyPart,
    String? riskLevel,
  }) {
    final canonicalActivity = _canonicalContext(activity);
    final canonicalBodyPart = _canonicalContext(bodyPart);
    final canonicalRiskLevel = _canonicalContext(riskLevel);
    final contexts = <(String, String, String)>[
      if (canonicalActivity != null &&
          canonicalBodyPart != null &&
          canonicalRiskLevel != null)
        (canonicalActivity, canonicalBodyPart, canonicalRiskLevel),
      if (canonicalActivity != null && canonicalRiskLevel != null)
        (canonicalActivity, 'any', canonicalRiskLevel),
      if (canonicalBodyPart != null && canonicalRiskLevel != null)
        ('any', canonicalBodyPart, canonicalRiskLevel),
      if (canonicalActivity != null) (canonicalActivity, 'any', 'any'),
      if (canonicalBodyPart != null) ('any', canonicalBodyPart, 'any'),
      ('any', 'any', 'any'),
    ];

    final seenContexts = <(String, String, String)>{};
    for (final context in contexts) {
      if (!seenContexts.add(context)) continue;
      final matches = catalog
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

  static String? tryJoinedTextForSelectionKey({
    required String selectionKey,
    required RecommendationLanguage language,
  }) {
    return tryJoinedTextForSelectionKeyFromCatalog(
      catalog: generatedRecommendationCatalog,
      selectionKey: selectionKey,
      language: language,
    );
  }

  /// Resolves a key without caller context only when every matching atomic
  /// item belongs to the same Catalog context.
  ///
  /// This keeps legacy key-only display boundaries deterministic without
  /// merging recommendations from incompatible contexts.
  static String? tryJoinedTextForSelectionKeyFromCatalog({
    required Iterable<RecommendationCatalogItem> catalog,
    required String selectionKey,
    required RecommendationLanguage language,
  }) {
    final matches = catalog
        .where(
          (item) =>
              item.selectionKey == selectionKey &&
              item.text(language).trim().isNotEmpty,
        )
        .toList(growable: false);
    if (matches.isEmpty) return null;

    final contexts = matches
        .map((item) => (item.activity, item.bodyPart, item.riskLevel))
        .toSet();
    if (contexts.length != 1) return null;

    matches.sort(
      (left, right) => left.displayOrder.compareTo(right.displayOrder),
    );
    return matches.map((item) => item.text(language)).join('\n');
  }

  static String? selectionKeyForLegacyText(String text) {
    return generatedRecommendationLegacyAliases[text];
  }

  static String? _canonicalContext(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '')
        .toLowerCase();
  }
}
