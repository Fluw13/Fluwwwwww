/// For a future created in `setState` and shown by a `FutureBuilder` on the
/// next frame. An error that arrives before that rebuild (a cancelled token,
/// an instant network failure) would otherwise be reported as uncaught.
/// Listeners added later still receive the error.
Future<T> handledLater<T>(Future<T> future) {
  future.ignore();
  return future;
}
