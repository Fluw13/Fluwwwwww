import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// A white card with the coloured bar and title used by every form section in the design.
class SectionCard extends StatelessWidget {
  const SectionCard({required this.title, required this.children, this.accentColor, this.trailing, super.key});

  final String title;
  final List<Widget> children;

  /// Defaults to the primary colour.
  final Color? accentColor;

  /// Shown after the title, e.g. an info button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
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
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
