import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/network/backend_warm_up.dart';

import '../helpers/pump_fluw_app.dart';

void main() {
  testWidgets('đánh thức máy chủ khi mở app và mỗi lần quay lại app', (tester) async {
    var calls = 0;
    await pumpFluwApp(
      tester,
      overrides: [
        backendWarmUpProvider.overrideWithValue(() async {
          calls++;
        }),
      ],
    );
    expect(calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(calls, 2);
  });
}
