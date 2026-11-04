import 'package:flutter/material.dart';

import '../core/history/history_scope.dart';
import '../core/navigation/product_origin.dart';
import '../models/product_model.dart';
import '../models/product_summary.dart';
import '../services/api_service.dart';
import '../widgets/async/async_content.dart';
import '../widgets/async/error_retry_view.dart';
import '../widgets/product/product_detail_loading_view.dart';
import '../widgets/product/product_detail_view.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.query, required this.origin, this.apiService});

  final String query;
  final ProductOrigin origin;
  final ApiService? apiService;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ApiService _apiService;
  late final bool _ownsApiService;
  late Future<ProductModel> _productFuture;

  @override
  void initState() {
    super.initState();
    _ownsApiService = widget.apiService == null;
    _apiService = widget.apiService ?? ApiService();
    _productFuture = _load();
  }

  @override
  void dispose() {
    if (_ownsApiService) {
      _apiService.dispose();
    }
    super.dispose();
  }

  /// A product enters the scan history only once it has loaded and while its
  /// page is still open; leaving early records nothing.
  Future<ProductModel> _load() async {
    final ProductModel product = await _apiService.fetchProduct(widget.query);
    if (mounted && widget.origin.recordsScan) {
      HistoryScope.read(context)?.addScan(ProductSummary.fromProduct(product));
    }
    return product;
  }

  void _retry() {
    setState(() {
      _productFuture = _load();
    });
  }

  static String _messageFor(Object error) {
    return error is ApiException ? error.message : 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: AsyncContent<ProductModel>(
        future: _productFuture,
        loadingBuilder: (_) => ProductDetailLoadingView(query: widget.query),
        errorBuilder: (_, error) => ErrorRetryView(message: _messageFor(error), onRetry: _retry),
        dataBuilder: (_, product) => ProductDetailView(product: product),
      ),
    );
  }
}
