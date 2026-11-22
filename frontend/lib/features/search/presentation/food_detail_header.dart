import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/serving_size.dart';
import 'package:fluw/features/search/presentation/food_image.dart';
import 'package:fluw/features/search/presentation/search_labels.dart';

/// The product's photo (when the source has one), its source, name, brand, barcode and the serving printed on the
/// pack.
class FoodDetailHeader extends StatelessWidget {
  const FoodDetailHeader({required this.item, super.key});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final details = [?item.brand, if (item.barcode case final code?) 'Mã $code'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.imageUrl case final imageUrl?) _HeroImage(item: item, url: imageUrl),
        Row(
          children: [
            Icon(foodIconFor(item), size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                foodSourceLabel(item.source),
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(item.name ?? 'Chưa có tên', style: theme.textTheme.headlineSmall),
        if (details.isNotEmpty) Text(details.join(' · '), style: muted),
        if (printedServing(item.servingSize) case final serving?) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.scale_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Khẩu phần ghi trên bao bì: $serving', style: muted)),
            ],
          ),
        ],
      ],
    );
  }
}

/// The product photo in a card of fixed height (a ratio would fill a tablet or landscape screen). An icon holds the
/// place while it loads; a photo that fails takes no room at all.
class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.item, required this.url});

  static const double height = 220;

  final FoodItem item;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Image.network(
      url.toString(),
      height: height,
      // Decode at screen width instead of the photo's full size.
      cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
      fit: BoxFit.contain,
      semanticLabel: 'Ảnh sản phẩm',
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: ColoredBox(
            color: frame == null && !wasSynchronouslyLoaded ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: frame == null && !wasSynchronouslyLoaded
                  ? Icon(foodIconFor(item), size: 56, color: scheme.primary)
                  : child,
            ),
          ),
        ),
      ),
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
