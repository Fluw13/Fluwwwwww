import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// The last few searches as chips under the search field.
class RecentSearches extends StatelessWidget {
  const RecentSearches({super.key, required this.queries, required this.onSelected});

  static const int maxShown = 5;

  final List<String> queries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final String query in queries.take(maxShown))
          ActionChip(
            avatar: const Icon(Icons.history, size: 18),
            label: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
            tooltip: 'Tìm lại "$query"',
            onPressed: () => onSelected(query),
          ),
      ],
    );
  }
}
