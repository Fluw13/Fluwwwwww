import 'package:flutter/material.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/features/profile/presentation/about_card.dart';

/// Shown instead of the profile when there is nothing readable to show, with one clear way forward.
class ProfileSetupPrompt extends StatelessWidget {
  const ProfileSetupPrompt.empty({required this.onPressed, super.key})
    : icon = Icons.person_add_alt_1_outlined,
      title = 'Chưa có hồ sơ sức khỏe',
      message =
          'Nhập chiều cao, cân nặng, mục tiêu và bệnh nền để Fluw ước tính calo, protein, đường và nước mỗi ngày. '
          'Dữ liệu chỉ lưu trên máy này.',
      buttonLabel = 'Thiết lập hồ sơ',
      isError = false;

  const ProfileSetupPrompt.unreadable({required this.onPressed, super.key})
    : icon = Icons.error_outline,
      title = 'Không đọc được hồ sơ đã lưu',
      message = 'Hồ sơ trên máy có dữ liệu mà phiên bản app này không hiểu. Hãy nhập lại để Fluw tính đúng chỉ tiêu.',
      buttonLabel = 'Nhập lại hồ sơ',
      isError = true;

  /// Offers a retry only: opening an empty form here could overwrite a profile that is just briefly unreadable.
  const ProfileSetupPrompt.loadFailed({required this.onPressed, super.key})
    : icon = Icons.error_outline,
      title = 'Không mở được dữ liệu trên máy',
      message = 'Hãy thử lại. Nếu vẫn lỗi, hãy đóng hẳn app rồi mở lại.',
      buttonLabel = 'Thử lại',
      isError = true;

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final bool isError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: isError ? theme.colorScheme.error : theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
            const SizedBox(height: AppSpacing.sm),
            const LicensesButton(),
          ],
        ),
      ),
    );
  }
}
