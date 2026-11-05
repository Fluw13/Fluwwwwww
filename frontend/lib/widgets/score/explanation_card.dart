import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../common/section_title.dart';

/// A titled card on the score explanation screen.
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Body text inside an [ExplanationCard].
class ExplanationText extends StatelessWidget {
  const ExplanationText(
    this.text, {
    super.key,
    this.secondary = false,
    this.emphasized = false,
  });

  final String text;
  final bool secondary;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: secondary ? 13 : 14,
          height: 1.5,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
          color: secondary ? palette.textSecondary : palette.textPrimary,
        ),
      ),
    );
  }
}
