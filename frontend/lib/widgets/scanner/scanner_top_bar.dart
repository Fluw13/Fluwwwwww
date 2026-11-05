import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_spacing.dart';
import 'scanner_round_button.dart';

class ScannerTopBar extends StatelessWidget {
  const ScannerTopBar({
    super.key,
    required this.torchState,
    required this.onClose,
    required this.onToggleTorch,
  });

  final TorchState torchState;
  final VoidCallback? onClose;
  final VoidCallback? onToggleTorch;

  @override
  Widget build(BuildContext context) {
    final bool torchAvailable = torchState != TorchState.unavailable;
    final bool torchOn = torchState == TorchState.on || torchState == TorchState.auto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          ScannerRoundButton(icon: Icons.close, tooltip: 'Đóng', onPressed: onClose),
          Expanded(
            child: Semantics(
              header: true,
              child: const Text(
                'Quét mã vạch',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          ScannerRoundButton(
            icon: switch (torchState) {
              TorchState.on => Icons.flash_on,
              TorchState.auto => Icons.flash_auto,
              _ => Icons.flash_off,
            },
            tooltip: switch (torchState) {
              TorchState.unavailable => 'Đèn flash không khả dụng',
              TorchState.on => 'Tắt đèn flash',
              TorchState.auto => 'Đèn flash đang tự động, bấm để đổi',
              TorchState.off => 'Bật đèn flash',
            },
            isSelected: torchAvailable ? torchOn : null,
            onPressed: torchAvailable ? onToggleTorch : null,
          ),
        ],
      ),
    );
  }
}
