import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/search/presentation/search_controller.dart';

/// The white search box of the design: search at the start, clear and barcode scan at the end.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onClear,
    required this.onOpenScan,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, 1), blurRadius: 2)],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        maxLength: maxSearchLength,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Tìm thực phẩm, đồ đóng gói...',
          counterText: '',
          fillColor: scheme.surfaceContainerLowest,
          prefixIcon: IconButton(
            tooltip: 'Tìm',
            icon: const Icon(Icons.search),
            onPressed: () => onSubmitted(controller.text),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value.text.isNotEmpty)
                    IconButton(tooltip: 'Xóa từ khóa', icon: const Icon(Icons.close), onPressed: onClear),
                  IconButton(
                    tooltip: 'Quét mã vạch',
                    onPressed: onOpenScan,
                    icon: const Icon(Icons.qr_code_scanner),
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainer,
                      foregroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.control / 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
