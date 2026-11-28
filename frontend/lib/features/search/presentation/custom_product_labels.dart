import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/portion_limits.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/custom_product_draft.dart';

String customProductIssueText(CustomProductIssue issue, QuantityUnit unit) => switch (issue) {
  CustomProductIssue.required => 'Cần nhập ô này.',
  CustomProductIssue.tooLong => 'Tối đa $maxProductNameLength ký tự.',
  CustomProductIssue.barcodeLength => 'Mã vạch có 8, 12, 13 hoặc 14 chữ số.',
  CustomProductIssue.barcodeCheckDigit => 'Mã vạch sai một chữ số, hãy kiểm lại.',
  CustomProductIssue.invalidNumber => 'Nhập một số, ví dụ 12,5.',
  CustomProductIssue.portionOutOfRange =>
    'Trong khoảng ${minPortion.round()}–${maxPortion.round()} ${unit.symbol}. Gói lớn hơn thì để trống.',
  CustomProductIssue.tooHighPer100 => 'Số này quá lớn so với 100 ${unit.symbol}. Kiểm lại số hoặc khẩu phần.',
  CustomProductIssue.sugarsAboveCarbohydrates => 'Đường không thể nhiều hơn carb.',
  CustomProductIssue.saturatedFatAboveFat => 'Béo bão hòa không thể nhiều hơn chất béo.',
};

/// Help under a nutrient field for labels that print another unit.
String? nutrientFieldHelper(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 'Nhãn chỉ ghi kJ: chia cho 4,184.',
  Nutrient.sodiumMg => 'Nhãn ghi muối (g): natri ≈ muối × 400 mg.',
  _ => null,
};
