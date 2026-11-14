import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';
import 'package:fluw/features/search/domain/search_response.dart';
import 'package:fluw/features/search/presentation/food_result_card.dart';
import 'package:fluw/features/search/presentation/recent_searches_controller.dart';
import 'package:fluw/features/search/presentation/search_controller.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';
import 'package:fluw/features/search/presentation/search_loading_view.dart';
import 'package:fluw/features/search/presentation/search_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({required this.onOpenFood, super.key});

  final ValueChanged<FoodItem> onOpenFood;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  Set<QuickFilter> _filters = const {};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String text) async {
    final query = normalizeQuery(text);
    if (query.length < minSearchLength || query.length > maxSearchLength) {
      return;
    }
    _query.text = query;
    FocusScope.of(context).unfocus();
    await ref.read(recentSearchesProvider.notifier).add(query);
    await ref.read(searchControllerProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(searchControllerProvider);
    final recent = ref.watch(recentSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TextField(
          controller: _query,
          textInputAction: TextInputAction.search,
          maxLength: maxSearchLength,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Tìm thực phẩm, đồ đóng gói...',
            counterText: '',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Tìm',
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _search(_query.text),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Lọc nhanh (trong 100 g/ml)', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final filter in QuickFilter.values)
              FilterChip(
                label: Text(quickFilterLabel(filter)),
                selected: _filters.contains(filter),
                onSelected: (selected) =>
                    setState(() => _filters = selected ? {..._filters, filter} : ({..._filters}..remove(filter))),
              ),
          ],
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Text('Gần đây', style: theme.textTheme.labelLarge)),
              TextButton(
                onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
                child: const Text('Xóa tất cả'),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final query in recent)
                InputChip(
                  label: Text(query),
                  onPressed: () => _search(query),
                  onDeleted: () => ref.read(recentSearchesProvider.notifier).remove(query),
                  deleteButtonTooltipMessage: 'Xóa "$query" khỏi gần đây',
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ..._results(state, theme),
      ],
    );
  }

  List<Widget> _results(SearchState state, ThemeData theme) {
    return switch (state) {
      SearchIdle() => [
        Text(
          'Nhập tên thực phẩm rồi bấm tìm. Dữ liệu lấy từ Open Food Facts và USDA FoodData Central.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
      SearchLoading() => [const SearchLoadingView()],
      SearchFailed(:final query, :final failure) => [
        Text(apiFailureMessage(failure), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => ref.read(searchControllerProvider.notifier).search(query),
            child: const Text('Thử lại'),
          ),
        ),
      ],
      SearchLoaded(:final response) => _loaded(response, theme),
    };
  }

  List<Widget> _loaded(SearchResponse response, ThemeData theme) {
    final items = applyQuickFilters(response.items, _filters);
    final hiddenByFilters = response.items.length - items.length;
    return [
      Text('${items.length} kết quả cho "${response.query}"', style: theme.textTheme.titleMedium),
      if (response.isPartial)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Một nguồn dữ liệu đang lỗi nên có thể thiếu kết quả.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ),
      if (hiddenByFilters > 0)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Đã ẩn $hiddenByFilters món không đạt bộ lọc hoặc thiếu số liệu để lọc.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      const SizedBox(height: AppSpacing.sm),
      if (items.isEmpty)
        Text(
          response.items.isEmpty
              ? 'Không tìm thấy món nào. Thử từ khóa khác, ví dụ tên hãng.'
              : 'Không có món nào đạt bộ lọc.',
          style: theme.textTheme.bodyMedium,
        ),
      for (final item in items) ...[
        FoodResultCard(item: item, onTap: () => widget.onOpenFood(item)),
        const SizedBox(height: AppSpacing.sm),
      ],
    ];
  }
}
