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
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Gợi ý cho bạn',
      children: [
        for (final item in advice) ...[_AdviceTile(advice: item), const SizedBox(height: AppSpacing.sm)],
        Text(
          'Gợi ý chung từ hồ sơ và Nhật ký, không thay thế tư vấn y tế.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    // Light cards as in the design; the kind is also spelled out in the label, never only shown by colour.
    final (icon, label, background, accent) = switch (advice.kind) {
      AdviceKind.recommend => (Icons.thumb_up_outlined, 'Nên dùng', scheme.surfaceContainerLow, scheme.primary),
      AdviceKind.avoid => (Icons.warning_amber_rounded, 'Nên tránh', scheme.errorContainer, scheme.error),
      AdviceKind.note => (Icons.info_outline, 'Lưu ý', scheme.surfaceContainerLow, scheme.onSurfaceVariant),
    };
    final foreground = advice.kind == AdviceKind.avoid ? scheme.onErrorContainer : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: accent)),
                Text(advice.title, style: theme.textTheme.titleSmall?.copyWith(color: foreground)),
                Text(advice.body, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
