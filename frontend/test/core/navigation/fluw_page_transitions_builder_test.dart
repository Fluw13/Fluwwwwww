import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/navigation/fluw_page_transitions_builder.dart';
import 'package:frontend/core/theme/app_theme.dart';

Widget _app({bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Trang đích'))),
        ),
        child: const Text('Mở'),
      ),
    ),
  );
}

void main() {
  test('Android dùng hiệu ứng chuyển trang của Fluw, iOS giữ vuốt quay lại', () {
    final PageTransitionsTheme transitions = AppTheme.light().pageTransitionsTheme;

    expect(transitions.builders[TargetPlatform.android], isA<FluwPageTransitionsBuilder>());
    expect(transitions.builders[TargetPlatform.iOS], isNot(isA<FluwPageTransitionsBuilder>()));
  });

  testWidgets('trang đích hiện ngay khi bắt đầu chuyển và rõ hẳn sau 280 ms', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.text('Mở'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('Trang đích'), findsOneWidget);
    final FadeTransition midway = tester.widget<FadeTransition>(
      find.ancestor(of: find.text('Trang đích'), matching: find.byType(FadeTransition)).first,
    );
    expect(midway.opacity.value, inExclusiveRange(0, 1));

    await tester.pump(const Duration(milliseconds: 280));
    final FadeTransition done = tester.widget<FadeTransition>(
      find.ancestor(of: find.text('Trang đích'), matching: find.byType(FadeTransition)).first,
    );
    expect(done.opacity.value, 1);
  });

  testWidgets('giảm chuyển động thì không bọc hiệu ứng', (tester) async {
    await tester.pumpWidget(_app(disableAnimations: true));

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: find.text('Trang đích'), matching: find.byType(SlideTransition)),
      findsNothing,
    );
  });
}
