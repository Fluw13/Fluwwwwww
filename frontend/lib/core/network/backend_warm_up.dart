import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluw/core/network/api_client.dart';
import 'package:fluw/core/network/api_client_provider.dart';
import 'package:fluw/core/network/api_failure.dart';

/// Called by the app when it starts and each time it comes back to the foreground. Tests replace it so their mock
/// backends only see the calls they expect.
final backendWarmUpProvider = Provider<Future<void> Function()>((ref) {
  final client = ref.watch(apiClientProvider);
  return () => wakeUpBackend(client);
});

/// Render's free plan sleeps after 15 idle minutes and the next request then waits about 50 s. Waking the server
/// when the app opens means it is usually up by the time the user searches.
Future<void> wakeUpBackend(ApiClient client) async {
  try {
    await client.getJson('/health');
  } on ApiFailure {
    // Only a warm-up: the user's own request reports its own error.
  }
}
