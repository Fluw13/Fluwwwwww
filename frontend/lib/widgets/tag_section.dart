import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';
import '../core/theme/score_colors.dart';

class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.tone,
    this.note,
  });

  final String title;
  final List<String> tags;
  final ScoreColors tone;
  final String? note;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final String? note = this.note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final String tag in tags)
              Chip(
                label: Text(tag, style: TextStyle(fontSize: 12, color: tone.text, fontWeight: FontWeight.w600)),
                backgroundColor: tone.container,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
          ],
        ),
        if (note != null) ...[
          const SizedBox(height: 6),
          Text(note, style: TextStyle(color: context.palette.textSecondary, fontSize: 11)),
        ],
      ],
    );
  }
}
