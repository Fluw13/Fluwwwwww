import 'package:flutter/material.dart';

import '../../core/async/handled_future.dart';
import '../../core/format/ai_error_text.dart';
import '../../data/api/api_cancel_token.dart';
import '../../data/api/fluw_api_exception.dart';
import '../../models/analysis/product_analysis.dart';
import '../async/api_error_view.dart';
import '../async/async_content.dart';
import '../zero_analysis_card.dart';

typedef AnalysisLoader = Future<ProductAnalysis> Function(
  ApiCancelToken cancelToken,
);

/// Zero's explanation, loaded on its own after the product is on screen: by
/// default only when the user taps "Hỏi Zero". Its failures never touch the
/// product or the score above it.
class ZeroAnalysisSection extends StatefulWidget {
  const ZeroAnalysisSection({
    super.key,
    required this.loadAnalysis,
    required this.scoreVersion,
    this.autoLoad = false,
  });

  final AnalysisLoader loadAnalysis;

  /// Formula of the score on screen, to flag an explanation written for another.
  final String? scoreVersion;
  final bool autoLoad;

  @override
  State<ZeroAnalysisSection> createState() => _ZeroAnalysisSectionState();
}

class _ZeroAnalysisSectionState extends State<ZeroAnalysisSection> {
  final ApiCancelToken _cancelToken = ApiCancelToken();
  Future<ProductAnalysis>? _analysis;

  @override
  void initState() {
    super.initState();
    if (widget.autoLoad) _analysis = _load();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<ProductAnalysis> _load() =>
      handledLater(widget.loadAnalysis(_cancelToken));

  void _ask() {
    setState(() {
      _analysis = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Future<ProductAnalysis>? analysis = _analysis;
    if (analysis == null) return ZeroAnalysisCard.prompt(onAsk: _ask);

    return AsyncContent<ProductAnalysis>(
      future: analysis,
      loadingBuilder: (_) => const ZeroAnalysisCard.loading(announce: true),
      errorBuilder: (_, error) => _errorCard(error),
      dataBuilder: (_, result) => _resultCard(result),
    );
  }

  Widget _errorCard(Object error) {
    if (error is! FluwApiException) {
      return ZeroAnalysisCard.message(
        message: ApiErrorView.unexpectedMessage,
        onRetry: _ask,
      );
    }
    return ZeroAnalysisCard.message(
      message: error.message,
      onRetry: error.canRetry ? _ask : null,
      retryAfter: error.retryAfter,
    );
  }

  Widget _resultCard(ProductAnalysis result) {
    final ZeroExplanation? explanation = result.explanation;
    if (explanation == null) {
      final AiErrorCode code = result.aiError ?? AiErrorCode.unknown;
      return ZeroAnalysisCard.message(
        message: AiErrorText.message(code),
        onRetry: AiErrorText.canRetry(code) ? _ask : null,
      );
    }

    final String? written = result.scoreVersion;
    final String? shown = widget.scoreVersion;
    final bool otherVersion =
        written != null && shown != null && written != shown;
    return ZeroAnalysisCard.result(
      explanation: explanation,
      disclaimer: result.disclaimer,
      versionNote: otherVersion
          ? 'Giải thích này viết cho công thức $written, khác công thức $shown của điểm ở trên; số liệu có thể không khớp.'
          : null,
    );
  }
}
