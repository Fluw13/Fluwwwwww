import 'package:flutter/material.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/nutrition/shown_amount.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// "Tổng năng lượng" for the portion in the field, always saying which portion: "114 kcal cho 440 g". Never shows
/// the per-100 number as if it were the whole pack.
class PortionEnergyCard extends StatelessWidget {
  const PortionEnergyCard({required this.portion, required this.unit, required this.kcal, super.key});

  /// Null while the portion field holds no valid amount.
  final double? portion;
  final QuantityUnit unit;

  /// Null when the source has no energy value (or there is no portion).
  final double? kcal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final portion = this.portion;
    final kcal = this.kcal;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: MergeSemantics(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(Icons.local_fire_department_outlined, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng năng lượng', style: muted),
                    if (portion == null) ...[
                      Text('–', style: theme.textTheme.headlineMedium),
                      Text('Nhập khẩu phần hợp lệ để tính.', style: muted),
                    ] else if (kcal == null) ...[
                      Text('Chưa có dữ liệu', style: theme.textTheme.titleMedium),
                      Text('Nguồn không ghi năng lượng.', style: muted),
                    ] else
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatShownAmount(Nutrient.energyKcal, kcal),
                              style: theme.textTheme.headlineMedium,
                            ),
                            TextSpan(text: ' kcal', style: theme.textTheme.titleSmall),
                            TextSpan(text: ' cho ${formatDecimal(portion)} ${unit.symbol}', style: muted),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
