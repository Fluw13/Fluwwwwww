import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

class AllergiesSection extends StatelessWidget {
  const AllergiesSection({
    required this.allergies,
    required this.onAllergyChanged,
    required this.noteController,
    super.key,
  });

  static const int maxNoteLength = 200;

  final Map<Allergen, AllergySeverity> allergies;

  /// `null` severity removes the allergy.
  final void Function(Allergen allergen, AllergySeverity? severity) onAllergyChanged;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unselected = [
      for (final allergen in Allergen.values)
        if (!allergies.containsKey(allergen)) allergen,
    ];

    return SectionCard(
      title: '4. Dị ứng',
      accentColor: theme.colorScheme.error,
      children: [
        Text(
          'Fluw sẽ cảnh báo khi sản phẩm trên Open Food Facts có ghi nhóm dị ứng bạn chọn (đang xây dựng). '
          'Dữ liệu sản phẩm có thể thiếu, hãy luôn đọc nhãn.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        for (final MapEntry(key: allergen, value: severity) in allergies.entries) ...[
          const SizedBox(height: AppSpacing.sm),
          _SelectedAllergy(
            allergen: allergen,
            severity: severity,
            onSeverityChanged: (value) => onAllergyChanged(allergen, value),
            onRemoved: () => onAllergyChanged(allergen, null),
          ),
        ],
        if (unselected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Chạm để thêm', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final allergen in unselected)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(allergenLabel(allergen)),
                  // New allergies start as severe: under-warning is the riskier mistake.
                  onPressed: () => onAllergyChanged(allergen, AllergySeverity.severe),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: noteController,
          maxLength: maxNoteLength,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Dị ứng khác (chỉ ghi chú, Fluw không cảnh báo)',
            prefixIcon: Icon(Icons.note_alt_outlined),
          ),
        ),
      ],
    );
  }
}

class _SelectedAllergy extends StatelessWidget {
  const _SelectedAllergy({
    required this.allergen,
    required this.severity,
    required this.onSeverityChanged,
    required this.onRemoved,
  });

  final Allergen allergen;
  final AllergySeverity severity;
  final ValueChanged<AllergySeverity> onSeverityChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = allergenLabel(allergen);
    final isSevere = severity == AllergySeverity.severe;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSevere ? theme.colorScheme.errorContainer : theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSevere ? Icons.gpp_maybe_outlined : Icons.info_outline,
                color: isSevere ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSevere ? theme.colorScheme.onErrorContainer : theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
              IconButton(onPressed: onRemoved, tooltip: 'Bỏ dị ứng $label', icon: const Icon(Icons.close)),
            ],
          ),
          SegmentedButton<AllergySeverity>(
            segments: [
              for (final value in AllergySeverity.values)
                ButtonSegment(value: value, label: Text(allergySeverityLabel(value))),
            ],
            selected: {severity},
            onSelectionChanged: (selection) => onSeverityChanged(selection.single),
          ),
        ],
      ),
    );
  }
}
