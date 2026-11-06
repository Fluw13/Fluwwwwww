import 'package:flutter/material.dart';

import '../core/async/handled_future.dart';
import '../core/history/history_scope.dart';
import '../core/navigation/product_origin.dart';
import '../data/api/api_cancel_token.dart';
import '../data/api/fluw_api_client.dart';
import '../data/api/fluw_api_scope.dart';
import '../models/product/product_details.dart';
import '../models/product_summary.dart';
import '../widgets/async/api_error_view.dart';
import '../widgets/async/async_content.dart';
import '../widgets/product/product_detail_loading_view.dart';
import '../widgets/product/product_detail_view.dart';

/// Product page for one barcode (API v1). The request is aborted when the
/// screen closes and sent again only when the user taps retry.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.barcode,
    required this.origin,
  });

  final String barcode;
  final ProductOrigin origin;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiCancelToken _cancelToken = ApiCancelToken();
  late FluwApiClient _client;
  Future<ProductDetails>? _details;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _client = FluwApiScope.of(context);
    _details ??= _load();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<ProductDetails> _load() => handledLater(_loadAndRecord());

  /// A product enters the scan history only once it has loaded and while its
  /// page is still open; leaving early or a failed load records nothing.
  Future<ProductDetails> _loadAndRecord() async {
    final ProductDetails details = await _client.product(
      widget.barcode,
      cancelToken: _cancelToken,
    );
    if (mounted && widget.origin.recordsScan) {
      HistoryScope.read(context)?.addScan(ProductSummary.fromDetails(details));
    }
    return details;
  }

  void _retry() {
    setState(() {
      _details = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: AsyncContent<ProductDetails>(
        future: _details!,
        loadingBuilder: (_) =>
            ProductDetailLoadingView(barcode: widget.barcode),
        errorBuilder: (_, error) => ApiErrorView(error: error, onRetry: _retry),
        dataBuilder: (_, details) => ProductDetailView(
          details: details,
          loadAnalysis: (token) =>
              _client.analysis(details.product.barcode, cancelToken: token),
        ),
      ),
    );
  }
}
