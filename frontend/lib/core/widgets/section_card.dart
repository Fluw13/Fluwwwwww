import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// A white card with the coloured bar and title used by every form section in the design.
class SectionCard extends StatelessWidget {
  const SectionCard({required this.title, required this.children, this.accentColor, super.key});

  final String title;
  final List<Widget> children;

  /// Defaults to the primary colour.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor ?? theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
