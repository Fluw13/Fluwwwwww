import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/home/domain/nutrition_advice.dart';

class AdviceCard extends StatelessWidget {
  const AdviceCard({required this.advice, super.key});

  final List<Advice> advice;

  @override
  Widget build(BuildContext context) {
    // A light bulb, not the design's sparkles: sparkles usually mean AI, and this advice comes from fixed rules.
    return SectionCard(
      title: 'Gợi ý cho bạn',
      icon: Icons.lightbulb_outline,
      children: [
        for (final item in advice) ...[_AdviceTile(advice: item), const SizedBox(height: AppSpacing.sm)],
        Text(
          'Gợi ý chung từ hồ sơ và Nhật ký, không thay thế tư vấn y tế.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AdviceTile extends StatelessWidget {
  const _AdviceTile({required this.advice});

  final Advice advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // The design's "NÊN DÙNG / NÊN TRÁNH" blocks; the kind is also spelled out in the label, never only shown by colour.
    final (icon, label, background, accent) = switch (advice.kind) {
      AdviceKind.recommend => (Icons.thumb_up_outlined, 'Nên dùng', scheme.surfaceContainerLow, scheme.primary),
      AdviceKind.avoid => (Icons.warning_amber_rounded, 'Nên tránh', scheme.errorContainer, scheme.error),
      AdviceKind.note => (Icons.info_outline, 'Lưu ý', scheme.surfaceContainerLow, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.14)),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  semanticsLabel: label,
                  style: theme.textTheme.labelSmall?.copyWith(color: accent),
                ),
                const SizedBox(height: 2),
                Text(advice.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(advice.body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
