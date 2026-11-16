import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/empty_state.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';
import 'package:fluw/features/search/presentation/search_loading_view.dart';

/// Opened by a scanned or typed barcode: looks the product up once, then shows its detail screen.
class BarcodeLookupScreen extends ConsumerStatefulWidget {
  const BarcodeLookupScreen({required this.code, required this.onSearchByName, super.key});

  final String code;
  final VoidCallback onSearchByName;

  @override
  ConsumerState<BarcodeLookupScreen> createState() => _BarcodeLookupScreenState();
}

class _BarcodeLookupScreenState extends ConsumerState<BarcodeLookupScreen> {
  late Future<FoodItem?> _lookup = _start();

  Future<FoodItem?> _start() => ref.read(foodApiProvider).lookUpBarcode(widget.code);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FoodItem?>(
      future: _lookup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _Frame(code: widget.code, child: const SearchLoadingView());
        }
        if (snapshot.error case final ApiFailure failure) {
          return _Frame(
            code: widget.code,
            child: Column(
              children: [
                EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Chưa tra được mã',
                  message: apiFailureMessage(failure),
                ),
                FilledButton(
                  onPressed: () => setState(() {
                    _lookup = _start();
                  }),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        if (snapshot.error case final Object error) {
          Error.throwWithStackTrace(error, snapshot.stackTrace ?? StackTrace.current);
        }
        final item = snapshot.data;
        if (item == null) {
          return _Frame(
            code: widget.code,
            child: Column(
              children: [
                EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Chưa có sản phẩm này',
                  message: 'Open Food Facts chưa có sản phẩm mã ${widget.code}. Bạn có thể tìm theo tên sản phẩm.',
                ),
                FilledButton(onPressed: widget.onSearchByName, child: const Text('Tìm theo tên')),
                const SizedBox(height: AppSpacing.sm),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Quét mã khác')),
              ],
            ),
          );
        }
        return FoodDetailScreen(item: item, isFullProduct: true);
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.code, required this.child});

  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mã $code')),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [child]),
    );
  }
}
