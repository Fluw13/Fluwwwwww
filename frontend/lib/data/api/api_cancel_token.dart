/// Lets a screen abort its in-flight requests when it is closed.
///
/// Listeners run synchronously inside [cancel], so the request's timeout
/// timer is released in the same frame the screen is disposed.
class ApiCancelToken {
  final List<void Function()> _listeners = [];
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    final List<void Function()> listeners = List.of(_listeners);
    _listeners.clear();
    for (final void Function() listener in listeners) {
      listener();
    }
  }

  /// Returns a callback that removes [listener] again.
  void Function() onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
      return _noop;
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  static void _noop() {}
}
