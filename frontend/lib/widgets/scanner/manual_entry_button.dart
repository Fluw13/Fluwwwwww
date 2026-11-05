import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';

class ManualEntryButton extends StatelessWidget {
  const ManualEntryButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.keyboard_outlined),
        label: const Text('Nhập mã thủ công', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0x52000000),
          disabledForegroundColor: const Color(0x80FFFFFF),
          side: const BorderSide(color: Color(0x40FFFFFF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
    );
  }
}
