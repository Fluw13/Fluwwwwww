import '../../data/json/json_fields.dart';

/// Why Zero could not explain the score. The HTTP status is still 200.
enum AiErrorCode {
  notConfigured,
  unavailable,
  rateLimited,
  invalidResponse,
  dailyLimit,

  /// A code this app version does not know yet.
  unknown;

  static AiErrorCode fromCode(String code) => switch (code) {
    'AI_NOT_CONFIGURED' => notConfigured,
    'AI_UNAVAILABLE' => unavailable,
    'AI_RATE_LIMITED' => rateLimited,
    'AI_INVALID_RESPONSE' => invalidResponse,
    'AI_DAILY_LIMIT' => dailyLimit,
    _ => unknown,
  };
}

/// Zero's explanation of a score it did not compute. It carries no score.
class ZeroExplanation {
  const ZeroExplanation({
    required this.summary,
    this.highlights = const [],
    this.recommendation,
    this.alternatives = const [],
  });

  static const int maxHighlights = 5;
  static const int maxAlternatives = 3;

  /// Null when the explanation has no summary, the one part every answer needs.
  static ZeroExplanation? tryParse(Object? value) {
    final Map<String, dynamic>? json = readMap(value);
    final String? summary = readString(json?['summary']);
    if (summary == null) return null;

    return ZeroExplanation(
      summary: summary,
      highlights: List.unmodifiable(
        readStringList(json?['highlights']).take(maxHighlights),
      ),
      recommendation: readString(json?['recommendation']),
      alternatives: List.unmodifiable(
        readStringList(json?['alternatives']).take(maxAlternatives),
      ),
    );
  }

  final String summary;
  final List<String> highlights;
  final String? recommendation;

  /// Generic product groups, never brands.
  final List<String> alternatives;
}

/// Body of `GET /api/v1/products/:barcode/analysis`. Exactly one of
/// [explanation] and [aiError] is set.
class ProductAnalysis {
  const ProductAnalysis({
    this.barcode,
    this.scoreVersion,
    this.explanation,
    this.aiError,
    this.disclaimer,
  }) : assert((explanation == null) != (aiError == null));

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    final ZeroExplanation? explanation = ZeroExplanation.tryParse(
      json['aiAnalysis'],
    );
    final String? errorCode = readString(json['aiError']);
    return ProductAnalysis(
      barcode: readString(json['barcode']),
      scoreVersion: readString(json['scoreVersion']),
      explanation: explanation,
      // An empty or unusable answer is treated like a malformed one.
      aiError: explanation != null
          ? null
          : (errorCode == null
                ? AiErrorCode.invalidResponse
                : AiErrorCode.fromCode(errorCode)),
      disclaimer: readString(json['disclaimer']),
    );
  }

  final String? barcode;

  /// Score formula the explanation was written for.
  final String? scoreVersion;
  final ZeroExplanation? explanation;
  final AiErrorCode? aiError;
  final String? disclaimer;
}
