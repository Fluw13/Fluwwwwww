import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/week.dart';
import 'package:fluw/features/note/presentation/note_labels.dart';

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    required this.selected,
    required this.today,
    required this.daysWithEntries,
    required this.onSelected,
    super.key,
  });

  final CalendarDate selected;
  final CalendarDate today;
  final Set<CalendarDate> daysWithEntries;
  final ValueChanged<CalendarDate> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = weekStartingOn(mondayOf(selected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Tuần trước',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onSelected(selected.addDays(-DateTime.daysPerWeek)),
            ),
            Expanded(
              child: Text(monthLabel(selected), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            ),
            IconButton(
              tooltip: 'Tuần sau',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onSelected(selected.addDays(DateTime.daysPerWeek)),
            ),
          ],
        ),
        if (selected != today)
          Align(
            child: TextButton(onPressed: () => onSelected(today), child: const Text('Về hôm nay')),
          ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final day in days) ...[
                _DayButton(
                  day: day,
                  isSelected: day == selected,
                  isToday: day == today,
                  hasEntries: daysWithEntries.contains(day),
                  onTap: () => onSelected(day),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasEntries,
    required this.onTap,
  });

  final CalendarDate day;
  final bool isSelected;
  final bool isToday;
  final bool hasEntries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final label = isToday ? 'Hôm nay' : weekdayShortLabel(day);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label ngày ${day.day} tháng ${day.month}${hasEntries ? ', có món đã ghi' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Column(
              children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
                Text('${day.day}', style: theme.textTheme.titleLarge?.copyWith(color: foreground)),
                // The dot repeats what the semantics label says, so the information is not colour-only.
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasEntries ? (isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
