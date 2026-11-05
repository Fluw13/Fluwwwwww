import 'dart:async';

import 'package:flutter/material.dart';

import '../core/navigation/app_routes.dart';
import '../core/scanner/scanner_exit.dart';
import '../core/search/search_input.dart';
import '../core/theme/fluw_palette.dart';
import '../data/api/fluw_api_scope.dart';
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
  /// search-as-you-type.
  void _submitSearch() {
    final SearchInput input = SearchInput.parse(_searchController.text);
    setState(
      () => _inputError = input is InvalidSearchInput ? input.message : null,
    );

    switch (input) {
      case BarcodeSearchInput(:final String barcode):
        AppRoutes.openProduct(context, barcode);
      case KeywordSearchInput(:final String query):
        AppRoutes.openSearch(context, query);
      case EmptySearchInput() || InvalidSearchInput():
        break;
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fluw',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bạn đang ăn món gì?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        errorText: _inputError,
                        onSubmit: _submitSearch,
                      ),
                      const SizedBox(height: 30),
                      const _ZeroIntroCard(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryAction,
                    foregroundColor: palette.onPrimaryAction,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner, size: 26),
                  label: const Text(
                    'QUÉT MÃ VẠCH',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: 'Nhập mã vạch hoặc tên sản phẩm...',
        errorText: errorText,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Tìm',
          onPressed: onSubmit,
        ),
      ),
    );
  }
}

class _ZeroIntroCard extends StatelessWidget {
  const _ZeroIntroCard();

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: palette.accentText),
              const SizedBox(width: 8),
              const Text(
                'Trợ lý Zero AI',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quét mã vạch hoặc tìm theo tên để xem Điểm Fluw, tính từ dữ liệu Open Food Facts theo công thức công khai. '
            'Bấm "Hỏi Zero" để AI giải thích điểm.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
