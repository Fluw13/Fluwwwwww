import 'package:fluw/features/scan/data/food_photo_picker.dart';

/// Hands back a fixed photo, or nothing to act as a cancelled picker.
class FakeFoodPhotoPicker implements FoodPhotoPicker {
  PickedPhoto? next = const PickedPhoto(bytes: [1, 2, 3], contentType: 'image/jpeg');
  final List<PhotoSource> requests = [];

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    requests.add(source);
    return next;
  }
}
