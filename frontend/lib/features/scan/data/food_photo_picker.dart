import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

final class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.contentType});

  final List<int> bytes;
  final String contentType;
}

/// Takes or picks a photo; null when the user cancels. Behind an interface so tests never open the camera.
abstract interface class FoodPhotoPicker {
  Future<PickedPhoto?> pick(PhotoSource source);
}

class ImageFoodPhotoPicker implements FoodPhotoPicker {
  ImageFoodPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    // About 1280 px is plenty to recognize a dish and keeps the upload small on mobile data.
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (file == null) {
      return null;
    }
    return PickedPhoto(bytes: await file.readAsBytes(), contentType: contentTypeOf(file.name, file.mimeType));
  }
}

/// The backend accepts JPEG, PNG, WebP and HEIC; anything else is sent as JPEG, which the picker produces when it
/// resizes.
String contentTypeOf(String fileName, String? mimeType) {
  if (mimeType != null && mimeType.startsWith('image/')) {
    return mimeType;
  }
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };
}

final foodPhotoPickerProvider = Provider<FoodPhotoPicker>((ref) => ImageFoodPhotoPicker());
