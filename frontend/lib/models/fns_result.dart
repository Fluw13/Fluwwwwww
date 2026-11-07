import 'score_level.dart';

enum FnsStatus { verified, provisional, notScored }

/// Fluw Nutrition Score exactly as the backend computed it. The app only displays it: the scoring rules
/// live in the backend FNS engine and are never repeated here.
class FnsResult {
  const FnsResult({
    required this.status,
    this.score,
    this.category,
    this.basis,
    this.rawScore,
    this.baselineComponents = const [],
    this.componentPoints = const {},
    this.proteinEligible,
    this.fiberEligible = false,
    this.missingFields = const [],
    this.reasonCodes = const [],
    this.limitations = const [],
  });

  /// The response had no usable `fns` object (older backend or malformed body).
  const FnsResult.unavailable() : this(status: FnsStatus.notScored, reasonCodes: const [unavailableReason]);

  static const String unavailableReason = 'FNS_UNAVAILABLE';
  static const double maxScore = 10;

  factory FnsResult.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const FnsResult.unavailable();

    final FnsStatus? status = _readStatus(json['status']);
    final double? score = _readScore(json['score']);
    // A "scored" status without a valid score must never be shown as a number.
    if (status == null || (status != FnsStatus.notScored && score == null)) {
      return const FnsResult.unavailable();
    }

    final Map<String, dynamic> eligibility = _asMap(json['modifier_eligibility']);
    final Object? rawScore = json['raw_score'];

    return FnsResult(
      status: status,
      score: status == FnsStatus.notScored ? null : score,
      category: _readString(json['category']),
      basis: _readString(json['basis']),
      rawScore: rawScore is int ? rawScore : null,
      baselineComponents: _readStrings(json['baseline_components']),
      componentPoints: _readPoints(json['component_points']),
      proteinEligible: eligibility['protein'] is bool ? eligibility['protein'] as bool : null,
      fiberEligible: eligibility['fiber'] == true,
      missingFields: _readStrings(json['missing_fields']),
      reasonCodes: _readStrings(json['reason_codes']),
      limitations: _readStrings(json['limitations']),
    );
  }

  final FnsStatus status;
  final double? score;
  final String? category;
  final String? basis;
  final int? rawScore;
  final List<String> baselineComponents;

  /// Points per component; null when the value is unknown or the component does not apply.
  final Map<String, int?> componentPoints;
  final bool? proteinEligible;
  final bool fiberEligible;
  final List<String> missingFields;
  final List<String> reasonCodes;
  final List<String> limitations;

  bool get isScored => status != FnsStatus.notScored && score != null;

  ScoreLevel? get level {
    final double? value = score;
    return isScored && value != null ? ScoreLevel.fromScore(value) : null;
  }

  bool hasLimitation(String code) => limitations.contains(code);

  static FnsStatus? _readStatus(Object? value) {
    switch (value) {
      case 'VERIFIED':
        return FnsStatus.verified;
      case 'PROVISIONAL':
        return FnsStatus.provisional;
      case 'NOT_SCORED':
        return FnsStatus.notScored;
      default:
        return null;
    }
  }

  static double? _readScore(Object? value) {
    if (value is! num || !value.isFinite || value < 0 || value > maxScore) return null;
    return value.toDouble();
  }

  static String? _readString(Object? value) => value is String && value.isNotEmpty ? value : null;

  static Map<String, dynamic> _asMap(Object? value) => value is Map<String, dynamic> ? value : const {};

  static List<String> _readStrings(Object? value) {
    return value is List ? value.whereType<String>().toList(growable: false) : const [];
  }

  static Map<String, int?> _readPoints(Object? value) {
    if (value is! Map<String, dynamic>) return const {};
    return {
      for (final MapEntry<String, dynamic> entry in value.entries)
        if (entry.value == null || entry.value is int) entry.key: entry.value as int?,
    };
  }
}
