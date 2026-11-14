/// Override with `--dart-define=FLUW_API_BASE_URL=http://10.0.2.2:5000` to point a debug build at a local backend.
const String apiBaseUrl = String.fromEnvironment('FLUW_API_BASE_URL', defaultValue: 'https://fluw.onrender.com');

/// Render's free plan sleeps after 15 minutes and takes about 50 seconds to wake, so the first request needs room.
const Duration apiTimeout = Duration(seconds: 70);
