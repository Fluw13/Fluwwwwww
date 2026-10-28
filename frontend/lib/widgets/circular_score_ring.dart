import 'package:flutter/material.dart';

class CircularScoreRing extends StatelessWidget {
  final int score;
  final double size;

  const CircularScoreRing({
    super.key,
    required this.score,
    this.size = 140.0,
  });

  Color _getScoreColor(int score) {
    if (score >= 70) return const Color(0xFF00E676);
    if (score >= 40) return const Color(0xFFFFD600);
    return const Color(0xFFFF3D00);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '',
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF141414),
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: size * 0.1,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
