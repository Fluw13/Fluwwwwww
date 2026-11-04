import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';
import 'common/section_title.dart';

class TagSection extends StatelessWidget {
  const TagSection({super.key, required this.title, required this.tags, required this.tone, this.icon, this.note});

  final String title;
  final List<String> tags;
  final ScoreColors tone;
  final IconData? icon;
  final String? note;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final String? note = this.note;
    final IconData? icon = this.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final String tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 7),
                decoration: BoxDecoration(color: tone.container, borderRadius: BorderRadius.circular(AppRadius.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 14, color: tone.text), const SizedBox(width: 6)],
                    Flexible(
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 13, color: tone.text, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(note, style: TextStyle(color: context.palette.textSecondary, fontSize: 12)),
        ],
      ],
    );
  }
}
