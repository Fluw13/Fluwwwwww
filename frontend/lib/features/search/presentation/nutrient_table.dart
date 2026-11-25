import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrition_facts.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Every nutrient as the source gives it, per 100 g or 100 ml, under a title that says so; "Chưa có dữ liệu" where
/// the source has nothing. [footnote] goes under the rows, e.g. what USDA counts as carb.
class NutrientTable extends StatelessWidget {
  const NutrientTable({required this.facts, this.footnote, super.key});

  final NutritionFacts facts;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final unit = facts.unit.symbol;
    final footnote = this.footnote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Bảng dinh dưỡng trong 100 $unit', style: theme.textTheme.titleMedium)),
            Text('Số liệu nguồn ghi cho 100 $unit, chưa phải cả gói hay cả chai.', style: muted),
            const SizedBox(height: AppSpacing.sm),
            for (final (index, nutrient) in Nutrient.values.indexed) ...[
              if (index > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      Expanded(child: Text(nutrientLabel(nutrient), style: theme.textTheme.bodyMedium)),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(child: _value(theme, facts.per100[nutrient], nutrient)),
                    ],
                  ),
                ),
              ),
            ],
            if (footnote != null) ...[const SizedBox(height: AppSpacing.xs), Text(footnote, style: muted)],
          ],
        ),
      ),
    );
  }

  Widget _value(ThemeData theme, double? value, Nutrient nutrient) {
    if (value == null) {
      return Text(
        'Chưa có dữ liệu',
        textAlign: TextAlign.end,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Text(formatNutrientAmount(nutrient, value), textAlign: TextAlign.end, style: theme.textTheme.titleSmall);
  }
}
