import 'package:flutter/material.dart';

class MacroBar extends StatelessWidget {
  final String calories;
  final String protein;
  final String fat;
  final String carbs;

  const MacroBar({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMacroItem('🔥', calories, 'Kcal', const Color(0xFFFF6B6B)),
          _buildDivider(),
          _buildMacroItem('🥩', protein, 'Đạm', const Color(0xFF4DABF7)),
          _buildDivider(),
          _buildMacroItem('🥑', fat, 'Béo', const Color(0xFF51CF66)),
          _buildDivider(),
          _buildMacroItem('🌾', carbs, 'Carb', const Color(0xFFFCC419)),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF868E96)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFDEE2E6),
    );
  }
}
