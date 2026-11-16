import 'package:flutter/material.dart';
import 'package:fluw/app/shell/profile_avatar_button.dart';
import 'package:fluw/app/shell/theme_mode_button.dart';
import 'package:fluw/core/theme/app_spacing.dart';

class FluwTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FluwTopBar({required this.title, required this.onProfileTap, required this.onRemindersTap, super.key});

  final String title;
  final VoidCallback onProfileTap;
  final VoidCallback onRemindersTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        const ThemeModeButton(),
        IconButton(tooltip: 'Nhắc nhở', icon: const Icon(Icons.notifications_outlined), onPressed: onRemindersTap),
        ProfileAvatarButton(onTap: onProfileTap),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
