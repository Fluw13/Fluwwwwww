import 'package:flutter/material.dart';

import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../models/analysis/product_analysis.dart';
import 'async/retry_countdown_button.dart';
import 'common/info_chip.dart';
import 'common/section_title.dart';
import 'product/product_detail_metrics.dart';
import 'skeleton/skeleton_box.dart';

/// Zero's card. Every form keeps the same frame, title and "Nội dung do AI
/// tạo" label; only the body changes. Zero explains the Fluw score, it never
/// gives one, so nothing here shows a score.
class ZeroAnalysisCard extends StatelessWidget {
  /// Placeholder lines. With [announce] screen readers hear that Zero is
  /// writing; the page skeleton leaves it off.
  const ZeroAnalysisCard.loading({super.key, bool announce = false})
    : _body = announce ? _announcedLoading : _silentLoading;

  /// Default form: nothing is requested until the user asks.
  ZeroAnalysisCard.prompt({super.key, required VoidCallback onAsk})
    : _body = _PromptBody(onAsk);

  ZeroAnalysisCard.result({
    super.key,
    required ZeroExplanation explanation,
    String? disclaimer,
    String? versionNote,
  }) : _body = _ResultBody(
         explanation: explanation,
         disclaimer: disclaimer,
         versionNote: versionNote,
       );

  /// Why there is no explanation, with a retry button when it can help.
  ZeroAnalysisCard.message({
    super.key,
    required String message,
    VoidCallback? onRetry,
    Duration? retryAfter,
  }) : _body = _MessageBody(
         message: message,
         onRetry: onRetry,
         retryAfter: retryAfter,
       );

  static const String title = 'Zero giải thích điểm';
  static const String aiLabel = 'Nội dung do AI tạo';
  static const String askLabel = 'Hỏi Zero';
  static const String writingText = 'Zero đang viết giải thích…';
  static const String defaultDisclaimer =
      'Nội dung do AI tạo, có thể chưa chính xác. AI không chấm điểm. '
      'Đây là thông tin tham khảo, không phải chẩn đoán hay tư vấn y tế.';

  static const double bodySize = 14;
  static const double bodyHeight = 1.55;

  static const Widget _silentLoading = _LoadingBody(announce: false);
  static const Widget _announcedLoading = _LoadingBody(announce: true);

  final Widget _body;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: ProductDetailMetrics.analysisCardPadding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 18, color: palette.accentText),
              const SectionTitle(title),
              InfoChip(
                label: aiLabel,
                foreground: palette.textSecondary,
                background: palette.surfaceMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          _body,
        ],
      ),
    );
  }
}

TextStyle _bodyStyle(BuildContext context) {
  return TextStyle(
    fontSize: ZeroAnalysisCard.bodySize,
    height: ZeroAnalysisCard.bodyHeight,
    color: context.palette.textPrimary,
  );
}

TextStyle _noteStyle(BuildContext context) {
  return TextStyle(
    color: context.palette.textSecondary,
    fontSize: 12,
    height: 1.5,
  );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.announce});

  final bool announce;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (announce) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              ZeroAnalysisCard.writingText,
              style: _noteStyle(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        const SkeletonBox.text(
          fontSize: ZeroAnalysisCard.bodySize,
          lineHeight: ZeroAnalysisCard.bodyHeight,
        ),
        const SkeletonBox.text(
          fontSize: ZeroAnalysisCard.bodySize,
          lineHeight: ZeroAnalysisCard.bodyHeight,
        ),
        const FractionallySizedBox(
          widthFactor: 0.7,
          child: SkeletonBox.text(
            fontSize: ZeroAnalysisCard.bodySize,
            lineHeight: ZeroAnalysisCard.bodyHeight,
          ),
        ),
      ],
    );
  }
}

class _PromptBody extends StatelessWidget {
  const _PromptBody(this.onAsk);

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zero có thể giải thích vì sao sản phẩm có điểm này, dựa trên dữ liệu ở trang này.',
          style: _bodyStyle(context),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: onAsk,
          icon: const Icon(Icons.auto_awesome),
          label: const Text(ZeroAnalysisCard.askLabel),
        ),
      ],
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.explanation,
    required this.disclaimer,
    required this.versionNote,
  });

  final ZeroExplanation explanation;
  final String? disclaimer;
  final String? versionNote;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = _bodyStyle(context);
    final TextStyle heading = body.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );
    final String? recommendation = explanation.recommendation;
    final String? versionNote = this.versionNote;

    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text('• $text', style: body),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(explanation.summary, style: body),
        if (explanation.highlights.isNotEmpty) ...[
          const Divider(height: 24),
          Text('Điểm chính', style: heading),
          for (final String highlight in explanation.highlights)
            bullet(highlight),
        ],
        if (recommendation != null) ...[
          const Divider(height: 24),
          Text('Gợi ý', style: heading),
          const SizedBox(height: AppSpacing.xs),
          Text(recommendation, style: body),
        ],
        if (explanation.alternatives.isNotEmpty) ...[
          const Divider(height: 24),
          Text('Nhóm sản phẩm có thể cân nhắc', style: heading),
          for (final String alternative in explanation.alternatives)
            bullet(alternative),
        ],
        if (versionNote != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(versionNote, style: _noteStyle(context)),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          disclaimer ?? ZeroAnalysisCard.defaultDisclaimer,
          style: _noteStyle(context),
        ),
      ],
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.message,
    required this.onRetry,
    required this.retryAfter,
  });

  final String message;
  final VoidCallback? onRetry;
  final Duration? retryAfter;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onRetry = this.onRetry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(message, style: _bodyStyle(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Điểm Fluw ở trên vẫn đầy đủ: điểm do Fluw tính, không phụ thuộc AI.',
          style: _noteStyle(context),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.md),
          RetryCountdownButton(
            onRetry: onRetry,
            retryAfter: retryAfter,
            tonal: true,
          ),
        ],
      ],
    );
  }
}
