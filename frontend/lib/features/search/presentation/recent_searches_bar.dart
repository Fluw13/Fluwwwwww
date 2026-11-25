import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// "Gần đây": small chips that search again on tap, each with its own ×, and "Xóa tất cả".
class RecentSearchesBar extends StatelessWidget {
  const RecentSearchesBar({
    required this.queries,
    required this.onSearch,
    required this.onRemove,
    required this.onClearAll,
    super.key,
  });

  final List<String> queries;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text('Gần đây', style: theme.textTheme.labelLarge)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
              onPressed: onClearAll,
              child: const Text('Xóa tất cả'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final query in queries)
              InputChip(
                label: Text(query),
                onPressed: () => onSearch(query),
                onDeleted: () => onRemove(query),
                deleteButtonTooltipMessage: 'Xóa "$query" khỏi gần đây',
                deleteIcon: const Icon(Icons.close, size: 16),
                shape: const StadiumBorder(),
                side: BorderSide.none,
                backgroundColor: scheme.surfaceContainer,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
          ],
        ),
      ],
    );
  }
}
