import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/app/erase_all_data.dart';

/// Asks first (nothing can be restored), erases, then says how it went. Returns whether everything was erased.
Future<bool> confirmAndEraseAllData(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(context: context, builder: (context) => const _ConfirmEraseDialog());
  if (confirmed != true) {
    return false;
  }
  try {
    await container.read(eraseAllDataProvider)();
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'fluw',
        context: ErrorDescription('while erasing all data on the phone'),
      ),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Chưa xóa được hết dữ liệu. Hãy thử lại; nếu vẫn lỗi, hãy đóng hẳn app, mở lại rồi thử lại.'),
      ),
    );
    return false;
  }
  messenger.showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ dữ liệu trên máy.')));
  return true;
}

class _ConfirmEraseDialog extends StatelessWidget {
  const _ConfirmEraseDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      // Scrolls instead of overflowing with very large text.
      scrollable: true,
      title: const Text('Xóa toàn bộ dữ liệu trên máy?'),
      content: const Text(
        'Xóa hồ sơ, bệnh nền, dị ứng, Nhật ký, lịch sử cân, giờ nhắc và lịch sử tìm kiếm trên máy này. Không khôi phục '
        'được. Bản sao lưu của Google/iCloud (nếu bạn bật) do tài khoản của bạn quản lý.\n\n'
        'Các lựa chọn đồng ý (lưu thông tin sức khỏe, gửi ảnh) cũng bị xóa; chế độ Sáng/Tối được giữ lại.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Hủy')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Xóa toàn bộ'),
        ),
      ],
    );
  }
}
