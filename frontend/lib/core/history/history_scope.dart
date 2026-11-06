import 'package:flutter/widgets.dart';

import 'session_history.dart';

class HistoryScope extends InheritedNotifier<SessionHistory> {
  const HistoryScope({super.key, required SessionHistory history, required super.child})
      : super(notifier: history);

  /// Rebuilds the caller when the history changes. Null outside a scope.
  static SessionHistory? watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HistoryScope>()?.notifier;
  }

  /// For writes from callbacks; does not rebuild the caller.
  static SessionHistory? read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<HistoryScope>()?.notifier;
  }
}
