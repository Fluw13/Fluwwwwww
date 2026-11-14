/// Override with `--dart-define=FLUW_API_BASE_URL=https://...` to point a build at another backend. It must be https:
/// Android 9+ and iOS block plain http, so a local backend needs an https tunnel.
const String apiBaseUrl = String.fromEnvironment('FLUW_API_BASE_URL', defaultValue: 'https://fluw.onrender.com');

/// Render's free plan sleeps after 15 minutes and takes about 50 seconds to wake, so the first request needs room.
const Duration apiTimeout = Duration(seconds: 70);
