import 'package:flutter/material.dart';
import 'package:fluw/features/search/domain/food_attribution.dart';

/// Source, data license and photo license, as Open Food Facts (ODbL, CC BY-SA) and USDA (CC0) require.
class AttributionFooter extends StatelessWidget {
  const AttributionFooter({required this.attribution, super.key});

  final FoodAttribution attribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageLicense = attribution.imageLicense;
    return SelectableText(
      [
        'Nguồn: ${attribution.source} (${attribution.license})',
        if (imageLicense != null) 'Ảnh: ${attribution.source} ($imageLicense)',
        attribution.url.toString(),
      ].join('\n'),
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
