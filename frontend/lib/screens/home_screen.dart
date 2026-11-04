import 'dart:async';

import 'package:flutter/material.dart';

import '../core/history/history_kind.dart';
import '../core/history/history_scope.dart';
import '../core/history/session_history.dart';
import '../core/navigation/product_origin.dart';
import '../core/scanner/scanner_exit.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/product_summary.dart';
import '../services/api_service.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/product_search_field.dart';
import '../widgets/home/recent_scans_section.dart';
import '../widgets/home/recent_searches.dart';
import '../widgets/home/scan_button.dart';
import '../widgets/home/zero_intro_card.dart';
import 'account_screen.dart';
import 'history_screen.dart';
import 'product_detail_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final ApiService _apiService;
  late final bool _ownsApiService;
  bool _isScannerOpen = false;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget.apiService == null;
    _apiService = widget.apiService ?? ApiService();
    unawaited(_apiService.wakeUpServer());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  void _openProduct(String query, ProductOrigin origin) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(query: query, origin: origin, apiService: _apiService)),
    );
  }

  void _search(String query) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;

    HistoryScope.read(context)?.addSearch(trimmed);
    _openProduct(trimmed, ProductOrigin.search);
  }

  void _openRecentScan(ProductSummary product) {
    _openProduct(product.barcode.isNotEmpty ? product.barcode : product.name, ProductOrigin.history);
  }

  void _openScanHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HistoryScreen(kind: HistoryKind.scans, apiService: _apiService)),
    );
  }

  void _openAccount() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen(apiService: _apiService)));
  }

  Future<void> _openScanner() async {
    if (_isScannerOpen) return;
    _isScannerOpen = true;

    final ScannerExit? exit = await Navigator.push<ScannerExit>(
      context,
      MaterialPageRoute(builder: (_) => ScannerScreen(apiService: _apiService)),
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
                    style: TextStyle(fontSize: 26, height: 1.25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Quét mã vạch hoặc tìm theo tên để Zero chấm điểm.',
                    style: TextStyle(fontSize: 15, height: 1.45, color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ProductSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
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
                    RecentScansSection(scans: scans, onOpen: _openRecentScan, onSeeAll: _openScanHistory),
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
