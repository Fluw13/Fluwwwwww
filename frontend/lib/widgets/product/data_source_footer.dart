import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

class DataSourceFooter extends StatelessWidget {
  const DataSourceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: Text(
        'Dữ liệu: Open Food Facts (openfoodfacts.org) — giấy phép ODbL, do cộng đồng đóng góp và có thể chưa đầy đủ.\n'
        'Ảnh sản phẩm: cộng tác viên Open Food Facts — CC BY-SA.\n'
        'Phân tích: Zero AI (Google Gemini).',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, height: 1.55, color: palette.textSecondary),
      ),
    );
  }
}
