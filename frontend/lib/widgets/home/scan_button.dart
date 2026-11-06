import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';

class ScanButton extends StatelessWidget {
  const ScanButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.qr_code_scanner, size: 24),
        label: const Text('Quét mã vạch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: palette.primaryAction,
          foregroundColor: palette.onPrimaryAction,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
    );
  }
}
