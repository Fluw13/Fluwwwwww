import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/methodology/presentation/methodology_content.dart';

/// "Cách Fluw tính": every formula behind the daily targets, with its source, and the thresholds Fluw chose itself.
class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cách Fluw tính')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Fluw dành cho người từ 18 tuổi và không tính chỉ tiêu khi mang thai hoặc cho con bú. Mọi số liệu là ước '
            'tính, không thay thế tư vấn y tế.',
            style: theme.textTheme.bodyMedium,
          ),
          for (final section in methodologySections) ...[
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: section.title,
              children: [
                for (final (index, item) in section.items.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  _Item(item),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.item);

  final MethodItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(item.text, style: theme.textTheme.bodyMedium),
        for (final source in item.sources)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text('Nguồn: $source', style: muted),
          ),
      ],
    );
  }
}
