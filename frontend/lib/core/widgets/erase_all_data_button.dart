import 'package:flutter/material.dart';

/// The one way to erase everything Fluw keeps on the phone; [onPressed] asks for confirmation first.
class EraseAllDataButton extends StatelessWidget {
  const EraseAllDataButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error),
      ),
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text('Xóa toàn bộ dữ liệu trên máy'),
    );
  }
}
