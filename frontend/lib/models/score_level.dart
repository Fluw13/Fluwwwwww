import 'package:flutter/material.dart';

import '../core/app_colors.dart';

enum ScoreLevel {
  good(label: 'Tốt', color: AppColors.accent),
  moderate(label: 'Trung bình', color: AppColors.warning),
  poor(label: 'Kém', color: AppColors.danger);

  const ScoreLevel({required this.label, required this.color});

  final String label;
  final Color color;

  static ScoreLevel fromScore(int score) {
    if (score >= 70) return good;
    if (score >= 40) return moderate;
    return poor;
  }
}
