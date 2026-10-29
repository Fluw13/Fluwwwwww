import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/models/score_level.dart';

Map<String, dynamic> _buildResponse({Object? score = 82}) {
  return {
    'success': true,
    'barcode': '8934563138165',
    'product': {
      'product_name': 'Sữa chua',
      'brands': 'Vinamilk',
      'image_front_url': 'https://example.com/image.jpg',
      'allergens': ['sữa'],
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
      'allergens': ['Sữa', 'đậu nành'],
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
      expect(product.declaredAllergens, ['sữa']);
      expect(product.suggestedAllergens, ['đậu nành']);
      expect(product.alternatives, ['Sữa chua không đường']);
    });

    test('giới hạn điểm trong khoảng 0-100', () {
      expect(ProductModel.fromJson(_buildResponse(score: 250)).score, 100);
      expect(ProductModel.fromJson(_buildResponse(score: -5)).score, 0);
    });

    test('bỏ qua phân tích AI khi thiếu điểm sức khỏe nhưng vẫn giữ dữ liệu sản phẩm', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse(score: null));

      expect(product.hasAnalysis, isFalse);
      expect(product.score, isNull);
      expect(product.level, isNull);
      expect(product.aiError, 'AI_UNAVAILABLE');
      expect(product.deepThink, isEmpty);
      expect(product.suggestedAllergens, isEmpty);
      expect(product.alternatives, isEmpty);
      expect(product.name, 'Sữa chua');
      expect(product.calories, 95);
      expect(product.declaredAllergens, ['sữa']);
    });

    test('đọc aiError khi backend trả aiAnalysis null', () {
      final Map<String, dynamic> response = _buildResponse();
      response['aiAnalysis'] = null;
      response['aiError'] = 'AI_NOT_CONFIGURED';

      final ProductModel product = ProductModel.fromJson(response);

      expect(product.hasAnalysis, isFalse);
      expect(product.aiError, 'AI_NOT_CONFIGURED');
      expect(product.name, 'Sữa chua');
    });

    test('aiError là null khi có phân tích AI hợp lệ', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse());

      expect(product.hasAnalysis, isTrue);
      expect(product.aiError, isNull);
    });

    test('dùng giá trị mặc định khi thiếu thông tin sản phẩm', () {
      final ProductModel product = ProductModel.fromJson({
        'aiAnalysis': {'score': 50},
      });

      expect(product.name, 'Sản phẩm chưa có tên');
      expect(product.calories, isNull);
      expect(product.declaredAllergens, isEmpty);
      expect(product.suggestedAllergens, isEmpty);
    });

    test('giữ null khi backend báo thiếu dữ liệu dinh dưỡng, phân biệt với giá trị 0', () {
      final Map<String, dynamic> response = _buildResponse();
      (response['product'] as Map<String, dynamic>)['nutriments'] = {
        'energy-kcal': 0,
        'proteins': null,
      };

      final ProductModel product = ProductModel.fromJson(response);

      expect(product.calories, 0);
      expect(product.protein, isNull);
      expect(product.fat, isNull);
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
