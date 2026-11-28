import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/network/api_failure_message.dart';
import 'package:fluw/core/search/search_request.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/domain/card_nutrition.dart';
import 'package:fluw/features/search/domain/custom_product_item.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';
import 'package:fluw/features/search/domain/search_response.dart';
import 'package:fluw/features/search/presentation/custom_product_form_screen.dart';
import 'package:fluw/features/search/presentation/food_result_card.dart';
import 'package:fluw/features/search/presentation/quick_filter_bar.dart';
import 'package:fluw/features/search/presentation/recent_food_sheet.dart';
import 'package:fluw/features/search/presentation/recent_foods_section.dart';
import 'package:fluw/features/search/presentation/recent_searches_bar.dart';
import 'package:fluw/features/search/presentation/recent_searches_controller.dart';
import 'package:fluw/features/search/presentation/search_controller.dart';
import 'package:fluw/features/search/presentation/search_field.dart';
import 'package:fluw/features/search/presentation/search_loading_view.dart';
import 'package:fluw/features/search/presentation/search_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({required this.onOpenFood, required this.onOpenScan, super.key});

  /// Completes when the detail screen closes, so the list can show a product the user changed or deleted there.
  final Future<void> Function(FoodItem item) onOpenFood;

  /// The barcode button in the search box opens the scan tab.
  final VoidCallback onOpenScan;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  Set<QuickFilter> _filters = const {};

  @override
  void initState() {
    super.initState();
    // Searches asked for by other tabs (a food recognized in a photo). Run after the frame: the screen may be built
    // for the first time by that very request.
    ref.listenManual<SearchRequest?>(searchRequestProvider, (_, request) {
      if (request != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(searchRequestProvider.notifier).clear();
            _search(request.query, englishQuery: request.englishQuery);
          }
        });
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String text, {String? englishQuery}) async {
    final query = normalizeQuery(text);
    if (query.length < minSearchLength || query.length > maxSearchLength) {
      return;
    }
    _query.text = query;
    FocusScope.of(context).unfocus();
    await ref.read(recentSearchesProvider.notifier).add(query);
    await ref.read(searchControllerProvider.notifier).search(query, englishQuery: englishQuery);
  }

  Future<void> _openFood(FoodItem item) async {
    await widget.onOpenFood(item);
    if (mounted) {
      await ref.read(searchControllerProvider.notifier).refreshStoredProducts();
    }
  }

  Future<void> _addFromLabel() async {
    final saved = await openCustomProductForm(context);
    if (saved != null && mounted) {
      await ref.read(searchControllerProvider.notifier).refreshStoredProducts();
      if (mounted) {
        await _openFood(foodItemFromCustomProduct(saved));
      }
    }
  }

  Widget _addFromLabelButton(String text) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(onPressed: _addFromLabel, icon: const Icon(Icons.edit_note_outlined), label: Text(text)),
  );

  void _clear() {
    _query.clear();
    ref.read(searchControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(searchControllerProvider);
    final recent = ref.watch(recentSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        SearchField(controller: _query, onSubmitted: _search, onClear: _clear, onOpenScan: widget.onOpenScan),
        const SizedBox(height: AppSpacing.md),
        QuickFilterBar(selected: _filters, onChanged: (filters) => setState(() => _filters = filters)),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          RecentSearchesBar(
            queries: recent,
            onSearch: _search,
            onRemove: (query) => ref.read(recentSearchesProvider.notifier).remove(query),
            onClearAll: () => ref.read(recentSearchesProvider.notifier).clear(),
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
        RecentFoodsSection(onSelected: (food) => showRecentFoodSheet(context, food)),
        Text(
          'Nhập tên thực phẩm rồi bấm tìm. Dữ liệu lấy từ sản phẩm bạn tự nhập, Open Food Facts và USDA FoodData '
          'Central.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        _addFromLabelButton('Nhập sản phẩm từ nhãn'),
      ],
      SearchLoading() => [const SearchLoadingView()],
      SearchFailed(:final query, :final failure, :final englishQuery) => [
        Text(apiFailureMessage(failure), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () => ref.read(searchControllerProvider.notifier).search(query, englishQuery: englishQuery),
            child: const Text('Thử lại'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _addFromLabelButton('Nhập sản phẩm từ nhãn'),
      ],
      SearchLoaded(:final response, :final englishQuery, :final failure) => _loaded(
        response,
        englishQuery,
        failure,
        theme,
      ),
    };
  }

  List<Widget> _loaded(SearchResponse response, String? englishQuery, ApiFailure? failure, ThemeData theme) {
    // Kept in the sources' order: a result without numbers is often the right product, whose numbers the detail
    // screen gets from the barcode lookup.
    final items = applyQuickFilters(response.items, _filters);
    final hidden = response.items.where((item) => !_filters.every((filter) => filter.matches(item)));
    final hiddenByFilters = hidden.length;
    final hiddenWithoutData = hidden.where((item) => !hasCardNutrition(item)).length;
    final hiddenSuspect = hidden.where((item) => item.nutrientsSuspect && hasCardNutrition(item)).length;
    return [
      Row(
        children: [
          Icon(Icons.manage_search, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('${items.length} kết quả cho "${response.query}"', style: theme.textTheme.titleMedium)),
        ],
      ),
      if (englishQuery != null)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            'Đã tìm thêm bằng tiếng Anh: $englishQuery',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      if (failure != null) ...[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            '${apiFailureMessage(failure)} Chỉ hiện sản phẩm bạn tự nhập.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: () =>
                ref.read(searchControllerProvider.notifier).search(response.query, englishQuery: englishQuery),
            child: const Text('Thử lại'),
          ),
        ),
      ] else if (response.isPartial)
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
            [
              'Đã ẩn $hiddenByFilters món không đạt bộ lọc hoặc thiếu số liệu để lọc.',
              if (hiddenWithoutData > 0)
                '$hiddenWithoutData món chưa có số liệu trong kết quả tìm kiếm: bỏ lọc rồi mở món để xem.',
              if (hiddenSuspect > 0) '$hiddenSuspect món có số liệu nguồn có thể sai.',
            ].join(' '),
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
        FoodResultCard(item: item, onTap: () => _openFood(item)),
        const SizedBox(height: AppSpacing.sm),
      ],
      _addFromLabelButton('Không thấy sản phẩm? Nhập từ nhãn'),
    ];
  }
}
