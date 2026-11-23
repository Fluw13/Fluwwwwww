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
    final monday = mondayOf(selected);
    final days = weekStartingOn(monday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(monthLabel(selected), style: theme.textTheme.titleLarge)),
              ],
            ),
            _WeekPill(
              label: monday == mondayOf(widget.today) ? 'Tuần này' : 'Tuần ${monday.day}/${monday.month}',
              onPrevious: () => widget.onSelected(selected.addDays(-DateTime.daysPerWeek)),
              onNext: () => widget.onSelected(selected.addDays(DateTime.daysPerWeek)),
            ),
          ],
        ),
        if (selected != widget.today)
          Align(
            child: TextButton(onPressed: () => widget.onSelected(widget.today), child: const Text('Về hôm nay')),
          ),
        // Not clipped, so the card shadows show and the row runs on to the screen edge as in the design.
        SingleChildScrollView(
          controller: _days,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

/// The design's "Tuần này" pill, between the previous and next week buttons.
class _WeekPill extends StatelessWidget {
  const _WeekPill({required this.label, required this.onPrevious, required this.onNext});

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Tuần trước',
            visualDensity: VisualDensity.compact,
            color: color,
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevious,
          ),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Tuần sau',
            visualDensity: VisualDensity.compact,
            color: color,
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
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
    final scheme = theme.colorScheme;
    final label = isToday ? 'Hôm nay' : weekdayShortLabel(day);
    final borderRadius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label ngày ${day.day} tháng ${day.month}${hasEntries ? ', có món đã ghi' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            if (isSelected)
              BoxShadow(color: scheme.primary.withValues(alpha: 0.3), offset: const Offset(0, 4), blurRadius: 10)
            else
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 1), blurRadius: 2),
          ],
        ),
        child: Material(
          color: isSelected ? scheme.primary : scheme.surfaceContainerLowest,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: 58),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm + AppSpacing.xs),
              child: Column(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected ? scheme.primaryContainer : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      height: 28 / 22,
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // The dot repeats what the semantics label says, so the information is not colour-only.
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasEntries ? (isSelected ? scheme.tertiaryContainer : scheme.primary) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
