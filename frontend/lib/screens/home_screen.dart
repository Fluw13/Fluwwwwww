import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/fluw_palette.dart';
import '../services/api_service.dart';
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
  late final ApiService _apiService;
  late final bool _ownsApiService;

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
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  void _searchProduct() {
    final String query = _searchController.text.trim();
    if (query.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(query: query)),
    );
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _SearchField(
                        controller: _searchController,
                        onSubmit: _searchProduct,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  const _SearchField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: 'Nhập mã vạch hoặc tên sản phẩm...',
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
            'Quét mã vạch bất kỳ đồ ăn hoặc thức uống để Zero phân tích chỉ số dinh dưỡng & chấm điểm sức khỏe.',
            style: TextStyle(color: palette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
