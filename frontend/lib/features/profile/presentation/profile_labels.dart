import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/profile_validation.dart';
import 'package:fluw/features/profile/domain/sex.dart';
import 'package:fluw/features/profile/domain/training_type.dart';
import 'package:fluw/features/profile/domain/weight_goal.dart';

String sexLabel(Sex sex) => switch (sex) {
  Sex.male => 'Nam',
  Sex.female => 'Nữ',
  Sex.other => 'Khác',
};

String bmrFormulaLabel(BmrFormula formula) => switch (formula) {
  BmrFormula.male => 'Theo công thức Nam',
  BmrFormula.female => 'Theo công thức Nữ',
};

String activityLevelLabel(ActivityLevel level) => switch (level) {
  ActivityLevel.sedentary => 'Ít vận động',
  ActivityLevel.light => 'Hoạt động nhẹ',
  ActivityLevel.moderate => 'Hoạt động vừa',
  ActivityLevel.active => 'Hoạt động nhiều',
  ActivityLevel.veryActive => 'Hoạt động rất cao',
};

String activityLevelDescription(ActivityLevel level) => switch (level) {
  ActivityLevel.sedentary => 'Ngồi nhiều, hầu như không tập',
  ActivityLevel.light => 'Tập nhẹ 1–3 buổi mỗi tuần',
  ActivityLevel.moderate => 'Tập 3–5 buổi mỗi tuần',
  ActivityLevel.active => 'Tập 6–7 buổi mỗi tuần',
  ActivityLevel.veryActive => 'Lao động nặng hoặc tập 2 lần mỗi ngày',
};

String trainingTypeLabel(TrainingType type) => switch (type) {
  TrainingType.none => 'Không tập thường xuyên',
  TrainingType.endurance => 'Nhẹ / sức bền',
  TrainingType.strength => 'Gym / tăng cơ',
};

String trainingTypeDescription(TrainingType type) => switch (type) {
  TrainingType.none => 'Đi lại, việc nhà',
  TrainingType.endurance => 'Chạy bộ, đạp xe, yoga',
  TrainingType.strength => 'Tập tạ, tăng cơ',
};

String healthConditionLabel(HealthCondition condition) => switch (condition) {
  HealthCondition.diabetes => 'Tiểu đường',
  HealthCondition.hypertension => 'Huyết áp cao',
  HealthCondition.dyslipidemia => 'Mỡ máu cao',
  HealthCondition.stomach => 'Bệnh dạ dày',
  HealthCondition.lowBloodPressure => 'Huyết áp thấp',
  HealthCondition.gout => 'Gout',
};

/// Says only what Fluw really does with each condition; the note-only ones have no data to warn about.
String healthConditionDescription(HealthCondition condition) => switch (condition) {
  HealthCondition.diabetes => 'Giới hạn đường tổng dưới 5% năng lượng mỗi ngày (tính từ 18 tuổi).',
  HealthCondition.hypertension => 'Lưu để cảnh báo món nhiều natri khi tra cứu và ghi Nhật ký (đang xây dựng).',
  HealthCondition.dyslipidemia => 'Giới hạn béo bão hòa dưới 7% năng lượng mỗi ngày (tính từ 18 tuổi).',
  HealthCondition.stomach ||
  HealthCondition.lowBloodPressure ||
  HealthCondition.gout => 'Chỉ lưu làm ghi chú. Fluw chưa có dữ liệu để cảnh báo bệnh này.',
};

String bmiCategoryLabel(BmiCategory category) => switch (category) {
  BmiCategory.underweight => 'Thiếu cân',
  BmiCategory.normal => 'Bình thường',
  BmiCategory.overweight => 'Thừa cân',
  BmiCategory.obese => 'Béo phì',
};

String weightGoalLabel(WeightGoal goal) => switch (goal) {
  WeightGoal.lose => 'Giảm cân',
  WeightGoal.maintain => 'Giữ cân',
  WeightGoal.gain => 'Tăng cân',
};

String profileIssueMessage(ProfileIssue issue) => switch (issue) {
  ProfileIssue.birthDateInFuture => 'Ngày sinh không được ở tương lai.',
  ProfileIssue.birthDateTooOld => 'Fluw chỉ tính cho người tối đa $maximumAgeYears tuổi.',
  ProfileIssue.bmrFormulaMissing => 'Chọn công thức để tính năng lượng cơ bản (BMR).',
  ProfileIssue.heightOutOfRange => 'Chiều cao từ ${minHeightCm.round()} đến ${maxHeightCm.round()} cm.',
  ProfileIssue.weightOutOfRange => 'Cân nặng từ ${minWeightKg.round()} đến ${maxWeightKg.round()} kg.',
  ProfileIssue.targetWeightOutOfRange => 'Cân nặng mong muốn từ ${minWeightKg.round()} đến ${maxWeightKg.round()} kg.',
  ProfileIssue.weeklyChangeMissing => 'Chọn tốc độ thay đổi cân nặng mỗi tuần.',
  ProfileIssue.weeklyChangeOutOfRange =>
    'Tốc độ thay đổi cân nặng phải lớn hơn 0 và không quá $maxWeeklyChangeKg kg mỗi tuần.',
};
