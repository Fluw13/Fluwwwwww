import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/barcode/gtin.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/network/api_failure_message.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/empty_state.dart';
import 'package:fluw/features/search/data/search_providers.dart';
import 'package:fluw/features/search/domain/custom_product_item.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/presentation/custom_product_form_screen.dart';
import 'package:fluw/features/search/presentation/food_detail_screen.dart';
import 'package:fluw/features/search/presentation/search_loading_view.dart';

/// Opened by a scanned or typed barcode: looks the product up once (the user's own products first, so a code they
/// typed in from a label answers without the network), then shows its detail screen.
class BarcodeLookupScreen extends ConsumerStatefulWidget {
  const BarcodeLookupScreen({required this.code, required this.onSearchByName, super.key});

  final String code;
  final VoidCallback onSearchByName;

  @override
  ConsumerState<BarcodeLookupScreen> createState() => _BarcodeLookupScreenState();
}

class _BarcodeLookupScreenState extends ConsumerState<BarcodeLookupScreen> {
  late Future<FoodItem?> _lookup = _start();

  Future<FoodItem?> _start() async {
    final api = ref.read(foodApiProvider);
    try {
      final stored = await ref.read(customProductRepositoryProvider).findByBarcode(widget.code);
      if (stored != null) {
        return foodItemFromCustomProduct(stored);
      }
    } on Object catch (error, stackTrace) {
      // A broken database only loses the user's own products; the backend can still answer.
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stackTrace, library: 'custom products'));
    }
    return api.lookUpBarcode(widget.code);
  }

  Future<void> _addFromLabel() async {
    final saved = await openCustomProductForm(context, barcode: widget.code);
    if (saved == null || !mounted) {
      return;
    }
    // The code can be corrected in the form; this page only shows a product that answers this code.
    if (saved.barcode case final code? when isSameGtin(code, widget.code)) {
      setState(() {
        _lookup = Future.value(foodItemFromCustomProduct(saved));
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Đã lưu ${saved.name} với mã khác mã ${widget.code}.')));
    }
  }

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
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(onPressed: _addFromLabel, child: const Text('Nhập từ nhãn')),
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
                  message:
                      'Máy này và Open Food Facts chưa có sản phẩm mã ${widget.code}. Bạn có thể chép số liệu từ '
                      'nhãn (lần sau quét sẽ ra ngay) hoặc tìm theo tên.',
                ),
                FilledButton(onPressed: _addFromLabel, child: const Text('Nhập từ nhãn')),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(onPressed: widget.onSearchByName, child: const Text('Tìm theo tên')),
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
