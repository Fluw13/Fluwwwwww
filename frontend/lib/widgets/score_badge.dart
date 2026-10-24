import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({super.key, required this.score});

  Color _getColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.teal.shade500;
    if (score >= 40) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            '$score / 100',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
