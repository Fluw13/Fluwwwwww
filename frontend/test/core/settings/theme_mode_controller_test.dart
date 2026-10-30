import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/settings/theme_mode_controller.dart';
import 'package:frontend/core/settings/theme_mode_store.dart';

class _ThrowingErrorStore implements ThemeModeStore {
  @override
  Future<ThemeMode?> read() async => throw StateError('no platform implementation');

  @override
  Future<void> write(ThemeMode mode) async => throw StateError('no platform implementation');
}

class _NeverAnsweringStore implements ThemeModeStore {
  @override
  Future<ThemeMode?> read() => Completer<ThemeMode?>().future;

  @override
  Future<void> write(ThemeMode mode) => Completer<void>().future;
}

class _FakeThemeModeStore implements ThemeModeStore {
  _FakeThemeModeStore({this.stored, this.failOnRead = false, this.failOnWrite = false});

  ThemeMode? stored;
  final bool failOnRead;
  final bool failOnWrite;
  final List<ThemeMode> writes = [];

  @override
  Future<ThemeMode?> read() async {
    if (failOnRead) throw Exception('read failed');
    return stored;
  }

  @override
  Future<void> write(ThemeMode mode) async {
    if (failOnWrite) throw Exception('write failed');
    writes.add(mode);
    stored = mode;
  }
}

void main() {
  test('mặc định theo cài đặt của máy khi chưa lưu lựa chọn', () async {
    final ThemeModeController controller = ThemeModeController(_FakeThemeModeStore());
    await controller.load();

    expect(controller.mode, ThemeMode.system);
  });

  test('khôi phục lựa chọn đã lưu trên máy', () async {
    final ThemeModeController controller = ThemeModeController(_FakeThemeModeStore(stored: ThemeMode.dark));
    int notifications = 0;
    controller.addListener(() => notifications++);

    await controller.load();

    expect(controller.mode, ThemeMode.dark);
    expect(notifications, 1);
  });

  test('đọc bộ nhớ lỗi thì giữ mặc định, không làm hỏng lúc mở app', () async {
    final ThemeModeController controller = ThemeModeController(_FakeThemeModeStore(failOnRead: true));
    await controller.load();

    expect(controller.mode, ThemeMode.system);
  });

  test('bộ nhớ ném Error (không phải Exception) cũng không làm hỏng lúc mở app', () async {
    final ThemeModeController controller = ThemeModeController(_ThrowingErrorStore());

    await controller.load();
    expect(controller.mode, ThemeMode.system);

    await controller.setMode(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);
  });

  test('bộ nhớ không phản hồi thì hết thời gian chờ và giữ mặc định', () async {
    final ThemeModeController controller = ThemeModeController(
      _NeverAnsweringStore(),
      readTimeout: const Duration(milliseconds: 50),
    );

    await controller.load();

    expect(controller.mode, ThemeMode.system);
  });

  test('setMode đổi giao diện ngay và lưu lại lựa chọn', () async {
    final _FakeThemeModeStore store = _FakeThemeModeStore();
    final ThemeModeController controller = ThemeModeController(store);
    int notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setMode(ThemeMode.light);

    expect(controller.mode, ThemeMode.light);
    expect(notifications, 1);
    expect(store.writes, [ThemeMode.light]);
  });

  test('setMode với giá trị hiện tại không ghi lại và không thông báo', () async {
    final _FakeThemeModeStore store = _FakeThemeModeStore();
    final ThemeModeController controller = ThemeModeController(store);
    int notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setMode(ThemeMode.system);

    expect(notifications, 0);
    expect(store.writes, isEmpty);
  });

  test('ghi bộ nhớ lỗi vẫn đổi giao diện trong phiên hiện tại', () async {
    final ThemeModeController controller = ThemeModeController(_FakeThemeModeStore(failOnWrite: true));

    await controller.setMode(ThemeMode.dark);

    expect(controller.mode, ThemeMode.dark);
  });
}
