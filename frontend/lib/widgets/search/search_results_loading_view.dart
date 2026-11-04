import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../async/loading_status_banner.dart';
import '../skeleton/shimmer_scope.dart';
import 'search_result_tile.dart';

/// Placeholder rows in the same frame as real results, with the progress bar
/// and the status banner floating on top so nothing moves when data arrives.
class SearchResultsLoadingView extends StatelessWidget {
  const SearchResultsLoadingView({super.key, required this.query});

  static const int placeholderCount = 6;

  final String query;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ShimmerScope(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                AppSpacing.xxl,
              ),
              children: [
                for (int i = 0; i < placeholderCount; i++) ...[
                  const SizedBox(height: AppSpacing.sm + 2),
                  const SearchResultTile.loading(),
                ],
              ],
            ),
          ),
        ),
        if (!MediaQuery.disableAnimationsOf(context))
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              AppSpacing.lg,
            ),
            child: LoadingStatusBanner(
              title: 'Đang tìm sản phẩm',
              subtitle: 'Từ khóa “$query” · Open Food Facts',
              slowHint: 'Nếu máy chủ vừa khởi động, lần tìm đầu tiên có thể mất khoảng 1 phút.',
            ),
          ),
        ),
      ],
    );
  }
}
