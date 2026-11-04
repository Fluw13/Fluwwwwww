import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';
import '../../models/search/search_results.dart';
import '../common/section_title.dart';
import 'search_result_tile.dart';

/// Results of one search. Near matches are labelled as such, and an empty
/// result says so instead of showing an unrelated product.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.query,
    required this.results,
    required this.onOpen,
  });

  static const String approximateNote =
      'Không có sản phẩm khớp đủ từ khóa, đây là kết quả gần đúng.';

  final String query;
  final SearchResults results;
  final ValueChanged<SearchResultItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return _EmptyResults(query: query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.xxl,
      ),
      children: [
        SectionTitle('${results.items.length} kết quả cho “$query”'),
        if (results.isApproximate) ...[
          const SizedBox(height: AppSpacing.sm),
          const _ApproximateNote(),
        ],
        for (final SearchResultItem item in results.items) ...[
          const SizedBox(height: AppSpacing.sm + 2),
          SearchResultTile(item: item, onTap: () => onOpen(item)),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Dữ liệu: Open Food Facts · ODbL · ảnh CC BY-SA',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.palette.textSecondary),
        ),
      ],
    );
  }
}

class _ApproximateNote extends StatelessWidget {
  const _ApproximateNote();

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              SearchResultsList.approximateNote,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 32,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Không tìm thấy sản phẩm phù hợp với “$query”.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Thử từ khóa khác, viết đủ dấu, hoặc quét mã vạch trên bao bì.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
