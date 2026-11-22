import 'package:flutter/material.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/app_card.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({required this.limits, required this.onSetupProfile, required this.onOpenProfile, super.key});

  final PersonalLimits limits;
  final VoidCallback onSetupProfile;

  /// For a profile that could not be read: the Hồ Sơ tab tells a broken profile from a failed read and only offers
  /// a retry for the latter, so an empty form never overwrites a profile that is just briefly unreadable.
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final name = limits.displayName;
    final tracking = [
      if (limits.watchesSugar) 'đường',
      if (limits.watchesSodium) 'natri',
      if (limits.watchesSaturatedFat) 'béo bão hòa',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(name == null || name.isEmpty ? 'Chào bạn' : 'Chào $name', style: theme.textTheme.titleLarge),
              ExcludeSemantics(child: Text('👋', style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...switch (limits.profileStatus) {
            ProfileStatus.loaded => [
              if (limits.goalLabel case final goal?) _InfoLine(icon: Icons.eco, label: 'Mục tiêu: ', value: goal),
              if (tracking.isNotEmpty)
                _InfoLine(icon: Icons.visibility_outlined, label: 'Theo dõi: ', value: tracking.join(', ')),
            ],
            ProfileStatus.none => [
              Text('Thiết lập hồ sơ để Fluw tính calo, protein và gợi ý món cho bạn.', style: muted),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(onPressed: onSetupProfile, child: const Text('Thiết lập hồ sơ')),
            ],
            ProfileStatus.unreadable => [
              Text('Không đọc được hồ sơ trên máy.', style: muted),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(onPressed: onOpenProfile, child: const Text('Mở Hồ Sơ')),
            ],
            ProfileStatus.loading => const <Widget>[],
          },
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  TextSpan(text: value, style: style),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
