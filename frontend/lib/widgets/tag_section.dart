import 'package:flutter/material.dart';

class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.title,
    required this.tags,
    required this.tagColor,
  });

  final String title;
  final List<String> tags;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

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
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: tagColor.withValues(alpha: 0.15),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
          ],
        ),
      ],
    );
  }
}
