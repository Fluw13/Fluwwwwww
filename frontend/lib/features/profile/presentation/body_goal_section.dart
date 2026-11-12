import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/goal_duration.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';
import 'package:fluw/features/profile/presentation/field_error_text.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

class BodyGoalSection extends StatelessWidget {
  const BodyGoalSection({
    required this.heightController,
    required this.weightController,
    required this.targetWeightController,
    required this.goal,
    required this.showsWeeklyChange,
    required this.weeklyChangeKg,
    required this.onWeeklyChangeChanged,
    required this.activityLevel,
    required this.onActivityLevelChanged,
    required this.trainingType,
    required this.onTrainingTypeChanged,
    required this.errors,
    super.key,
  });

  final TextEditingController heightController;
  final TextEditingController weightController;
  final TextEditingController targetWeightController;
  final WeightGoal? goal;
  final bool showsWeeklyChange;
  final double? weeklyChangeKg;
  final ValueChanged<double> onWeeklyChangeChanged;
  final ActivityLevel? activityLevel;
  final ValueChanged<ActivityLevel> onActivityLevelChanged;
  final TrainingType? trainingType;
  final ValueChanged<TrainingType> onTrainingTypeChanged;
  final Map<ProfileField, String> errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = this.goal;

    return SectionCard(
      title: '2. Chỉ số cơ thể & mục tiêu',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: heightController,
                label: 'Chiều cao',
                unit: 'cm',
                errorText: errors[ProfileField.height],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _NumberField(
                controller: weightController,
                label: 'Cân nặng',
                unit: 'kg',
                errorText: errors[ProfileField.weight],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumberField(
          controller: targetWeightController,
          label: 'Cân nặng mong muốn',
          unit: 'kg',
          errorText: errors[ProfileField.targetWeight],
          helperText: goal == null ? null : _goalText(goal),
        ),
        if (showsWeeklyChange) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Tốc độ mỗi tuần', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in weeklyChangeOptionsKg)
                ChoiceChip(
                  label: Text(_weeklyChangeText(option)),
                  selected: weeklyChangeKg == option,
                  onSelected: (_) => onWeeklyChangeChanged(option),
                ),
            ],
          ),
          FieldErrorText(errors[ProfileField.weeklyChange]),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fluw giới hạn tối đa ${formatDecimal(maxWeeklyChangeKg)} kg mỗi tuần.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ActivityLevel>(
          initialValue: activityLevel,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Mức vận động hằng ngày',
            errorText: errors[ProfileField.activityLevel],
          ),
          selectedItemBuilder: (context) => [
            for (final level in ActivityLevel.values) Text(activityLevelLabel(level), overflow: TextOverflow.ellipsis),
          ],
          items: [
            for (final level in ActivityLevel.values)
              DropdownMenuItem(
                value: level,
                child: _OptionText(label: activityLevelLabel(level), description: activityLevelDescription(level)),
              ),
          ],
          onChanged: (level) => level == null ? null : onActivityLevelChanged(level),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<TrainingType>(
          initialValue: trainingType,
          isExpanded: true,
          decoration: InputDecoration(labelText: 'Hình thức tập', errorText: errors[ProfileField.trainingType]),
          selectedItemBuilder: (context) => [
            for (final type in TrainingType.values) Text(trainingTypeLabel(type), overflow: TextOverflow.ellipsis),
          ],
          items: [
            for (final type in TrainingType.values)
              DropdownMenuItem(
                value: type,
                child: _OptionText(label: trainingTypeLabel(type), description: trainingTypeDescription(type)),
              ),
          ],
          onChanged: (type) => type == null ? null : onTrainingTypeChanged(type),
        ),
      ],
    );
  }

  String _goalText(WeightGoal goal) {
    final weightKg = parseDecimal(weightController.text);
    final targetWeightKg = parseDecimal(targetWeightController.text);
    if (goal == WeightGoal.maintain || weightKg == null || targetWeightKg == null) {
      return weightGoalLabel(goal);
    }
    return '${weightGoalLabel(goal)} ${formatDecimal((targetWeightKg - weightKg).abs())} kg';
  }

  String _weeklyChangeText(double weeklyChangeKg) {
    final text = '${formatDecimal(weeklyChangeKg, maxFractionDigits: 2)} kg/tuần';
    final weightKg = parseDecimal(weightController.text);
    final targetWeightKg = parseDecimal(targetWeightController.text);
    if (weightKg == null || targetWeightKg == null) {
      return text;
    }
    final weeks = estimateWeeksToTarget(currentKg: weightKg, targetKg: targetWeightKg, weeklyChangeKg: weeklyChangeKg);
    return '$text · khoảng $weeks tuần';
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.errorText,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        errorText: errorText,
        errorMaxLines: 3,
        helperText: helperText,
      ),
    );
  }
}

class _OptionText extends StatelessWidget {
  const _OptionText({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
