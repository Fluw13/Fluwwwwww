import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';

enum NutrientTargetKind {
  /// Calories: going over is said, as a target rather than a limit.
  calorieGoal,

  /// Protein: the lower end to reach; going over is fine.
  minimum,

  /// Saturated fat, sodium: going over is a warning.
  limit,

  /// Total sugars: the 10% / 5% of energy is a suggestion made from WHO's advice on free sugars, which labels do not
  /// give. Going over is said in the warning colour, never as an exceeded limit.
  suggestion,

  /// Fat and carbohydrates: a plan to follow, shown without warnings.
  target,
}

/// How a day's total compares with its target, as the numbers are shown. Every row and box that shows
/// "eaten / target" reads it from here, so the wording, the percentage and "over" are the same on every screen.
@immutable
final class NutrientTargetStatus {
  factory NutrientTargetStatus.of({
    required Nutrient nutrient,
    required double? value,
    required double? target,
    required NutrientTargetKind kind,
  }) {
    if (value == null || target == null || target <= 0) {
      return NutrientTargetStatus._(kind: kind, percent: null, share: null, isOver: false);
    }
    final warnsOver = kind != NutrientTargetKind.minimum && kind != NutrientTargetKind.target;
    return NutrientTargetStatus._(
      kind: kind,
      percent: percentAsShown(nutrient, amount: value, target: target),
      share: (value / target).clamp(0, 1).toDouble(),
      isOver: warnsOver && isOverAsShown(nutrient, amount: value, target: target),
    );
  }

  const NutrientTargetStatus._({required this.kind, required this.percent, required this.share, required this.isOver});

  final NutrientTargetKind kind;

  /// Null without a total or a target: nothing to compare, so no bar is drawn.
  final int? percent;

  /// The filled part of the bar, 0–1.
  final double? share;
  final bool isOver;

  String get targetWord => switch (kind) {
    NutrientTargetKind.calorieGoal || NutrientTargetKind.target => 'mục tiêu',
    NutrientTargetKind.minimum => 'cần ít nhất',
    NutrientTargetKind.limit => 'tối đa',
    NutrientTargetKind.suggestion => 'mức gợi ý',
  };

  String? get overText => !isOver
      ? null
      : switch (kind) {
          NutrientTargetKind.calorieGoal => 'Vượt mục tiêu calo cả ngày.',
          NutrientTargetKind.suggestion => 'Cao hơn mức gợi ý cả ngày.',
          _ => 'Vượt giới hạn cả ngày.',
        };

  /// Total sugars has a suggestion, not a limit: the warning colour, never the error red.
  Color overColor(ColorScheme colorScheme) =>
      kind == NutrientTargetKind.suggestion ? colorScheme.tertiary : colorScheme.error;
}
