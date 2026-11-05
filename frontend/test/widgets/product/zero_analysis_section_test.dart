import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/format/ai_error_text.dart';
import 'package:frontend/data/api/api_cancel_token.dart';
import 'package:frontend/data/api/api_error_kind.dart';
import 'package:frontend/data/api/fluw_api_exception.dart';
import 'package:frontend/models/analysis/product_analysis.dart';
import 'package:frontend/widgets/product/zero_analysis_section.dart';
import 'package:frontend/widgets/zero_analysis_card.dart';

import '../../helpers/contract_fixtures.dart';
import '../../helpers/test_app.dart';

ProductAnalysis _fixture(String name) =>
    ProductAnalysis.fromJson(ContractFixture.load(name).body);

/// Counts calls and answers each one with the next item of [answers]: a
/// [ProductAnalysis], an error to throw, or a [Completer] to finish later.
class _FakeLoader {
  _FakeLoader(this.answers);

  final List<Object> answers;
  final List<ApiCancelToken> tokens = [];

  int get calls => tokens.length;

  Future<ProductAnalysis> call(ApiCancelToken token) {
    tokens.add(token);
    final Object answer =
        answers[(tokens.length - 1).clamp(0, answers.length - 1)];
    return switch (answer) {
      final ProductAnalysis analysis => Future.value(analysis),
      final Completer<ProductAnalysis> pending => pending.future,
      _ => Future.error(answer),
    };
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeLoader loader, {
  bool autoLoad = false,
  String? scoreVersion,
}) {
  return pumpOnPhone(
    tester,
    SingleChildScrollView(
      child: ZeroAnalysisSection(
        loadAnalysis: loader.call,
        scoreVersion: scoreVersion ?? 'fluw-score-1.0',
        autoLoad: autoLoad,
      ),
    ),
  );
}

/// Lets the request settle and the 220 ms cross-fade finish. A ticker's first
/// frame only starts its clock, so one more step is needed before the
/// outgoing card is removed.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _ask(WidgetTester tester) async {
  await tester.tap(find.text(ZeroAnalysisCard.askLabel));
  await _settle(tester);
}

