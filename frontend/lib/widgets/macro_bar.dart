import 'package:flutter/material.dart';

class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MacroTile(emoji: '🔥', label: 'Calo', value: '${calories.round()} kcal'),
        const SizedBox(width: 8),
        _MacroTile(emoji: '🥩', label: 'Đạm', value: '${protein.toStringAsFixed(1)} g'),
        const SizedBox(width: 8),
        _MacroTile(emoji: '🥑', label: 'Béo', value: '${fat.toStringAsFixed(1)} g'),
        const SizedBox(width: 8),
        _MacroTile(emoji: '🌾', label: 'Carb', value: '${carbs.toStringAsFixed(1)} g'),
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
          color: Colors.grey.shade100,
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
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
