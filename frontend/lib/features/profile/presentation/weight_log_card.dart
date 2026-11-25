import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/today_provider.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/domain/health_profile.dart';
import 'package:fluw/features/profile/domain/weight_entry.dart';
import 'package:fluw/features/profile/presentation/profile_labels.dart';
import 'package:fluw/features/profile/presentation/record_weight_dialog.dart';

class WeightLogCard extends ConsumerWidget {
  const WeightLogCard({required this.profile, super.key});

  static const int _shownEntries = 5;

  final HealthProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final log = ref.watch(weightLogProvider);
    final entries = log.value ?? const <WeightEntry>[];

    return SectionCard(
      title: 'Theo dõi cân nặng',
      icon: Icons.monitor_weight_outlined,
      accentColor: theme.colorScheme.secondary,
      children: [
        if (log.hasError && !log.hasValue)
          Text(
            'Không đọc được lịch sử cân nặng trên máy. Hãy đóng hẳn app rồi mở lại.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          )
        else if (log.isLoading && !log.hasValue)
          const LinearProgressIndicator()
        else if (entries.isEmpty)
          Text(
            _tracksGoal ? 'Chưa ghi lần nào. Ghi đều để thấy tiến độ đến cân nặng mong muốn.' : 'Chưa ghi lần nào.',
            style: theme.textTheme.bodyMedium,
          )
        else
          // The progress towards the target is shown with the target, in "Thể trạng & mục tiêu".
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.inner),
            ),
            child: Column(
              children: [
                for (final entry in entries.reversed.take(_shownEntries))
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.scale_outlined, color: theme.colorScheme.secondary),
                    title: Text('${formatDecimal(entry.weightKg)} kg', style: theme.textTheme.titleSmall),
                    trailing: Text(calendarDateLabel(entry.date), style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _record(context, ref),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.monitor_weight_outlined),
          label: const Text('Ghi cân nặng hôm nay'),
        ),
      ],
    );
  }

  /// Weight changes for other reasons while pregnant or breastfeeding, and Fluw sets no targets then.
  bool get _tracksGoal => profile.isPregnantOrBreastfeeding != true;

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
