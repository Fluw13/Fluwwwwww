import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// Quick amounts next to the portion field, as in the design; the pack's own serving comes first when it has one.
class PortionChips extends StatelessWidget {
  const PortionChips({
    required this.unit,
    required this.serving,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const List<double> standardAmounts = [50, 100, 150, 200];

  final QuantityUnit unit;
  final double? serving;

  /// The amount in the field, so the matching chip shows as chosen.
  final double? selected;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final serving = this.serving;
    Widget chip(double amount, String label) =>
        ChoiceChip(label: Text(label), selected: selected == amount, onSelected: (_) => onSelected(amount));

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (serving != null) chip(serving, '1 khẩu phần (${formatDecimal(serving)} ${unit.symbol})'),
        for (final amount in standardAmounts)
          if (amount != serving) chip(amount, '${formatDecimal(amount)} ${unit.symbol}'),
      ],
    );
  }
}
