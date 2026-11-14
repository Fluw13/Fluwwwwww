import 'package:fluw/core/network/api_failure.dart';
import 'package:fluw/core/nutrition/nutrient.dart';
import 'package:fluw/core/nutrition/quantity_unit.dart';
import 'package:fluw/features/search/domain/food_source.dart';
import 'package:fluw/features/search/domain/quick_filter.dart';

String quickFilterLabel(QuickFilter filter) => switch (filter) {
  QuickFilter.lowSugar => 'Ít đường (<5 g)',
  QuickFilter.highProtein => 'Giàu protein (>20 g)',
  QuickFilter.under200Kcal => 'Dưới 200 kcal',
};

String foodSourceLabel(FoodSource source) => switch (source) {
  FoodSource.openFoodFacts => 'Open Food Facts',
  FoodSource.usda => 'USDA',
};

String quantityUnitLabel(QuantityUnit unit) => switch (unit) {
  QuantityUnit.gram => 'g',
  QuantityUnit.milliliter => 'ml',
};

String nutrientLabel(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 'Năng lượng',
  Nutrient.proteinG => 'Protein (đạm)',
  Nutrient.carbohydratesG => 'Tinh bột',
  Nutrient.sugarsG => 'Đường tổng',
  Nutrient.fatG => 'Chất béo',
  Nutrient.saturatedFatG => 'Béo bão hòa',
  Nutrient.sodiumMg => 'Natri',
};

String nutrientUnit(Nutrient nutrient) => switch (nutrient) {
  Nutrient.energyKcal => 'kcal',
  Nutrient.sodiumMg => 'mg',
  _ => 'g',
};

String apiFailureMessage(ApiFailure failure) => switch (failure) {
  NetworkFailure() => 'Không kết nối được máy chủ. Hãy kiểm tra mạng rồi thử lại.',
  TimeoutFailure() => 'Máy chủ phản hồi quá lâu. Hãy thử lại sau ít phút.',
  ServerFailure(:final message) => message,
  InvalidResponseFailure() => 'Máy chủ trả dữ liệu không đọc được. Hãy thử lại sau.',
};
