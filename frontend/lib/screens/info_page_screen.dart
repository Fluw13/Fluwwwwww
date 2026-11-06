import 'package:flutter/material.dart';

import '../content/info_page.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/fluw_palette.dart';
import '../widgets/common/section_title.dart';

class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({super.key, required this.page});

  final InfoPage page;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final String? notice = page.notice;

    return Scaffold(
      appBar: AppBar(title: Text(page.title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            if (notice != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: palette.textPrimary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(notice, style: TextStyle(fontSize: 14, height: 1.5, color: palette.textPrimary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            for (final InfoSection section in page.sections) ...[
              SectionTitle(section.heading),
              const SizedBox(height: AppSpacing.sm),
              for (final String paragraph in section.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(paragraph, style: TextStyle(fontSize: 15, height: 1.55, color: palette.textPrimary)),
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}
