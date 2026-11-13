import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/calendar_date.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/goal_progress.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';
import 'package:fluw/features/profile/presentation/record_weight_dialog.dart';

class WeightLogCard extends ConsumerWidget {
  const WeightLogCard({required this.profile, super.key});

  static const int _shownEntries = 5;

  final HealthProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(weightLogProvider).value ?? const <WeightEntry>[];
    // Progress starts from the first weigh-in, so it needs at least one earlier entry to compare against.
    final progress = entries.length < 2
        ? null
        : goalProgress(startKg: entries.first.weightKg, currentKg: profile.weightKg, targetKg: profile.targetWeightKg);

    return SectionCard(
      title: 'Theo dõi cân nặng',
      accentColor: theme.colorScheme.secondary,
      children: [
        if (entries.isEmpty)
          Text('Chưa ghi lần nào. Ghi đều để thấy tiến độ đến cân nặng mong muốn.', style: theme.textTheme.bodyMedium)
        else ...[
          if (progress != null) ...[
            Text(
              'Từ ${formatDecimal(entries.first.weightKg)} kg ngày ${_dateText(entries.first.date)}: '
              'đã đi được ${(progress * 100).round()}% quãng đường đến ${formatDecimal(profile.targetWeightKg)} kg',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (final entry in entries.reversed.take(_shownEntries))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('${formatDecimal(entry.weightKg)} kg'),
              trailing: Text(_dateText(entry.date)),
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _record(context, ref),
          icon: const Icon(Icons.monitor_weight_outlined),
          label: const Text('Ghi cân nặng hôm nay'),
        ),
      ],
    );
  }

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final weightKg = await showRecordWeightDialog(context, currentKg: profile.weightKg);
    if (weightKg == null || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(weightLogRepositoryProvider)
          .record(WeightEntry(date: ref.read(todayProvider), weightKg: weightKg));
      messenger.showSnackBar(const SnackBar(content: Text('Đã ghi cân nặng.')));
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Không ghi được cân nặng. Hãy thử lại.')));
    }
  }
}

String _dateText(CalendarDate date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
