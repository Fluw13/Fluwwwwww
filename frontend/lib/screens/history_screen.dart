import 'package:flutter/material.dart';

import '../core/history/history_kind.dart';
import '../core/history/history_scope.dart';
import '../core/history/session_history.dart';
import '../core/navigation/product_origin.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/product_summary.dart';
import '../services/api_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/product/product_card.dart';
import 'product_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.kind, this.apiService});

  static const String sessionNote = 'Chỉ lưu trong lần mở ứng dụng này và mất khi bạn đóng ứng dụng.';

  final HistoryKind kind;
  final ApiService? apiService;

  void _openProduct(BuildContext context, String query, ProductOrigin origin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(query: query, origin: origin, apiService: apiService)),
    );
  }

  void _openScan(BuildContext context, ProductSummary product) {
    _openProduct(context, product.barcode.isNotEmpty ? product.barcode : product.name, ProductOrigin.history);
  }

  void _openSearch(BuildContext context, SessionHistory history, String query) {
    history.addSearch(query);
    _openProduct(context, query, ProductOrigin.search);
  }

  Future<void> _confirmClear(BuildContext context, SessionHistory history) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ${kind.title.toLowerCase()}?'),
        content: const Text('Thao tác này không hoàn tác được.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true) return;

    switch (kind) {
      case HistoryKind.scans:
        history.clearScans();
      case HistoryKind.searches:
        history.clearSearches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final SessionHistory? history = HistoryScope.watch(context);
    final bool isEmpty = switch (kind) {
      HistoryKind.scans => history?.scans.isEmpty ?? true,
      HistoryKind.searches => history?.searches.isEmpty ?? true,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(kind.title),
        actions: [
          if (history != null && !isEmpty)
            TextButton(onPressed: () => _confirmClear(context, history), child: const Text('Xóa')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            Text(sessionNote, style: TextStyle(fontSize: 13, height: 1.45, color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            if (history == null || isEmpty)
              switch (kind) {
                HistoryKind.scans => const EmptyState(
                    icon: Icons.qr_code_scanner,
                    title: 'Chưa quét sản phẩm nào',
                    message: 'Sản phẩm bạn quét sẽ hiện ở đây.',
                  ),
                HistoryKind.searches => const EmptyState(
                    icon: Icons.search,
                    title: 'Chưa tìm kiếm gì',
                    message: 'Những gì bạn tìm sẽ hiện ở đây.',
                  ),
              }
            else
              ...switch (kind) {
                HistoryKind.scans => [
                    for (final ProductSummary product in history.scans)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ProductCard(product: product, onTap: () => _openScan(context, product)),
                      ),
                  ],
                HistoryKind.searches => [
                    for (final String query in history.searches)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history),
                        title: Text(query),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openSearch(context, history, query),
                      ),
                  ],
              },
          ],
        ),
      ),
    );
  }
}
