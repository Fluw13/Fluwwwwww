import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/presentation/field_error_text.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({
    required this.nameController,
    required this.sex,
    required this.onSexChanged,
    required this.bmrFormula,
    required this.onBmrFormulaChanged,
    required this.birthDate,
    required this.onBirthDateChanged,
    required this.today,
    required this.errors,
    super.key,
  });

  static const int maxNameLength = 40;

  final TextEditingController nameController;
  final Sex? sex;
  final ValueChanged<Sex> onSexChanged;
  final BmrFormula? bmrFormula;
  final ValueChanged<BmrFormula> onBmrFormulaChanged;
  final CalendarDate? birthDate;
  final ValueChanged<CalendarDate> onBirthDateChanged;
  final CalendarDate today;
  final Map<ProfileField, String> errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sex = this.sex;
    final bmrFormula = this.bmrFormula;

    return SectionCard(
      title: '1. Thông tin cơ bản',
      children: [
        TextField(
          controller: nameController,
          maxLength: maxNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Tên gọi (không bắt buộc)',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          child: InkWell(
            onTap: () => _pickBirthDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Ngày sinh',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                errorText: errors[ProfileField.birthDate],
              ),
              child: Text(_birthDateText()),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Giới tính sinh học', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<Sex>(
          emptySelectionAllowed: true,
          segments: [for (final value in Sex.values) ButtonSegment(value: value, label: Text(sexLabel(value)))],
          selected: {?sex},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              onSexChanged(selection.single);
            }
          },
        ),
        FieldErrorText(errors[ProfileField.sex]),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Dùng để tính năng lượng cơ bản (BMR) theo công thức Mifflin–St Jeor.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (sex == Sex.other) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Tính BMR theo công thức nào?', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<BmrFormula>(
            emptySelectionAllowed: true,
            segments: [
              for (final value in BmrFormula.values) ButtonSegment(value: value, label: Text(bmrFormulaLabel(value))),
            ],
            selected: {?bmrFormula},
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onBmrFormulaChanged(selection.single);
              }
            },
          ),
          FieldErrorText(errors[ProfileField.bmrFormula]),
        ],
      ],
    );
  }

  String _birthDateText() {
    final birthDate = this.birthDate;
    if (birthDate == null) {
      return 'Chọn ngày sinh';
    }
    final day = birthDate.day.toString().padLeft(2, '0');
    final month = birthDate.month.toString().padLeft(2, '0');
    final age = ageInYears(birthDate: birthDate, today: today);
    return '$day/$month/${birthDate.year} ($age tuổi)';
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final lastDate = _toDateTime(today);
    // The day after someone born on it would turn maximumAgeYears + 1 today, so every pickable date is a valid age.
    final firstDate = DateTime(today.year - maximumAgeYears - 1, today.month, today.day + 1);
    final current = birthDate;
    final initialDate = current == null ? DateTime(today.year - 25, today.month) : _toDateTime(current);
    final picked = await showDatePicker(
      context: context,
      helpText: 'Chọn ngày sinh',
      initialDatePickerMode: DatePickerMode.year,
      // A saved birth date can fall outside the range after enough years; the picker asserts on that.
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      onBirthDateChanged(CalendarDate.fromDateTime(picked));
    }
  }
}

DateTime _toDateTime(CalendarDate date) => DateTime(date.year, date.month, date.day);
