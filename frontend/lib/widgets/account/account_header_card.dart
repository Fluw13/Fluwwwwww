import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/fluw_palette.dart';

/// Sign-in needs a backend and a final privacy policy, so the button is shown
/// disabled with "Sắp có" rather than as a login that does nothing.
class AccountHeaderCard extends StatelessWidget {
  const AccountHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final FluwPalette palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: palette.surfaceMuted, shape: BoxShape.circle),
                child: Icon(Icons.person_outline, size: 28, color: palette.textPrimary),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Khách', style: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w700)),
                    Text(
                      'Dùng Fluw không cần tài khoản',
                      style: TextStyle(fontSize: 13, height: 1.35, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đăng nhập để giữ lịch sử quét và tìm kiếm sau khi đóng ứng dụng.',
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          const FilledButton(onPressed: null, child: Text('Đăng nhập · Sắp có')),
        ],
      ),
    );
  }
}
