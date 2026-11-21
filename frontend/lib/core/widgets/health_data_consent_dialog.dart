import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/privacy/health_data_consent.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/time/clock_provider.dart';

enum _Answer { agree, later, readPolicy }

/// Asks before health data is first stored on this phone and remembers the answer. Returns whether the data may be
/// saved (agreed now or earlier). "Để sau", or closing the dialog, saves nothing and says so; [onReadPolicy] opens the
/// privacy policy instead, and the question comes back at the next save.
Future<bool> ensureHealthDataConsent(BuildContext context, WidgetRef ref, {required VoidCallback onReadPolicy}) async {
  final storage = ref.read(healthDataConsentStorageProvider);
  if (storage.hasConsent) {
    return true;
  }
  final clock = ref.read(clockProvider);
  final messenger = ScaffoldMessenger.of(context);
  final answer = await showDialog<_Answer>(context: context, builder: (context) => const _HealthDataConsentDialog());
  switch (answer) {
    case _Answer.agree:
      await storage.giveConsent(clock());
      return true;
    case _Answer.readPolicy:
      onReadPolicy();
      return false;
    case _Answer.later || null:
      messenger.showSnackBar(
        const SnackBar(content: Text('Chưa lưu hồ sơ. Fluw chỉ lưu thông tin sức khỏe khi bạn đồng ý.')),
      );
      return false;
  }
}

class _HealthDataConsentDialog extends StatelessWidget {
  const _HealthDataConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrolls instead of overflowing with very large text.
      scrollable: true,
      title: const Text('Đồng ý lưu thông tin sức khỏe'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ngày sinh, chiều cao, cân nặng, việc mang thai hoặc cho con bú, bệnh nền và dị ứng là dữ liệu cá nhân '
            'nhạy cảm. Fluw chỉ lưu chúng trên điện thoại này để tính chỉ tiêu, gợi ý món và cảnh báo; Fluw không gửi '
            'chúng lên máy chủ hay cho bên nào khác. Bạn sửa hoặc xóa được bất cứ lúc nào trong Hồ Sơ; xóa toàn bộ dữ '
            'liệu trên máy cũng là rút lại đồng ý này.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Fluw chỉ dành cho người từ 18 tuổi.'),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_Answer.readPolicy),
            child: const Text('Đọc chính sách quyền riêng tư'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(_Answer.later), child: const Text('Để sau')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_Answer.agree), child: const Text('Tôi đồng ý')),
      ],
    );
  }
}
