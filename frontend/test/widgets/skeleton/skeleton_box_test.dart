import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/skeleton/shimmer_scope.dart';
import 'package:frontend/widgets/skeleton/skeleton_box.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('SkeletonBox có kích thước đúng và không lộ ra trình đọc màn hình', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const Center(child: SkeletonBox(width: 120, height: 20))));

    expect(tester.getSize(find.byType(SkeletonBox)), const Size(120, 20));
    expect(find.descendant(of: find.byType(SkeletonBox), matching: find.byType(ExcludeSemantics)), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('SkeletonBox.circle vuông và bo tròn', (tester) async {
    await tester.pumpWidget(_wrap(const Center(child: SkeletonBox.circle(size: 48))));

    expect(tester.getSize(find.byType(SkeletonBox)), const Size(48, 48));
  });

  testWidgets('ShimmerScope chạy hiệu ứng khi được phép', (tester) async {
    await tester.pumpWidget(_wrap(const ShimmerScope(child: SkeletonBox(width: 100, height: 12))));

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(ShimmerScope.period ~/ 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShimmerScope đứng yên khi người dùng bật giảm chuyển động', (tester) async {
    await tester.pumpWidget(
      _wrap(const ShimmerScope(child: SkeletonBox(width: 100, height: 12)), disableAnimations: true),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('một ShimmerScope dùng chung cho nhiều SkeletonBox', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const ShimmerScope(
          child: Column(
            children: [
              SkeletonBox(width: 100, height: 12),
              SkeletonBox.text(width: 80, fontSize: 12),
              SkeletonBox.circle(size: 32),
            ],
          ),
        ),
      ),
    );

    final BuildContext first = tester.element(find.byType(SkeletonBox).first);
    final BuildContext last = tester.element(find.byType(SkeletonBox).last);
    expect(ShimmerScope.maybeOf(first), isNotNull);
    expect(ShimmerScope.maybeOf(first), same(ShimmerScope.maybeOf(last)));
  });
}
