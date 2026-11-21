/// Why a backend call failed, in terms the UI can explain. The backend's own message is kept when it sent one.
sealed class ApiFailure implements Exception {
  const ApiFailure();
}

/// No connection, DNS failure, connection reset.
final class NetworkFailure extends ApiFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends ApiFailure {
  const TimeoutFailure();
}

/// The backend answered with an error body: `{ "error": { "code", "message" } }`.
final class ServerFailure extends ApiFailure {
  const ServerFailure({required this.statusCode, required this.code, required this.message});

  final int statusCode;
  final String code;
  final String message;
}

/// The answer was not the JSON the app expects.
final class InvalidResponseFailure extends ApiFailure {
  const InvalidResponseFailure();
}

/// A 5xx answer without the backend's error body: the host's own page while the server starts, redeploys or is
/// overloaded (Render answers 502/503 with HTML then).
final class ServerUnavailableFailure extends ApiFailure {
  const ServerUnavailableFailure();
}
