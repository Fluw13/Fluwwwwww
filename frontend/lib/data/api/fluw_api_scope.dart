import 'package:flutter/widgets.dart';

import 'fluw_api_client.dart';

/// Gives every screen the app-wide [FluwApiClient], so tests can swap it.
class FluwApiScope extends InheritedWidget {
  const FluwApiScope({super.key, required this.client, required super.child});

  final FluwApiClient client;

  static FluwApiClient of(BuildContext context) {
    final FluwApiScope? scope = context
        .dependOnInheritedWidgetOfExactType<FluwApiScope>();
    assert(
      scope != null,
      'FluwApiScope.of() called without a FluwApiScope ancestor.',
    );
    return scope!.client;
  }

  @override
  bool updateShouldNotify(FluwApiScope oldWidget) => client != oldWidget.client;
}
