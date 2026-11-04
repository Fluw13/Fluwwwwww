import 'package:flutter/material.dart';

/// 44 px translucent circle used over the camera preview, readable on any frame.
/// [isSelected] makes it a toggle (announced as on/off by screen readers).
class ScannerRoundButton extends StatelessWidget {
  const ScannerRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected,
  });

  static const double size = 44;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    final bool selected = isSelected ?? false;

    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      isSelected: isSelected,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(size),
        backgroundColor: selected ? Colors.white : const Color(0x52000000),
        foregroundColor: selected ? const Color(0xFF0B0D0C) : Colors.white,
        disabledBackgroundColor: const Color(0x29000000),
        disabledForegroundColor: const Color(0x80FFFFFF),
      ),
    );
  }
}
