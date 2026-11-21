import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/profile/domain/protein_target.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

void main() {
  group('chọn nhóm protein', () {
    ProteinGroup select(TrainingType training, [WeightGoal goal = WeightGoal.maintain]) {
      return ProteinGroup.select(trainingType: training, goal: goal);
    }

    test('không tập thường xuyên là 0,8 g/kg', () {
      expect(select(TrainingType.none), ProteinGroup.adult);
      expect(select(TrainingType.none, WeightGoal.lose), ProteinGroup.adult);
    });

    test('vận động nhẹ / sức bền là 1,2–1,4 g/kg, mục tiêu nào cũng vậy', () {
      expect(select(TrainingType.endurance), ProteinGroup.endurance);
      expect(select(TrainingType.endurance, WeightGoal.lose), ProteinGroup.endurance);
    });

    test('gym là 1,6–2,2 g/kg; gym kèm giảm cân là 1,6–2,4 g/kg', () {
      expect(select(TrainingType.strength), ProteinGroup.strength);
      expect(select(TrainingType.strength, WeightGoal.gain), ProteinGroup.strength);
      expect(select(TrainingType.strength, WeightGoal.lose), ProteinGroup.cutting);
    });
  });

  group('lượng protein theo cân nặng', () {
    const gramsAt50Kg = {
      ProteinGroup.adult: (40.0, 40.0),
      ProteinGroup.endurance: (60.0, 70.0),
      ProteinGroup.strength: (80.0, 110.0),
      ProteinGroup.cutting: (80.0, 120.0),
    };

    for (final MapEntry(key: group, value: (min, max)) in gramsAt50Kg.entries) {
      test('50 kg nhóm ${group.name}: $min–$max g', () {
        final target = ProteinTarget(group: group, weightKg: 50);

        expect(target.minGrams, closeTo(min, 1e-9));
        expect(target.maxGrams, closeTo(max, 1e-9));
      });
    }

    test('70 kg tập gym: 112–154 g', () {
      const target = ProteinTarget(group: ProteinGroup.strength, weightKg: 70);

      expect(target.minGrams, closeTo(112, 1e-9));
      expect(target.maxGrams, closeTo(154, 1e-9));
    });

    test('đủ khi đạt cận dưới của khoảng', () {
      const target = ProteinTarget(group: ProteinGroup.strength, weightKg: 70);

      expect(target.isReachedBy(112), isTrue);
      expect(target.isReachedBy(111.9), isFalse);
    });

    test('sai số dấu phẩy động không làm mất mốc đủ (42,2 × 0,8 tính ra 33,760000000000005)', () {
      const target = ProteinTarget(group: ProteinGroup.adult, weightKg: 42.2);

      expect(target.isReachedBy(33.76), isTrue);
    });

    test('lượng đã nạp là NaN thì coi như chưa đủ, không crash', () {
      const target = ProteinTarget(group: ProteinGroup.adult, weightKg: 70);

      expect(target.isReachedBy(double.nan), isFalse);
    });
  });

  test('nhắc người bệnh thận khi khoảng protein vượt 1,2 g/kg', () {
    expect(ProteinGroup.adult.needsKidneyCaution, isFalse);
    expect(ProteinGroup.endurance.needsKidneyCaution, isTrue);
    expect(ProteinGroup.strength.needsKidneyCaution, isTrue);
    expect(ProteinGroup.cutting.needsKidneyCaution, isTrue);
  });
}