void main() {
  testWidgets('mặc định chỉ hiện nút "Hỏi Zero", chưa gọi AI', (tester) async {
    final _FakeLoader loader = _FakeLoader([_fixture('analysis-ok')]);
    await _pump(tester, loader);

    expect(find.text(ZeroAnalysisCard.askLabel), findsOneWidget);
    expect(find.text(ZeroAnalysisCard.aiLabel), findsOneWidget);
    expect(loader.calls, 0);
  });

  testWidgets(
    'bấm "Hỏi Zero": đang viết → tóm tắt, ý chính, gợi ý, nhóm thay thế, nhãn AI, miễn trừ',
    (tester) async {
      final Completer<ProductAnalysis> pending = Completer();
      final _FakeLoader loader = _FakeLoader([pending]);
      await _pump(tester, loader);

      await _ask(tester);
      expect(loader.calls, 1);
      expect(find.text(ZeroAnalysisCard.writingText), findsOneWidget);

      pending.complete(_fixture('analysis-ok'));
      await _settle(tester);

      expect(
        find.textContaining('Bánh quy bơ (dữ liệu thử) có Điểm Fluw 31/100'),
        findsOneWidget,
      );
      expect(find.text('Điểm chính'), findsOneWidget);
      expect(
        find.text('• Năng lượng 2.000 kJ/100 g, bị trừ 5/10 điểm.'),
        findsOneWidget,
      );
      expect(find.text('Gợi ý'), findsOneWidget);
      expect(find.text('Nhóm sản phẩm có thể cân nhắc'), findsOneWidget);
      expect(find.text('• Trái cây tươi'), findsOneWidget);
      expect(find.text(ZeroAnalysisCard.aiLabel), findsOneWidget);
      expect(find.textContaining('AI không chấm điểm'), findsOneWidget);
      expect(find.text(ZeroAnalysisCard.askLabel), findsNothing);
    },
  );

  testWidgets('cờ tự tải bật thì gọi ngay khi hiện', (tester) async {
    final _FakeLoader loader = _FakeLoader([_fixture('analysis-ok')]);
    await _pump(tester, loader, autoLoad: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(loader.calls, 1);
    expect(find.text('Điểm chính'), findsOneWidget);
  });

  testWidgets('AI tạm lỗi: câu riêng, bấm thử lại thì gọi lại', (tester) async {
    final _FakeLoader loader = _FakeLoader([
      _fixture('analysis-ai-unavailable'),
      _fixture('analysis-ok'),
    ]);
    await _pump(tester, loader);

    await _ask(tester);
    expect(
      find.text(AiErrorText.message(AiErrorCode.unavailable)),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(loader.calls, 2);
    expect(find.text('Điểm chính'), findsOneWidget);
  });

  for (final (String fixture, AiErrorCode code) in [
    ('analysis-ai-daily-limit', AiErrorCode.dailyLimit),
  ]) {
    testWidgets('$code: câu riêng, không có nút thử lại', (tester) async {
      final _FakeLoader loader = _FakeLoader([_fixture(fixture)]);
      await _pump(tester, loader);
      await _ask(tester);

      expect(find.text(AiErrorText.message(code)), findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);
    });
  }

  testWidgets(
    'mỗi mã lỗi AI có câu riêng; chỉ AI_NOT_CONFIGURED và AI_DAILY_LIMIT không cho thử lại',
    (tester) async {
      final Set<String> messages = {};
      for (final AiErrorCode code in AiErrorCode.values) {
        messages.add(AiErrorText.message(code));
        expect(
          AiErrorText.canRetry(code),
          code != AiErrorCode.notConfigured && code != AiErrorCode.dailyLimit,
          reason: code.name,
        );
      }
      expect(messages, hasLength(AiErrorCode.values.length));

      final _FakeLoader loader = _FakeLoader([
        ProductAnalysis.fromJson({
          'aiAnalysis': null,
          'aiError': 'AI_NOT_CONFIGURED',
        }),
      ]);
      await _pump(tester, loader);
      await _ask(tester);
      expect(
        find.text(AiErrorText.message(AiErrorCode.notConfigured)),
        findsOneWidget,
      );
      expect(find.text('Thử lại'), findsNothing);
    },
  );

  testWidgets(
    'máy chủ giới hạn lượt (429): khóa nút theo Retry-After, không tự gửi lại',
    (tester) async {
      final _FakeLoader loader = _FakeLoader([
        FluwApiException(
          kind: ApiErrorKind.rateLimited,
          statusCode: 429,
          retryAfter: const Duration(seconds: 5),
        ),
        _fixture('analysis-ok'),
      ]);
      await _pump(tester, loader);
      await _ask(tester);

      expect(
        find.text(ApiErrorKind.rateLimited.defaultMessage),
        findsOneWidget,
      );
      expect(find.text('Thử lại sau 5 giây'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(loader.calls, 1);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(loader.calls, 2);
    },
  );

  testWidgets('sản phẩm không còn (404): không cho thử lại', (tester) async {
    final _FakeLoader loader = _FakeLoader([
      FluwApiException(kind: ApiErrorKind.productNotFound, statusCode: 404),
    ]);
    await _pump(tester, loader);
    await _ask(tester);

    expect(
      find.text(ApiErrorKind.productNotFound.defaultMessage),
      findsOneWidget,
    );
    expect(find.text('Thử lại'), findsNothing);
  });

  testWidgets('giải thích viết cho công thức khác thì có ghi chú', (
    tester,
  ) async {
    final _FakeLoader loader = _FakeLoader([_fixture('analysis-ok')]);
    await _pump(tester, loader, scoreVersion: 'fluw-score-2.0');
    await _ask(tester);

    expect(
      find.textContaining('khác công thức fluw-score-2.0'),
      findsOneWidget,
    );
  });

  testWidgets('rời màn thì hủy request đang chờ', (tester) async {
    final _FakeLoader loader = _FakeLoader([Completer<ProductAnalysis>()]);
    await _pump(tester, loader);
    await _ask(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(loader.tokens.single.isCancelled, isTrue);
  });

  for (final Size size in [const Size(360, 640), const Size(320, 640)]) {
    testWidgets(
      'chữ 200% không tràn khi có kết quả (${size.width.toInt()} px)',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final _FakeLoader loader = _FakeLoader([_fixture('analysis-ok')]);

        await pumpOnPhone(
          tester,
          SingleChildScrollView(
            child: ZeroAnalysisSection(
              loadAnalysis: loader.call,
              scoreVersion: 'fluw-score-1.0',
            ),
          ),
          size: size,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(ZeroAnalysisCard.askLabel));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
