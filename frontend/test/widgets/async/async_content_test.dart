import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/async/async_content.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.initial});

  final Future<String> initial;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late Future<String> future = widget.initial;

  void retryWith(Future<String> next) {
    setState(() {
      future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AsyncContent<String>(
      future: future,
      loadingBuilder: (_) => const Text('loading'),
      dataBuilder: (_, data) => Text('data:$data'),
      errorBuilder: (_, error) => Text('error:$error'),
    );
  }
}

class _CountsInit extends StatefulWidget {
  const _CountsInit({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_CountsInit> createState() => _CountsInitState();
}

class _CountsInitState extends State<_CountsInit> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('loading');
}

Future<void> _pump(WidgetTester tester, Future<String> future) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: _Harness(initial: future))));
}

void main() {
  testWidgets('hiện màn tải trước, rồi chuyển sang dữ liệu', (tester) async {
    final Completer<String> completer = Completer();
    await _pump(tester, completer.future);

    expect(find.text('loading'), findsOneWidget);

    completer.complete('sữa chua');
    await tester.pumpAndSettle();

    expect(find.text('data:sữa chua'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
  });

  testWidgets('hiện màn lỗi khi future thất bại', (tester) async {
    final Completer<String> completer = Completer();
    await _pump(tester, completer.future);

    completer.completeError('mất mạng');
    await tester.pumpAndSettle();

    expect(find.text('error:mất mạng'), findsOneWidget);
  });

  testWidgets('thử lại với future mới thì quay về màn tải, không hiện lỗi cũ', (tester) async {
    final Completer<String> first = Completer();
    await _pump(tester, first.future);
    first.completeError('lỗi lần 1');
    await tester.pumpAndSettle();
    expect(find.text('error:lỗi lần 1'), findsOneWidget);

    final Completer<String> retry = Completer();
    tester.state<_HarnessState>(find.byType(_Harness)).retryWith(retry.future);
    await tester.pumpAndSettle();

    expect(find.text('loading'), findsOneWidget);
    expect(find.text('error:lỗi lần 1'), findsNothing);

    retry.complete('ok');
    await tester.pumpAndSettle();
    expect(find.text('data:ok'), findsOneWidget);
  });

  testWidgets('màn tải đang mờ dần vẫn giữ nguyên trạng thái, không bị dựng lại', (tester) async {
    int initCount = 0;
    final Completer<String> completer = Completer();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncContent<String>(
            future: completer.future,
            loadingBuilder: (_) => _CountsInit(onInit: () => initCount++),
            dataBuilder: (_, data) => Text('data:$data'),
            errorBuilder: (_, error) => Text('error:$error'),
          ),
        ),
      ),
    );
    expect(initCount, 1);

    completer.complete('x');
    await tester.pump();
    await tester.pump(AsyncContent.switchDuration ~/ 2);

    expect(find.byType(_CountsInit), findsOneWidget);
    expect(initCount, 1);

    await tester.pumpAndSettle();
    expect(find.text('data:x'), findsOneWidget);
  });

  testWidgets('giảm chuyển động thì đổi nội dung ngay, không crossfade', (tester) async {
    final Completer<String> completer = Completer();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: _Harness(initial: completer.future)),
        ),
      ),
    );

    completer.complete('x');
    await tester.pump();

    expect(find.text('data:x'), findsOneWidget);
    expect(find.text('loading'), findsNothing);
  });
}
