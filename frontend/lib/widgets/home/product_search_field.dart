import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/fluw_palette.dart';

class ProductSearchField extends StatelessWidget {
  const ProductSearchField({super.key, required this.controller, required this.focusNode, required this.onSubmit});

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(color: palette.border),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: 'Mã vạch hoặc tên sản phẩm',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), tooltip: 'Tìm', onPressed: onSubmit),
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: palette.textPrimary, width: 1.5)),
      ),
    );
  }
}
