import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({required this.limits, required this.onSetupProfile, super.key});

  final PersonalLimits limits;
  final VoidCallback onSetupProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final name = limits.displayName;
    final tracking = [
      if (limits.watchesSugar) 'đường',
      if (limits.watchesSodium) 'natri',
      if (limits.watchesSaturatedFat) 'béo bão hòa',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name == null || name.isEmpty ? 'Chào bạn' : 'Chào $name', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            ...switch (limits.profileStatus) {
              ProfileStatus.loaded => [
                if (limits.goalLabel case final goal?) Text('Mục tiêu: $goal', style: muted),
                if (tracking.isNotEmpty) Text('Theo dõi: ${tracking.join(', ')}', style: muted),
              ],
              ProfileStatus.none => [
                Text('Thiết lập hồ sơ để Fluw tính calo, protein và gợi ý món cho bạn.', style: muted),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(onPressed: onSetupProfile, child: const Text('Thiết lập hồ sơ')),
              ],
              ProfileStatus.unreadable => [
                Text('Không đọc được hồ sơ trên máy. Hãy nhập lại để Fluw tính đúng chỉ tiêu.', style: muted),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(onPressed: onSetupProfile, child: const Text('Nhập lại hồ sơ')),
              ],
              ProfileStatus.loading => const <Widget>[],
            },
          ],
        ),
      ),
    );
  }
}
