import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/features/note/domain/week.dart';
import 'package:fluw/features/note/presentation/note_labels.dart';

class WeekStrip extends StatefulWidget {
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
  State<WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<WeekStrip> {
  final ScrollController _days = ScrollController();
  final GlobalKey _selectedDayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _revealSelectedDay();
  }

  @override
  void didUpdateWidget(WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _revealSelectedDay();
    }
  }

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  /// On a narrow phone the week scrolls sideways and Saturday or Sunday start out of view. Only this row scrolls:
  /// `Scrollable.ensureVisible` would also move the page around it.
  void _revealSelectedDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _selectedDayKey.currentContext?.findRenderObject();
      if (!mounted || box == null || !_days.hasClients) {
        return;
      }
      final target = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.5).offset;
      final position = _days.position;
      _days.jumpTo(target.clamp(position.minScrollExtent, position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final days = weekStartingOn(mondayOf(selected));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Tuần trước',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => widget.onSelected(selected.addDays(-DateTime.daysPerWeek)),
            ),
            Expanded(
              child: Text(monthLabel(selected), textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            ),
            IconButton(
              tooltip: 'Tuần sau',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => widget.onSelected(selected.addDays(DateTime.daysPerWeek)),
            ),
          ],
        ),
        if (selected != widget.today)
          Align(
            child: TextButton(onPressed: () => widget.onSelected(widget.today), child: const Text('Về hôm nay')),
          ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          controller: _days,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final day in days) ...[
                _DayButton(
                  key: day == selected ? _selectedDayKey : null,
                  day: day,
                  isSelected: day == selected,
                  isToday: day == widget.today,
                  hasEntries: widget.daysWithEntries.contains(day),
                  onTap: () => widget.onSelected(day),
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
    super.key,
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
