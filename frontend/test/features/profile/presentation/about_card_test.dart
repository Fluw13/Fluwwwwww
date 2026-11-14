import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/app/app_tab.dart';
import 'package:fluw/app/shell/fluw_bottom_bar.dart';
import 'package:fluw/features/profile/data/profile_providers.dart';
import 'package:fluw/features/profile/presentation/about_card.dart';

import '../../../helpers/pump_fluw_app.dart';
import '../domain/profile_fixture.dart';

void main() {
  testWidgets('thẻ Về Fluw ghi nguồn dữ liệu và mở được trang giấy phép', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AboutCard())));

    expect(find.textContaining('Open Food Facts (ODbL)'), findsOneWidget);
    expect(find.textContaining('USDA FoodData Central (CC0)'), findsOneWidget);

    await tester.tap(find.text('Nguồn dữ liệu và giấy phép'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('trang giấy phép mở toàn màn hình, che thanh tab như các trang mở từ tab khác', (tester) async {
    await pumpFluwApp(tester);
    await tester.runAsync(() => appContainer(tester).read(profileRepositoryProvider).save(buildProfile()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppTab.profile.label).last);
    await tester.pumpAndSettle();
    final list = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axis == Axis.vertical).hitTestable();
    final element = list.evaluate().first;
    await tester.scrollUntilVisible(
      find.text('Nguồn dữ liệu và giấy phép'),
      200,
      scrollable: find.byElementPredicate((e) => identical(e, element)),
      maxScrolls: 500,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nguồn dữ liệu và giấy phép'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.byType(FluwBottomBar).hitTestable(), findsNothing);
  });
}
