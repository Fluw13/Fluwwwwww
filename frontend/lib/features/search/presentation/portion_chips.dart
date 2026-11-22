import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// Quick amounts next to the portion field, as in the design; the pack's own serving and the whole pack come first
/// when the source gives them.
class PortionChips extends StatelessWidget {
  const PortionChips({
    required this.unit,
    required this.serving,
    required this.package,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const List<double> standardAmounts = [50, 100, 150, 200];

  final QuantityUnit unit;
  final double? serving;
  final double? package;

  /// The amount in the field, so the matching chip shows as chosen.
  final double? selected;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final serving = this.serving;
    final package = this.package;
    // A strong fill for the chosen amount, like the design's selected portion tile.
    Widget chip(double amount, String label) => ChoiceChip(
      label: Text(label),
      selected: selected == amount,
      onSelected: (_) => onSelected(amount),
      showCheckmark: false,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control)),
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainer,
      ),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
    );

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (serving != null) chip(serving, '1 khẩu phần (${formatDecimal(serving)} ${unit.symbol})'),
        if (package != null && package != serving) chip(package, packageChipLabel(package, unit)),
        for (final amount in standardAmounts)
          if (amount != serving && amount != package) chip(amount, '${formatDecimal(amount)} ${unit.symbol}'),
      ],
    );
  }
}
