import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';
import 'common/section_title.dart';

/// A titled group of chips. With no tags it shows [emptyText] when given,
/// otherwise nothing at all.
class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.tone,
    this.icon,
    this.note,
    this.emptyText,
  });

  final String title;
  final List<String> tags;
  final ScoreColors tone;
  final IconData? icon;
  final String? note;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final String? emptyText = this.emptyText;
    if (tags.isEmpty && emptyText == null) return const SizedBox.shrink();

    final FluwPalette palette = context.palette;
    final String? note = this.note;
    final IconData? icon = this.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        if (tags.isEmpty)
          Text(
            emptyText!,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: palette.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final String tag in tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tone.container,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: tone.text),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 13,
                            color: tone.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            note,
            style: TextStyle(color: palette.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
