import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/network/api_failure_message.dart';
import 'package:fluw/core/nutrition/personal_limits.dart';
import 'package:fluw/core/nutrition/personal_limits_provider.dart';
import 'package:fluw/core/theme/app_radius.dart';
import 'package:fluw/core/theme/app_spacing.dart';
import 'package:fluw/core/widgets/section_card.dart';
import 'package:fluw/features/scan/data/food_photo_picker.dart';
import 'package:fluw/features/scan/data/photo_consent_storage.dart';
import 'package:fluw/features/scan/data/recognition_api.dart';
import 'package:fluw/features/scan/domain/recognition_result.dart';
import 'package:fluw/features/scan/presentation/viewfinder_corners.dart';

sealed class _PhotoState {
  const _PhotoState();
}

final class _Idle extends _PhotoState {
  const _Idle();
}

/// The camera or the photo library is open.
final class _Picking extends _PhotoState {
  const _Picking();
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

enum _ConsentAnswer { agree, decline, readPolicy }

/// Changing this text in substance means raising `PhotoConsentStorage.currentVersion`, so everyone is asked again.
class _PhotoConsentDialog extends StatelessWidget {
  const _PhotoConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Gửi ảnh để nhận diện món?'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh được gửi qua máy chủ Fluw (đặt tại Hoa Kỳ) tới Google Gemini để nhận ra tên món. Trước khi gửi, Fluw '
            'xóa thông tin vị trí và thời gian chụp trong ảnh; máy chủ Fluw không lưu ảnh. Fluw dùng gói miễn phí của '
            'Google nên Google có thể lưu ảnh, cho người xem lại và dùng để cải thiện sản phẩm của họ; đừng chụp '
            'người, giấy tờ hay thông tin cá nhân. Bạn rút lại đồng ý được bất cứ lúc nào trong màn này, nhưng Fluw '
            'không xóa được những ảnh đã gửi trước đó khỏi Google.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Tính năng này chỉ dành cho người dùng ở Việt Nam.'),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ConsentAnswer.readPolicy),
            child: const Text('Đọc chính sách quyền riêng tư'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(_ConsentAnswer.decline), child: const Text('Không')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_ConsentAnswer.agree), child: const Text('Đồng ý')),
      ],
    );
  }
}

/// Photo → food names → search. The names come from AI and are labelled as such; the nutrition the user then sees
/// comes from Open Food Facts or USDA. Asks for consent before the first photo leaves the phone; adults only.
class PhotoRecognitionPanel extends ConsumerStatefulWidget {
  const PhotoRecognitionPanel({required this.onSearchFood, required this.onOpenPrivacy, super.key});

  final ValueChanged<RecognizedFood> onSearchFood;
  final VoidCallback onOpenPrivacy;

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
    final answer = await showDialog<_ConsentAnswer>(
      context: context,
      builder: (context) => const _PhotoConsentDialog(),
    );
    switch (answer) {
      case _ConsentAnswer.agree:
        await storage.giveConsent();
        return true;
      case _ConsentAnswer.readPolicy:
        widget.onOpenPrivacy();
        return false;
      case _ConsentAnswer.decline || null:
        return false;
    }
  }

  Future<void> _recognize(PhotoSource source) async {
    if (!await _ensureConsent() || !mounted) {
      return;
    }
    setState(() => _state = const _Picking());
    final Uint8List? photo;
    try {
      photo = await ref.read(foodPhotoPickerProvider).pick(source);
    } on Object {
      if (mounted) {
        setState(() => _state = const _Failed('Không mở được camera hoặc thư viện ảnh. Hãy kiểm tra quyền của Fluw.'));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (photo == null) {
      setState(() => _state = const _Idle());
      return;
    }
    setState(() => _state = const _Recognizing());
    try {
      final result = await ref.read(recognitionApiProvider).recognize(photo);
      if (mounted) {
        setState(() => _state = _Recognized(result));
      }
    } on UnsupportedPhotoFormat {
      if (mounted) {
        setState(() => _state = const _Failed('Ảnh dạng này chưa gửi được. Hãy chụp ảnh mới hoặc chọn ảnh JPEG, PNG.'));
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

  Future<void> _withdrawConsent() async {
    await ref.read(photoConsentStorageProvider).withdrawConsent();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã rút lại đồng ý. Lần sau Fluw sẽ hỏi trước khi gửi ảnh.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final limits = ref.watch(personalLimitsProvider);
    if (!limits.isAdult) {
      return SectionCard(
        title: 'Nhận diện món qua ảnh',
        children: [Text(_adultsOnlyMessage(limits.profileStatus), style: theme.textTheme.bodyMedium)],
      );
    }
    final busy = _state is _Picking || _state is _Recognizing;
    final hasConsent = ref.read(photoConsentStorageProvider).hasConsent;

    return SectionCard(
      title: 'Nhận diện món qua ảnh',
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: ViewfinderCorners(color: theme.colorScheme.primary, length: AppSpacing.md, thickness: 3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chụp hoặc chọn ảnh món ăn; Fluw gợi ý tên món để bạn tra số liệu dinh dưỡng. Khẩu phần do bạn '
                      'chọn, Fluw không ước lượng từ ảnh.',
                      textAlign: TextAlign.center,
                      style: muted,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: busy ? null : () => _recognize(PhotoSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Chụp ảnh'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: busy ? null : () => _recognize(PhotoSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Chọn ảnh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Read out by screen readers as it changes.
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (_state) {
              _Idle() || _Picking() => const <Widget>[],
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
                Row(
                  children: [
                    Icon(Icons.auto_awesome_outlined, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text('AI (Google Gemini) gợi ý, có thể sai. Chọn món để tra số liệu:', style: muted),
                    ),
                  ],
                ),
                for (final food in result.foods)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(Icons.search, color: theme.colorScheme.primary),
                        title: Text(food.name, style: theme.textTheme.titleMedium),
                        subtitle: Text('Tìm "${food.searchQuery}"'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onSearchFood(food),
                      ),
                    ),
                  ),
              ],
            },
          ),
        ),
        if (hasConsent && !busy)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: _withdrawConsent, child: const Text('Rút lại đồng ý gửi ảnh')),
          ),
      ],
    );
  }

  String _adultsOnlyMessage(ProfileStatus status) => switch (status) {
    ProfileStatus.loading => 'Đang đọc hồ sơ...',
    ProfileStatus.none =>
      'Nhận diện ảnh dùng Google Gemini, chỉ dành cho người từ 18 tuổi. Hãy thiết lập hồ sơ ở tab Hồ Sơ để dùng; '
          'bạn vẫn quét mã vạch hoặc tìm theo tên được.',
    ProfileStatus.unreadable =>
      'Không đọc được hồ sơ nên chưa biết tuổi của bạn. Nhận diện ảnh dùng Google Gemini, chỉ dành cho người từ 18 '
          'tuổi; bạn vẫn quét mã vạch hoặc tìm theo tên được.',
    ProfileStatus.loaded =>
      'Nhận diện ảnh dùng Google Gemini, chỉ dành cho người từ 18 tuổi theo điều khoản của Google. Bạn vẫn quét mã '
          'vạch hoặc tìm theo tên được.',
  };
}
