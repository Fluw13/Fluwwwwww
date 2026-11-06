import 'dart:async';

import 'package:flutter/material.dart';

import '../core/history/history_kind.dart';
import '../core/history/history_scope.dart';
import '../core/history/session_history.dart';
import '../core/navigation/app_routes.dart';
import '../core/navigation/product_origin.dart';
import '../core/scanner/scanner_exit.dart';
import '../core/search/search_input.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../data/api/fluw_api_scope.dart';
import '../models/product_summary.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/product_search_field.dart';
import '../widgets/home/recent_scans_section.dart';
import '../widgets/home/recent_searches.dart';
import '../widgets/home/scan_button.dart';
import '../widgets/home/zero_intro_card.dart';
import 'account_screen.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _wakeUpSent = false;
  bool _isScannerOpen = false;
  String? _inputError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_wakeUpSent) return;
    _wakeUpSent = true;
    unawaited(FluwApiScope.of(context).wakeUp());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Only runs when the user submits: Open Food Facts forbids
  /// search-as-you-type. A barcode opens the product, anything else the
  /// search results; input the server would reject is reported here.
  void _search(String query) {
    final SearchInput input = SearchInput.parse(query);
    setState(
      () => _inputError = input is InvalidSearchInput ? input.message : null,
    );

    if (AppRoutes.openSearchInput(context, input)) {
      HistoryScope.read(context)?.addSearch(query);
    }
  }

  void _openRecentScan(ProductSummary product) {
    AppRoutes.openProduct(
      context,
      product.barcode,
      origin: ProductOrigin.history,
    );
  }

  void _openScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryScreen(kind: HistoryKind.scans),
      ),
    );
  }

  void _openAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
  }

  Future<void> _openScanner() async {
    if (_isScannerOpen) return;
    _isScannerOpen = true;

    final ScannerExit? exit = await Navigator.push<ScannerExit>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    _isScannerOpen = false;
    if (exit == ScannerExit.manualEntry && mounted) {
      _searchFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final SessionHistory? history = HistoryScope.watch(context);
    final List<ProductSummary> scans = history?.scans ?? const [];
    final List<String> searches = history?.searches ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeHeader(onOpenAccount: _openAccount),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                ),
                children: [
                  const Text(
                    'Bạn đang ăn món gì?',
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Quét mã vạch hoặc tìm theo tên để xem Điểm Fluw.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProductSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    errorText: _inputError,
                    onSubmit: () => _search(_searchController.text),
                  ),
                  if (searches.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    RecentSearches(queries: searches, onSelected: _search),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  if (scans.isEmpty)
                    const ZeroIntroCard()
                  else
                    RecentScansSection(
                      scans: scans,
                      onOpen: _openRecentScan,
                      onSeeAll: _openScanHistory,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: ScanButton(onPressed: _openScanner),
            ),
          ],
        ),
      ),
    );
  }
}
