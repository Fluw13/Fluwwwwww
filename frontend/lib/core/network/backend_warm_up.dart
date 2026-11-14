import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_failure.dart';

/// Render's free plan sleeps after 15 idle minutes and the next request then waits about 50 s. Waking the server
/// when the app opens means it is usually up by the time the user searches.
Future<void> wakeUpBackend(ApiClient client) async {
  try {
    await client.getJson('/health');
  } on ApiFailure {
    // Only a warm-up: the user's own request reports its own error.
  }
}
