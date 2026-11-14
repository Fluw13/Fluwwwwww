import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/nutrients.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Every nutrient for the chosen portion and per 100, with "Chưa có dữ liệu" where the source has nothing.
class NutrientTable extends StatelessWidget {
  const NutrientTable({
    required this.portion,
    required this.per100,
    required this.portionLabel,
    required this.unitLabel,
    super.key,
  });

  final Nutrients? portion;
  final Nutrients per100;
  final String portionLabel;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            Expanded(
              child: Text(portionLabel, style: muted, textAlign: TextAlign.end),
            ),
            Expanded(
              child: Text('100 $unitLabel', style: muted, textAlign: TextAlign.end),
            ),
          ],
        ),
        for (final nutrient in Nutrient.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(child: Text(nutrientLabel(nutrient), style: theme.textTheme.bodyMedium)),
                Expanded(child: _value(context, portion?[nutrient], nutrient, emphasize: true)),
                Expanded(child: _value(context, per100[nutrient], nutrient, emphasize: false)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _value(BuildContext context, double? value, Nutrient nutrient, {required bool emphasize}) {
    final theme = Theme.of(context);
    if (value == null) {
      return Text(
        portion == null && emphasize ? '–' : 'Chưa có dữ liệu',
        textAlign: TextAlign.end,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Text(
      '${formatDecimal(value)} ${nutrientUnit(nutrient)}',
      textAlign: TextAlign.end,
      style: emphasize ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium,
    );
  }
}
