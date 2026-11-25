import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/presentation/field_error_text.dart';
import 'package:fluw/features/profile/presentation/profile_draft.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/segmented_pills.dart';
import 'package:fluw/features/profile/presentation/setup_section_card.dart';

class BasicInfoSection extends StatelessWidget {
  const BasicInfoSection({
    required this.nameController,
    required this.sex,
    required this.onSexChanged,
    required this.bmrFormula,
    required this.onBmrFormulaChanged,
    required this.asksPregnancy,
    required this.isPregnantOrBreastfeeding,
    required this.onPregnancyChanged,
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
  final bool asksPregnancy;
  final bool? isPregnantOrBreastfeeding;
  final ValueChanged<bool> onPregnancyChanged;
  final CalendarDate? birthDate;
  final ValueChanged<CalendarDate> onBirthDateChanged;
  final CalendarDate today;
  final Map<ProfileField, String> errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sex = this.sex;
    final bmrFormula = this.bmrFormula;

    return SetupSectionCard(
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
                suffixIcon: Icon(Icons.edit_calendar_outlined, color: theme.colorScheme.primary),
                errorText: errors[ProfileField.birthDate],
              ),
              child: Text(_birthDateText()),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Giới tính sinh học', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        SegmentedPills<Sex>(
          options: {for (final value in Sex.values) value: sexLabel(value)},
          selected: sex,
          onSelected: onSexChanged,
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
          SegmentedPills<BmrFormula>(
            options: {for (final value in BmrFormula.values) value: bmrFormulaLabel(value)},
            selected: bmrFormula,
            onSelected: onBmrFormulaChanged,
          ),
          FieldErrorText(errors[ProfileField.bmrFormula]),
        ],
        if (asksPregnancy) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Bạn đang mang thai hoặc cho con bú?', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedPills<bool>(
            options: const {true: 'Có', false: 'Không'},
            selected: isPregnantOrBreastfeeding,
            onSelected: onPregnancyChanged,
          ),
          FieldErrorText(errors[ProfileField.pregnancy]),
          if (isPregnantOrBreastfeeding == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fluw sẽ không tính calo, đạm, BMI và nước; dị ứng vẫn được cảnh báo.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ],
    );
  }

  String _birthDateText() {
    final birthDate = this.birthDate;
    if (birthDate == null) {
      return 'Chọn ngày sinh';
    }
    return '${calendarDateLabel(birthDate)} (${ageInYears(birthDate: birthDate, today: today)} tuổi)';
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final lastDate = _toDateTime(latestAdultBirthDate(today));
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
