import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/reminders/data/notification_scheduler.dart';
import 'package:fluw/features/reminders/data/reminder_settings_controller.dart';
import 'package:fluw/features/reminders/domain/reminder_settings.dart';
import 'package:fluw/features/reminders/domain/reminder_time.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  bool _isAsking = false;

  Future<void> _setEnabled(bool enabled) async {
    final controller = ref.read(reminderSettingsProvider.notifier);
    final settings = ref.read(reminderSettingsProvider);
    if (!enabled) {
      await controller.update(settings.copyWith(enabled: false));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isAsking = true);
    final bool granted;
    try {
      granted = await ref.read(notificationSchedulerProvider).requestPermission();
    } on Object {
      messenger.showSnackBar(const SnackBar(content: Text('Chưa bật được nhắc nhở. Vui lòng thử lại.')));
      return;
    } finally {
      if (mounted) {
        setState(() => _isAsking = false);
      }
    }
    if (!granted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fluw chưa được phép gửi thông báo. Hãy bật thông báo cho Fluw trong Cài đặt.')),
      );
      return;
    }
    await controller.update(settings.copyWith(enabled: true));
  }

  Future<void> _changeTime(int index, ReminderTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Chọn giờ nhắc',
    );
    if (picked == null || !mounted) {
      return;
    }
    final settings = ref.read(reminderSettingsProvider);
    final chosen = ReminderTime(picked.hour, picked.minute);
    if (chosen != current && settings.times.contains(chosen)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã có giờ nhắc ${chosen.label}.')));
      return;
    }
    final times = [...settings.times]..[index] = chosen;
    await ref.read(reminderSettingsProvider.notifier).update(settings.copyWith(times: times));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(reminderSettingsProvider);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final isDefault = const ListEquality<ReminderTime>().equals(settings.times, ReminderSettings.defaultTimes);

    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc nhở')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SectionCard(
            title: 'Nhắc ghi bữa ăn',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật nhắc nhở'),
                subtitle: const Text('Nội dung nhắc dựa trên lượng bạn đã ghi hôm nay so với chỉ tiêu.'),
                value: settings.enabled,
                onChanged: _isAsking ? null : _setEnabled,
              ),
              const Divider(),
              for (final (index, time) in settings.times.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(time.label, style: theme.textTheme.titleMedium),
                  subtitle: Text(_momentLabel(time)),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _changeTime(index, time),
                ),
              if (!isDefault)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => ref
                        .read(reminderSettingsProvider.notifier)
                        .update(settings.copyWith(times: ReminderSettings.defaultTimes)),
                    child: const Text('Về giờ mặc định 10:00, 17:00, 22:00'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nhắc nhở chạy trên máy, không gửi dữ liệu lên máy chủ. Trên màn khóa, điện thoại có thể ẩn nội dung nhắc '
            'tùy cài đặt của bạn.',
            style: muted,
          ),
        ],
      ),
    );
  }

  String _momentLabel(ReminderTime time) => switch (time.hour) {
    < 12 => 'Nhắc ghi bữa sáng',
    < 19 => 'Nhắc ghi bữa trưa, chiều',
    _ => 'Tổng kết cuối ngày',
  };
}
