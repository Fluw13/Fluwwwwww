import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/core/time/current_hour_provider.dart';

import '../helpers/pump_fluw_app.dart';

void main() {
  testWidgets('quay lại app thì tính lại giờ hiện tại (đồng hồ hẹn giờ dừng khi máy ngủ)', (tester) async {
    var reads = 0;
    await pumpFluwApp(
      tester,
      overrides: [
        currentHourProvider.overrideWith((ref) {
          reads++;
          return 22;
        }),
      ],
    );
    final before = reads;
    expect(before, greaterThan(0), reason: 'Trang Chủ đọc giờ cho lời khuyên buổi tối');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(reads, before + 1);
  });
}
