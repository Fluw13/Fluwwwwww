import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/dietary_preferences.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

class DietarySummaryCard extends StatelessWidget {
  const DietarySummaryCard({required this.dietary, super.key});

  final DietaryPreferences dietary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = dietary.allergyNote;
    // Severe first, so the most important warning is read first.
    final allergies = dietary.allergies.entries.toList()..sort((a, b) => a.value.index.compareTo(b.value.index));

    return SectionCard(
      title: 'Dị ứng & chế độ ăn',
      accentColor: theme.colorScheme.error,
      children: [
        if (allergies.isEmpty && note == null)
          Text('Chưa khai báo dị ứng.', style: theme.textTheme.bodyMedium)
        else ...[
          for (final MapEntry(key: allergen, value: severity) in allergies)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                severity == AllergySeverity.severe ? Icons.gpp_maybe_outlined : Icons.info_outline,
                color: severity == AllergySeverity.severe ? theme.colorScheme.error : theme.colorScheme.tertiary,
              ),
              title: Text(allergenLabel(allergen)),
              subtitle: Text('Mức: ${allergySeverityLabel(severity)}'),
            ),
          if (note != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.note_alt_outlined),
              title: const Text('Dị ứng khác (chỉ ghi chú)'),
              subtitle: Text(note),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            Chip(
              avatar: const Icon(Icons.restaurant_outlined, size: 18),
              label: Text(dietStyleLabel(dietary.dietStyle)),
            ),
            for (final preference in dietary.preferences) Chip(label: Text(foodPreferenceLabel(preference))),
          ],
        ),
      ],
    );
  }
}
