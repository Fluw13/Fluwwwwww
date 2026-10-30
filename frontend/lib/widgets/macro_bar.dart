import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';

class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  static const String _missingValue = '—';

  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;

  static String _formatKcal(double? value) {
    return value == null ? _missingValue : '${value.round()} kcal';
  }

  static String _formatGrams(double? value) {
    return value == null ? _missingValue : '${value.toStringAsFixed(1)} g';
  }

  @override
  Widget build(BuildContext context) {
    final bool hasMissingValue = [calories, protein, fat, carbs].contains(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MacroTile(emoji: '🔥', label: 'Calo', value: _formatKcal(calories)),
            const SizedBox(width: 8),
            _MacroTile(emoji: '🥩', label: 'Đạm', value: _formatGrams(protein)),
            const SizedBox(width: 8),
            _MacroTile(emoji: '🥑', label: 'Béo', value: _formatGrams(fat)),
            const SizedBox(width: 8),
            _MacroTile(emoji: '🌾', label: 'Carb', value: _formatGrams(carbs)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          hasMissingValue
              ? 'Trên 100 g · Nguồn: OpenFoodFacts · "—" là chưa có dữ liệu'
              : 'Trên 100 g · Nguồn: OpenFoodFacts',
          style: TextStyle(color: context.palette.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: context.palette.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
