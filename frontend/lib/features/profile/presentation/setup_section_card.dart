import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/app_card.dart';

/// A numbered step of the profile form: a coloured marker before the title, as in the design.
class SetupSectionCard extends StatelessWidget {
  const SetupSectionCard({required this.title, required this.children, this.markerColor, super.key});

  final String title;
  final List<Widget> children;

  /// Defaults to the primary colour.
  final Color? markerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 6,
                    height: 22,
                    decoration: BoxDecoration(
                      color: markerColor ?? theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
