import 'package:fluw/core/format/decimal_text.dart';
import 'package:fluw/core/nutrition/fluw_thresholds.dart';
import 'package:fluw/features/profile/domain/activity_level.dart';
import 'package:fluw/features/profile/domain/age.dart';
import 'package:fluw/features/profile/domain/allergen.dart';
import 'package:fluw/features/profile/domain/bmi.dart';
import 'package:fluw/features/profile/domain/bmr_formula.dart';
import 'package:fluw/features/profile/domain/calorie_target.dart';
import 'package:fluw/features/profile/domain/diet_style.dart';
import 'package:fluw/features/profile/domain/food_preference.dart';
import 'package:fluw/features/profile/domain/health_condition.dart';
import 'package:fluw/features/profile/domain/nutrient_targets.dart';
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
  ActivityLevel.sedentary => 'Làm việc ngồi, ít đi lại, hầu như không tập',
  ActivityLevel.light => 'Đi lại vừa phải hoặc tập nhẹ 1–3 buổi mỗi tuần',
  ActivityLevel.moderate => 'Đi lại nhiều hoặc tập 3–5 buổi mỗi tuần',
  ActivityLevel.active => 'Đứng, đi lại gần cả ngày hoặc tập 6–7 buổi mỗi tuần',
  ActivityLevel.veryActive => 'Lao động chân tay nặng hoặc tập 2 lần mỗi ngày',
};

String trainingTypeLabel(TrainingType type) => switch (type) {
  TrainingType.none => 'Không tập thường xuyên',
  TrainingType.endurance => 'Nhẹ / sức bền',
  TrainingType.strength => 'Gym / tăng cơ',
};

String trainingTypeDescription(TrainingType type) => switch (type) {
  TrainingType.none => 'Đi lại, việc nhà',
  TrainingType.endurance => 'Chạy bộ, đạp xe, bơi',
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
  HealthCondition.diabetes =>
    'Theo dõi đường tổng: Fluw dùng mức gợi ý dưới 5% năng lượng mỗi ngày (dựa trên khuyến nghị đường tự do của WHO '
        '2015). Đây không phải chế độ ăn điều trị: lượng carb (bột đường) phù hợp cho người tiểu đường do bác sĩ chỉ '
        'định.',
  HealthCondition.hypertension =>
    'Theo dõi natri: tối đa ${formatWhole(dailySodiumMaxMg)} mg mỗi ngày (khoảng 5 g muối, khuyến nghị của WHO cho '
        'mọi người lớn). Với huyết áp cao, Trang Chủ luôn nhắc hạn chế muối và chi tiết sản phẩm cảnh báo khi một khẩu '
        'phần chiếm từ ${formatWhole(watchedPortionShare * 100)}% mức này. Không thay thế hướng dẫn của bác sĩ.',
  HealthCondition.dyslipidemia =>
    'Giới hạn béo bão hòa dưới 7% năng lượng mỗi ngày (mức tham khảo). Không thay thế hướng dẫn của bác sĩ.',
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
  ProfileIssue.pregnancyAnswerMissing => 'Cho biết bạn có đang mang thai hoặc cho con bú không.',
  ProfileIssue.heightOutOfRange => 'Chiều cao từ ${minHeightCm.round()} đến ${maxHeightCm.round()} cm.',
  ProfileIssue.weightOutOfRange => 'Cân nặng từ ${minWeightKg.round()} đến ${maxWeightKg.round()} kg.',
  ProfileIssue.targetWeightOutOfRange => 'Cân nặng mong muốn từ ${minWeightKg.round()} đến ${maxWeightKg.round()} kg.',
  ProfileIssue.targetBmiTooLow =>
    'Cân nặng mong muốn cho BMI dưới 18.5 (thiếu cân theo thang châu Á). Fluw không tính chỉ tiêu giảm cân tới mức '
        'này. Hãy hỏi bác sĩ.',
  ProfileIssue.loseWhenUnderweight =>
    'Bạn đang thiếu cân (BMI dưới 18.5 theo thang châu Á). Fluw không tính chỉ tiêu giảm cân khi đang thiếu cân. '
        'Hãy hỏi bác sĩ.',
  ProfileIssue.weeklyChangeMissing => 'Chọn tốc độ thay đổi cân nặng mỗi tuần.',
  ProfileIssue.weeklyChangeOutOfRange =>
    'Tốc độ thay đổi cân nặng phải lớn hơn 0 và không quá $maxWeeklyChangeKg kg mỗi tuần.',
};

String allergenLabel(Allergen allergen) => switch (allergen) {
  Allergen.gluten => 'Gluten (lúa mì, lúa mạch)',
  Allergen.crustaceans => 'Tôm, cua (giáp xác)',
  Allergen.eggs => 'Trứng',
  Allergen.fish => 'Cá',
  Allergen.peanuts => 'Đậu phộng (lạc)',
  Allergen.soybeans => 'Đậu nành',
  Allergen.milk => 'Sữa',
  Allergen.treeNuts => 'Hạt cây (hạnh nhân, óc chó, điều...)',
  Allergen.celery => 'Cần tây',
  Allergen.mustard => 'Mù tạt',
  Allergen.sesame => 'Mè (vừng)',
  Allergen.sulphites => 'Sulfit',
  Allergen.lupin => 'Đậu lupin',
  Allergen.molluscs => 'Nhuyễn thể (mực, nghêu, sò...)',
};

String allergySeverityLabel(AllergySeverity severity) => switch (severity) {
  AllergySeverity.severe => 'Nặng',
  AllergySeverity.mild => 'Nhẹ',
};

String dietStyleLabel(DietStyle style) => switch (style) {
  DietStyle.regular => 'Ăn bình thường',
  DietStyle.eatClean => 'Eat Clean',
  DietStyle.keto => 'Keto',
  DietStyle.vegan => 'Thuần chay (Vegan)',
  DietStyle.mediterranean => 'Địa Trung Hải',
};

String foodPreferenceLabel(FoodPreference preference) => switch (preference) {
  FoodPreference.noOrganMeat => 'Không ăn nội tạng động vật',
  FoodPreference.steamedOrBoiled => 'Ưu tiên đồ hấp, luộc, áp chảo ít dầu',
  FoodPreference.likesNuts => 'Thích hạt dinh dưỡng (óc chó, hạnh nhân)',
};
