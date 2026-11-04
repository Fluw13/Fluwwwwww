import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.onOpenAccount});

  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: const Text('Fluw', style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800)),
            ),
          ),
          IconButton(
            tooltip: 'Tài khoản',
            onPressed: onOpenAccount,
            icon: const Icon(Icons.person_outline),
            style: IconButton.styleFrom(
              fixedSize: const Size.square(44),
              backgroundColor: palette.surface,
              foregroundColor: palette.textPrimary,
              side: BorderSide(color: palette.border),
            ),
          ),
        ],
      ),
    );
  }
}
