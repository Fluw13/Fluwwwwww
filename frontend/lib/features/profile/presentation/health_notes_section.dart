import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/theme/readable_color.dart';
import 'package:fluw/core/widgets/section_header.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

/// Allergies (severe in red, mild in amber), health conditions and the free-text notes, one card each, as in the
/// design's "Tiền sử bệnh & dị ứng". Says only what Fluw does with each: the conditions keep their own description.
class HealthNotesSection extends StatelessWidget {
  const HealthNotesSection({required this.profile, required this.onEdit, super.key});

  /// Only these conditions change a target or a warning; the others are notes.
  static const Set<HealthCondition> _tracked = {
    HealthCondition.diabetes,
    HealthCondition.hypertension,
    HealthCondition.dyslipidemia,
  };

  final HealthProfile profile;

  /// Opens the profile form, where allergies and conditions are added.
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dietary = profile.dietary;
    // Severe first, so the most important warning is read first.
    final allergies = dietary.allergies.entries.toList()..sort((a, b) => a.value.index.compareTo(b.value.index));
    final count = allergies.length + profile.conditions.length;
    final conditionNote = profile.conditionNote;
    final allergyNote = dietary.allergyNote;

    final cards = [
      for (final MapEntry(key: allergen, value: severity) in allergies)
        severity == AllergySeverity.severe
            ? _NoteCard(
                overline: 'Mức: ${allergySeverityLabel(severity)}',
                title: allergenLabel(allergen),
                icon: Icons.gpp_maybe_outlined,
                background: colors.errorContainer,
                foreground: colors.onErrorContainer,
                accent: colors.error,
              )
            : _NoteCard(
                overline: 'Mức: ${allergySeverityLabel(severity)}',
                title: allergenLabel(allergen),
                icon: Icons.info_outline,
                background: colors.tertiaryContainer,
                foreground: colors.onTertiaryContainer,
                accent: colors.tertiary,
              ),
      if (allergyNote != null)
        _NoteCard(
          overline: 'Dị ứng khác (chỉ ghi chú)',
          body: allergyNote,
          icon: Icons.note_alt_outlined,
          background: colors.surfaceContainerLow,
          foreground: colors.onSurface,
          accent: colors.onSurfaceVariant,
        ),
      for (final condition in profile.conditions)
        _tracked.contains(condition)
            ? _NoteCard(
                overline: 'Bệnh nền',
                title: healthConditionLabel(condition),
                body: healthConditionDescription(condition),
                icon: Icons.health_and_safety_outlined,
                background: colors.tertiaryContainer,
                foreground: colors.onTertiaryContainer,
                accent: colors.tertiary,
              )
            : _NoteCard(
                overline: 'Bệnh nền',
                title: healthConditionLabel(condition),
                body: healthConditionDescription(condition),
                icon: Icons.note_alt_outlined,
                background: colors.surfaceContainerLow,
                foreground: colors.onSurface,
                accent: colors.onSurfaceVariant,
              ),
      if (conditionNote != null)
        _NoteCard(
          overline: 'Bệnh khác (chỉ ghi chú)',
          body: conditionNote,
          icon: Icons.note_alt_outlined,
          background: colors.surfaceContainerLow,
          foreground: colors.onSurface,
          accent: colors.onSurfaceVariant,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Dị ứng & bệnh nền',
          icon: Icons.medical_information_outlined,
          iconColor: colors.error,
          trailing: count == 0 ? null : _CountBadge(count: count),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (allergies.isNotEmpty) ...[
          Text(
            'Fluw cảnh báo khi Open Food Facts ghi sản phẩm có nhóm dị ứng này. Dữ liệu có thể thiếu: luôn đọc nhãn '
            'trên bao bì.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (cards.isEmpty)
          Text('Chưa khai báo dị ứng hay bệnh nền.', style: theme.textTheme.bodyMedium)
        else
          for (final card in cards)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: card,
            ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          button: true,
          child: Material(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: colors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Thêm dị ứng / bệnh nền',
                          style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.overline,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.accent,
    this.title,
    this.body,
  });

  final String overline;
  final String? title;
  final String? body;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    final body = this.body;
    final accentText = readableOn(accent, background);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.inner),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(overline, style: theme.textTheme.labelSmall?.copyWith(color: accentText)),
                if (title != null) ...[
                  const SizedBox(height: 2),
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(color: foreground)),
                ],
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: theme.textTheme.bodySmall?.copyWith(color: foreground)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count mục',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 24),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(999)),
        child: Text(
          '$count',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
