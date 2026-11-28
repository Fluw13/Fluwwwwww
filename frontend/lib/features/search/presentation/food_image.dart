import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/features/search/domain/food_item.dart';
import 'package:fluw/features/search/domain/food_source.dart';

IconData foodIconFor(FoodItem item) => switch ((item.facts.unit, item.source)) {
  (QuantityUnit.milliliter, _) => Icons.local_drink_outlined,
  (_, FoodSource.usda) => Icons.eco_outlined,
  (_, FoodSource.openFoodFacts) => Icons.inventory_2_outlined,
  (_, FoodSource.custom) => Icons.edit_note_outlined,
};

/// A square of the Open Food Facts photo over an icon tile that shows while it loads, when it fails and when the
/// source has no photo. Never a stock picture: Fluw only shows the product's own photo. Left out of semantics: the
/// card next to it reads the name.
class FoodThumbnail extends StatelessWidget {
  const FoodThumbnail({required this.item, required this.size, super.key});

  final FoodItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: scheme.surfaceContainer,
              child: Icon(foodIconFor(item), size: size / 2.5, color: scheme.primary),
            ),
            if (imageUrl != null)
              Image.network(
                imageUrl.toString(),
                fit: BoxFit.cover,
                // Decode at the size shown instead of the photo's full size.
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
                excludeFromSemantics: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                    frame == null && !wasSynchronouslyLoaded ? const SizedBox.shrink() : child,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
