import 'package:flutter/material.dart';

class MacroBar extends StatelessWidget {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const MacroBar({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  Widget _buildItem(String label, String value, String emoji) {
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildItem('Calo', ' kcal', '🔥'),
        const SizedBox(width: 8),
        _buildItem('Đạm', 'g', '🥩'),
        const SizedBox(width: 8),
        _buildItem('Béo', 'g', '🥑'),
        const SizedBox(width: 8),
        _buildItem('Carb', 'g', '🌾'),
      ],
    );
  }
}
