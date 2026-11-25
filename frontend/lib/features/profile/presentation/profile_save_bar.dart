import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';

/// The rounder shape of the design's large profile buttons.
const OutlinedBorder largeButtonShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24)));

/// The save button pinned under the profile form. Its text stops growing at 130%, like a navigation bar, so the bar
/// never covers most of a small screen.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({required this.onSave, super.key});

  /// `null` while saving.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -4), blurRadius: 20),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: FilledButton.icon(
              onPressed: onSave,
              style: FilledButton.styleFrom(shape: largeButtonShape),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('Lưu hồ sơ'),
            ),
          ),
        ),
      ),
    );
  }
}
