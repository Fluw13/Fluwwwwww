import 'package:flutter/material.dart';

class CircularScoreRing extends StatelessWidget {
  final int score;

  const CircularScoreRing({super.key, required this.score});

  Color _getPrimaryColor() {
    if (score >= 70) return const Color(0xFF2B8A3E); // Xanh lá
    if (score >= 40) return const Color(0xFFF59F00); // Vàng
    return const Color(0xFFE03131); // Đỏ
  }

  Color _getSecondaryColor() {
    if (score >= 70) return const Color(0xFF51CF66);
    if (score >= 40) return const Color(0xFFFFD43B);
    return const Color(0xFFFF8787);
  }

  String _getRatingText() {
    if (score >= 70) return 'TỐT CHO SỨC KHỎE';
    if (score >= 40) return 'NÊN DÙNG ĐIỀU ĐỘ';
    return 'CẦN HẠN CHẾ';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();
    final secondaryColor = _getSecondaryColor();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: (score.clamp(0, 100)) / 100.0,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFE9ECEF),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getRatingText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
