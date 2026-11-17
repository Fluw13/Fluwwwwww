import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/scan/domain/photo_metadata.dart';
import 'package:fluw/features/scan/domain/recognition_result.dart';

/// The photo is neither JPEG nor PNG (or is damaged), so its location data could not be removed and it is not sent.
final class UnsupportedPhotoFormat implements Exception {
  const UnsupportedPhotoFormat();
}

/// Sends a food photo to the Fluw backend, which asks the vision model for the food names. Only the picture leaves
/// the phone: its metadata (GPS position, time, phone model) is removed first.
final class RecognitionApi {
  const RecognitionApi(this._client);

  final ApiClient _client;

  Future<RecognitionResult> recognize(Uint8List photo) async {
    final clean = removePhotoMetadata(photo);
    if (clean == null) {
      throw const UnsupportedPhotoFormat();
    }
    final json = await _client.postBytes('/api/foods/recognize', clean.bytes, contentType: clean.contentType);
    final foods = json['foods'];
    if (json['isFood'] is! bool || foods is! List) {
      throw const InvalidResponseFailure();
    }
    return RecognitionResult(
      foods: [
        for (final food in foods)
          if (food case {'name': final String name, 'searchQuery': final String searchQuery}
              when name.trim().isNotEmpty && searchQuery.trim().length >= 2)
            RecognizedFood(
              name: name.trim(),
              searchQuery: searchQuery.trim(),
              englishQuery: switch (food['searchQueryEn']) {
                final String english when english.trim().length >= 2 => english.trim(),
                _ => null,
              },
            ),
      ],
    );
  }
}

final recognitionApiProvider = Provider<RecognitionApi>((ref) => RecognitionApi(ref.watch(apiClientProvider)));
