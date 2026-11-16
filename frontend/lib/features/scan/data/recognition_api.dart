import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/features/scan/domain/recognition_result.dart';

/// Sends a food photo to the Fluw backend, which asks the vision model for the food names.
final class RecognitionApi {
  const RecognitionApi(this._client);

  final ApiClient _client;

  Future<RecognitionResult> recognize(List<int> photo, {required String contentType}) async {
    final json = await _client.postBytes('/api/foods/recognize', photo, contentType: contentType);
    final foods = json['foods'];
    if (json['isFood'] is! bool || foods is! List) {
      throw const InvalidResponseFailure();
    }
    return RecognitionResult(
      foods: [
        for (final food in foods)
          if (food case {'name': final String name, 'searchQuery': final String searchQuery}
              when name.trim().isNotEmpty && searchQuery.trim().length >= 2)
            RecognizedFood(name: name.trim(), searchQuery: searchQuery.trim()),
      ],
    );
  }
}

final recognitionApiProvider = Provider<RecognitionApi>((ref) => RecognitionApi(ref.watch(apiClientProvider)));
