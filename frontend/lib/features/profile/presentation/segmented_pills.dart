import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// One choice out of a few, drawn like the design's switch: a tinted track with the chosen option raised and ticked.
/// The options stack when their labels do not fit side by side (narrow screen, large text).
class SegmentedPills<T> extends StatelessWidget {
  const SegmentedPills({required this.options, required this.selected, required this.onSelected, super.key});

  /// Values in display order with their labels.
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  static const double _checkSize = 18;
  static const double _segmentPadding = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    final textScaler = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final gaps = AppSpacing.xs * (options.length + 1);
        final segmentWidth = (constraints.maxWidth - gaps) / options.length;
        final fits = options.values.every((label) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width + _checkSize + AppSpacing.xs + 2 * _segmentPadding <= segmentWidth;
        });
        final segments = [
          for (final MapEntry(key: value, value: label) in options.entries)
            _Segment(label: label, isSelected: value == selected, onTap: () => onSelected(value), style: style),
        ];

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.inner),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: fits
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.xs,
                      children: [for (final segment in segments) Expanded(child: segment)],
                    ),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpacing.xs, children: segments),
          ),
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.isSelected, required this.onTap, required this.style});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.inner - AppSpacing.xs);
    // White on the light track like the design; on the dark track a lighter tone, so the choice still stands out.
    final raised = theme.brightness == Brightness.dark ? colors.surfaceContainerHighest : colors.surfaceContainerLowest;
    final foreground = isSelected ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), offset: const Offset(0, 1), blurRadius: 3)]
              : null,
        ),
        child: Material(
          color: isSelected ? raised : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SegmentedPills._segmentPadding,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      Icon(Icons.check, size: SegmentedPills._checkSize, color: foreground),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: style?.copyWith(
                          color: foreground,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
