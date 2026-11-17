import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fluw/features/scan/data/food_photo_picker.dart';

/// Hands back a phone-like JPEG that still carries its GPS position, so tests see what really gets uploaded. Set
/// [next] to null for a cancelled picker, [error] for a picker that fails, [hold] to keep it open.
class FakeFoodPhotoPicker implements FoodPhotoPicker {
  static final Uint8List photoWithLocation = File('test/fixtures/photos/with_location.jpg').readAsBytesSync();

  Uint8List? next = photoWithLocation;
  Object? error;
  Completer<void>? hold;
  final List<PhotoSource> requests = [];

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    requests.add(source);
    await hold?.future;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return next;
  }
}
