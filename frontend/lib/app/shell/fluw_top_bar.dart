import 'package:flutter/material.dart';
import 'package:fluw/app/shell/profile_avatar_button.dart';
import 'package:fluw/app/shell/theme_mode_button.dart';
import 'package:fluw/core/theme/app_spacing.dart';

class FluwTopBar extends StatelessWidget implements PreferredSizeWidget {
  const FluwTopBar({required this.title, required this.onProfileTap, super.key});

  final String title;
  final VoidCallback onProfileTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        const ThemeModeButton(),
        ProfileAvatarButton(onTap: onProfileTap),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
