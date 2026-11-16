import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/network/api_failure_message.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/scan/data/food_photo_picker.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/scan/data/recognition_api.dart';
import 'package:fluw/features/scan/domain/recognition_result.dart';

sealed class _PhotoState {
  const _PhotoState();
}

final class _Idle extends _PhotoState {
  const _Idle();
}

final class _Recognizing extends _PhotoState {
  const _Recognizing();
}

final class _Recognized extends _PhotoState {
  const _Recognized(this.result);

  final RecognitionResult result;
}

final class _Failed extends _PhotoState {
  const _Failed(this.message);

  final String message;
}

/// Photo → food names → search. The names come from AI and are labelled as such; the nutrition the user then sees
/// comes from Open Food Facts or USDA. Asks for consent once before the first photo leaves the phone.
class PhotoRecognitionPanel extends ConsumerStatefulWidget {
  const PhotoRecognitionPanel({required this.onSearchFood, super.key});

  final ValueChanged<String> onSearchFood;

  @override
  ConsumerState<PhotoRecognitionPanel> createState() => _PhotoRecognitionPanelState();
}

class _PhotoRecognitionPanelState extends ConsumerState<PhotoRecognitionPanel> {
  _PhotoState _state = const _Idle();

  Future<bool> _ensureConsent() async {
    final storage = ref.read(photoConsentStorageProvider);
    if (storage.hasConsent) {
      return true;
    }
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Gửi ảnh để nhận diện món?'),
        content: const Text(
          'Ảnh được gửi qua máy chủ Fluw tới Google Gemini để nhận ra tên món. Fluw không lưu ảnh. '
          'Với gói miễn phí, Google có thể dùng ảnh để cải thiện sản phẩm của họ, nên đừng chụp người, '
          'giấy tờ hay thông tin cá nhân.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Không')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Đồng ý')),
        ],
      ),
    );
    if (agreed ?? false) {
      await storage.giveConsent();
      return true;
    }
    return false;
  }

  Future<void> _recognize(PhotoSource source) async {
    if (!await _ensureConsent() || !mounted) {
      return;
    }
    final PickedPhoto? photo;
    try {
      photo = await ref.read(foodPhotoPickerProvider).pick(source);
    } on Object {
      if (mounted) {
        setState(() => _state = const _Failed('Không mở được camera hoặc thư viện ảnh. Hãy kiểm tra quyền của Fluw.'));
      }
      return;
    }
    if (photo == null || !mounted) {
      return;
    }
    setState(() => _state = const _Recognizing());
    try {
      final result = await ref.read(recognitionApiProvider).recognize(photo.bytes, contentType: photo.contentType);
      if (mounted) {
        setState(() => _state = _Recognized(result));
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _state = _Failed(_failureMessage(failure)));
      }
    }
  }

  // The picker cannot shrink every format (some HEIC photos stay full size), so the 4 MB limit can still be hit.
  String _failureMessage(ApiFailure failure) => failure is ServerFailure && failure.statusCode == 413
      ? 'Ảnh quá lớn. Hãy chọn ảnh khác hoặc chụp lại.'
      : apiFailureMessage(failure);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final busy = _state is _Recognizing;

    return SectionCard(
      title: 'Nhận diện món qua ảnh',
      children: [
        Text('Chụp hoặc chọn ảnh món ăn; Fluw gợi ý tên món để bạn tra số liệu dinh dưỡng.', style: muted),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : () => _recognize(PhotoSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Chụp ảnh'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _recognize(PhotoSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...switch (_state) {
          _Idle() => const <Widget>[],
          _Recognizing() => [
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.xs),
            Text('Đang nhận diện... Lần đầu có thể mất gần một phút khi máy chủ khởi động.', style: muted),
          ],
          _Failed(:final message) => [Text(message, style: TextStyle(color: theme.colorScheme.error))],
          _Recognized(:final result) when !result.isFood => [
            Text('Không thấy món ăn trong ảnh. Hãy chụp gần và rõ món ăn hơn.', style: theme.textTheme.bodyMedium),
          ],
          _Recognized(:final result) => [
            Text('AI (Google Gemini) gợi ý, có thể sai. Chọn món để tra số liệu:', style: muted),
            for (final food in result.foods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search),
                title: Text(food.name),
                subtitle: Text('Tìm "${food.searchQuery}"'),
                onTap: () => widget.onSearchFood(food.searchQuery),
              ),
          ],
        },
      ],
    );
  }
}
