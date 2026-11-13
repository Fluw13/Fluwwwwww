import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

class ConditionsSection extends StatelessWidget {
  const ConditionsSection({
    required this.conditions,
    required this.onConditionChanged,
    required this.noteController,
    super.key,
  });

  static const int maxNoteLength = 200;

  final Set<HealthCondition> conditions;
  final void Function(HealthCondition condition, {required bool selected}) onConditionChanged;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SectionCard(
      title: '3. Bệnh nền',
      accentColor: theme.colorScheme.tertiary,
      children: [
        Text(
          'Thông tin bệnh chỉ lưu trên máy này, không gửi lên máy chủ.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final condition in HealthCondition.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: conditions.contains(condition),
            onChanged: (selected) => onConditionChanged(condition, selected: selected ?? false),
            title: Text(healthConditionLabel(condition)),
            subtitle: Text(healthConditionDescription(condition)),
          ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: noteController,
          maxLength: maxNoteLength,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: 'Bệnh khác (chỉ để ghi chú)',
            prefixIcon: Icon(Icons.note_alt_outlined),
          ),
        ),
      ],
    );
  }
}
