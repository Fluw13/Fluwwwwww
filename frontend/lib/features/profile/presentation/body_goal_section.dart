import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/goal_duration.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';
import 'package:fluw/features/profile/presentation/bmi_scale.dart';
import 'package:fluw/features/profile/presentation/field_error_text.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/segmented_pills.dart';
import 'package:fluw/features/profile/presentation/setup_section_card.dart';

class BodyGoalSection extends StatelessWidget {
  const BodyGoalSection({
    required this.heightController,
    required this.weightController,
    required this.targetWeightController,
    required this.bmi,
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

  /// The BMI of the typed numbers, when the profile would get one.
  final Bmi? bmi;
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
    final bmi = this.bmi;
    final targetError = errors[ProfileField.targetWeight];

    return SetupSectionCard(
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
        if (bmi != null) ...[const SizedBox(height: AppSpacing.sm), BmiScale(bmi: bmi)],
        const SizedBox(height: AppSpacing.md),
        _NumberField(
          controller: targetWeightController,
          label: 'Cân nặng mong muốn',
          unit: 'kg',
          errorText: targetError,
        ),
        if (goal != null && targetError == null) ...[
          const SizedBox(height: AppSpacing.sm),
          _GoalPill(goal: goal, text: _goalText(goal)),
        ],
        if (showsWeeklyChange) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Tốc độ mỗi tuần', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedPills<double>(
            options: {for (final option in weeklyChangeOptionsKg) option: _weeklyChangeText(option)},
            selected: weeklyChangeKg,
            onSelected: onWeeklyChangeChanged,
          ),
          FieldErrorText(errors[ProfileField.weeklyChange]),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fluw giới hạn tối đa ${formatDecimal(maxWeeklyChangeKg)} kg mỗi tuần. Số tuần là ước tính; cân thường '
            'thay đổi chậm dần.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<ActivityLevel>(
          initialValue: activityLevel,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Mức vận động hằng ngày',
            prefixIcon: const Icon(Icons.directions_walk_outlined),
            helperText: 'Tính cả công việc, đi lại và tập luyện. Fluw dùng hệ số vận động thông dụng (ước tính).',
            helperMaxLines: 4,
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
          decoration: InputDecoration(
            labelText: 'Hình thức tập',
            prefixIcon: const Icon(Icons.fitness_center_outlined),
            errorText: errors[ProfileField.trainingType],
          ),
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
    return '$text · ít nhất khoảng $weeks tuần';
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, required this.unit, required this.errorText});

  final TextEditingController controller;
  final String label;
  final String unit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: unit, errorText: errorText, errorMaxLines: 3),
    );
  }
}

/// The goal the two weights imply, e.g. "Giảm cân 5 kg"; it is not picked separately.
class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.goal, required this.text});

  final WeightGoal goal;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + AppSpacing.xs, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.inner),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              switch (goal) {
                WeightGoal.lose => Icons.trending_down,
                WeightGoal.maintain => Icons.trending_flat,
                WeightGoal.gain => Icons.trending_up,
              },
              size: 18,
              color: colors.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: colors.onSecondaryContainer)),
            ),
          ],
        ),
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
