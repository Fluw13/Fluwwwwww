import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/goal_duration.dart';

void main() {
  test('làm tròn lên số tuần, cả khi giảm và khi tăng cân', () {
    expect(estimateWeeksToTarget(currentKg: 58.5, targetKg: 53, weeklyChangeKg: 0.5), 11);
    expect(estimateWeeksToTarget(currentKg: 58.5, targetKg: 53, weeklyChangeKg: 0.25), 22);
    expect(estimateWeeksToTarget(currentKg: 60, targetKg: 61.1, weeklyChangeKg: 0.5), 3);
  });

  test('chia hết thì không cộng thêm tuần vì sai số máy tính', () {
    expect(estimateWeeksToTarget(currentKg: 70, targetKg: 65, weeklyChangeKg: 0.5), 10);
    expect(estimateWeeksToTarget(currentKg: 70.3, targetKg: 70, weeklyChangeKg: 0.1), 3);
  });

  test('đã ở cân nặng mong muốn thì 0 tuần; tốc độ không dương thì báo lỗi', () {
    expect(estimateWeeksToTarget(currentKg: 70, targetKg: 70.04, weeklyChangeKg: 0.5), 0);
    expect(() => estimateWeeksToTarget(currentKg: 70, targetKg: 65, weeklyChangeKg: 0), throwsArgumentError);
    expect(() => estimateWeeksToTarget(currentKg: 70, targetKg: 65, weeklyChangeKg: double.nan), throwsArgumentError);
  });
}
