import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/app_card.dart';
import 'package:fluw/core/widgets/section_header.dart';

/// A card with the design's section header: small icon, title and optional trailing widget.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.children,
    this.icon,
    this.subtitle,
    this.accentColor,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final String? subtitle;

  /// Colour of the icon; defaults to the primary colour.
  final Color? accentColor;

  /// Shown after the title, e.g. an info button or a link.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: title, icon: icon, iconColor: accentColor, subtitle: subtitle, trailing: trailing),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}
