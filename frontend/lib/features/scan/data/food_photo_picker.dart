import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Takes or picks a photo; null when the user cancels. Behind an interface so tests never open the camera.
abstract interface class FoodPhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}

class ImageFoodPhotoPicker implements FoodPhotoPicker {
  ImageFoodPhotoPicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    // About 1280 px is plenty to recognize a dish and keeps the upload small on mobile data. The picker re-encodes to
    // JPEG (PNG stays PNG) but copies the original metadata, which `RecognitionApi` removes before sending.
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    return file == null ? null : await file.readAsBytes();
  }
}

final foodPhotoPickerProvider = Provider<FoodPhotoPicker>((ref) => ImageFoodPhotoPicker());
