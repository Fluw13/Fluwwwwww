import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/goal_progress.dart';

void main() {
  test('tỉ lệ quãng đường đã đi, cả khi giảm và khi tăng cân', () {
    expect(goalProgress(startKg: 58.5, currentKg: 56.4, targetKg: 53), closeTo(21 / 55, 1e-9));
    expect(goalProgress(startKg: 60, currentKg: 61, targetKg: 64), 0.25);
  });

  test('đi ngược hướng là 0, vượt mục tiêu là 1', () {
    expect(goalProgress(startKg: 70, currentKg: 72, targetKg: 65), 0);
    expect(goalProgress(startKg: 70, currentKg: 64, targetKg: 65), 1);
  });

  test('không còn quãng nào phải đi (giữ cân) thì null, so theo 0,1 kg', () {
    expect(goalProgress(startKg: 70, currentKg: 70, targetKg: 70.04), isNull);
  });
}
