import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/models/score_level.dart';

Map<String, dynamic> _buildResponse({Object? score = 82}) {
  return {
    'success': true,
    'barcode': '8934563138164',
    'product': {
      'product_name': 'Sữa chua',
      'brands': 'Vinamilk',
      'image_front_url': 'https://example.com/image.jpg',
      'nutriments': {
        'energy-kcal': 95,
        'proteins': 3.5,
        'fat': 3,
        'carbohydrates': 12.4,
      },
    },
    'aiAnalysis': {
      'score': score,
      'deepThink': 'Giàu canxi, đường vừa phải.',
      'recommendation': 'Phù hợp dùng hằng ngày.',
      'allergens': ['sữa'],
      'alternatives': ['Sữa chua không đường'],
    },
  };
}

void main() {
  group('ProductModel.fromJson', () {
    test('đọc đủ dữ liệu từ phản hồi hợp lệ', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse());

      expect(product.name, 'Sữa chua');
      expect(product.score, 82);
      expect(product.level, ScoreLevel.good);
      expect(product.calories, 95);
      expect(product.protein, 3.5);
      expect(product.allergens, ['sữa']);
      expect(product.alternatives, ['Sữa chua không đường']);
    });

    test('giới hạn điểm trong khoảng 0-100', () {
      expect(ProductModel.fromJson(_buildResponse(score: 250)).score, 100);
      expect(ProductModel.fromJson(_buildResponse(score: -5)).score, 0);
    });

    test('ném FormatException khi thiếu điểm sức khỏe', () {
      expect(
        () => ProductModel.fromJson(_buildResponse(score: null)),
        throwsFormatException,
      );
    });

    test('dùng giá trị mặc định khi thiếu thông tin sản phẩm', () {
      final ProductModel product = ProductModel.fromJson({
        'aiAnalysis': {'score': 50},
      });

      expect(product.name, 'Sản phẩm chưa có tên');
      expect(product.calories, 0);
      expect(product.allergens, isEmpty);
    });
  });

  group('ScoreLevel.fromScore', () {
    test('phân loại đúng theo ngưỡng điểm', () {
      expect(ScoreLevel.fromScore(70), ScoreLevel.good);
      expect(ScoreLevel.fromScore(69), ScoreLevel.moderate);
      expect(ScoreLevel.fromScore(40), ScoreLevel.moderate);
      expect(ScoreLevel.fromScore(39), ScoreLevel.poor);
    });
  });
}
