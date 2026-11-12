import 'package:flutter/material.dart';

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Hồ sơ',
      onPressed: onTap,
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primaryContainer,
        child: Icon(Icons.person, size: 20, color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}
