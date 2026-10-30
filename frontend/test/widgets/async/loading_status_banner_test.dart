import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/async/loading_status_banner.dart';

const String _slowHint = 'Máy chủ đang khởi động';

Widget _banner() {
  return const MaterialApp(
    home: Scaffold(
      body: LoadingStatusBanner(
        title: 'Đang mở chi tiết sản phẩm',
        subtitle: 'Mã 8934563138165',
        slowHint: _slowHint,
      ),
    ),
  );
}

void main() {
  testWidgets('hiện tên màn đang mở và nội dung đang tải', (tester) async {
    await tester.pumpWidget(_banner());

    expect(find.text('Đang mở chi tiết sản phẩm'), findsOneWidget);
    expect(find.text('Mã 8934563138165'), findsOneWidget);
    expect(find.text(_slowHint), findsNothing);
  });

  testWidgets('chỉ hiện gợi ý tải chậm sau 8 giây', (tester) async {
    await tester.pumpWidget(_banner());

    await tester.pump(const Duration(seconds: 7));
    expect(find.text(_slowHint), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_slowHint), findsOneWidget);
  });

  testWidgets('giảm chuyển động thì biểu tượng đứng yên', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LoadingStatusBanner(title: 'Đang mở')),
        ),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('đổi gợi ý sau khi đã dựng thì hẹn giờ lại theo giá trị mới', (tester) async {
    Widget build(String? hint) => MaterialApp(
          home: Scaffold(
            body: LoadingStatusBanner(title: 'Đang mở', slowHint: hint, slowAfter: const Duration(seconds: 3)),
          ),
        );

    await tester.pumpWidget(build(null));
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(build(_slowHint));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(_slowHint), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_slowHint), findsOneWidget);
  });

  testWidgets('rời màn trước 8 giây không gây lỗi setState sau dispose', (tester) async {
    await tester.pumpWidget(_banner());
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 10));

    expect(tester.takeException(), isNull);
  });
}
