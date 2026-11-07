import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/fns_result.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/models/score_level.dart';

import 'helpers/api_fixtures.dart';

Map<String, dynamic> _buildResponse({double? score = 7.8}) {
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
        'sugars': 8,
        'saturated-fat': 2.1,
        'sodium': 0.1,
      },
    },
    'fns': fnsJson(score: score),
    'aiAnalysis': {
      'deepThink': 'Giàu canxi, đường vừa phải.',
      'recommendation': 'Phù hợp dùng hằng ngày.',
      'allergens': ['Sữa', 'đậu nành'],
      'alternatives': ['Sữa chua không đường'],
    },
  };
}

void main() {
  group('ProductModel.fromJson', () {
    test('đọc đủ dữ liệu sản phẩm, điểm FNS và phân tích AI', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse());

      expect(product.name, 'Sữa chua');
      expect(product.score, 7.8);
      expect(product.level, ScoreLevel.good);
      expect(product.fns.status, FnsStatus.provisional);
      expect(product.fns.category, 'C2D');
      expect(product.calories, 95);
      expect(product.protein, 3.5);
      expect(product.sugars, 8);
      expect(product.saturatedFat, 2.1);
      expect(product.sodiumMg, 100);
      expect(product.declaredAllergens, ['sữa']);
      expect(product.suggestedAllergens, ['đậu nành']);
      expect(product.hasAnalysis, isTrue);
    });

    test('sản phẩm chưa chấm điểm: score null, vẫn giữ dữ liệu và phân tích AI', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse(score: null));

      expect(product.score, isNull);
      expect(product.level, isNull);
      expect(product.fns.status, FnsStatus.notScored);
      expect(product.fns.missingFields, ['sodium_mg']);
      expect(product.hasAnalysis, isTrue);
      expect(product.calories, 95);
    });

    test('không có object fns (backend cũ) thì không hiện điểm, kể cả khi AI còn trả score', () {
      final Map<String, dynamic> response = _buildResponse()..remove('fns');
      (response['aiAnalysis'] as Map<String, dynamic>)['score'] = 82;

      final ProductModel product = ProductModel.fromJson(response);

      expect(product.score, isNull);
      expect(product.fns.reasonCodes, [FnsResult.unavailableReason]);
    });

    test('điểm ngoài 0-10 hoặc trạng thái lạ bị bỏ, không hiện con số sai', () {
      for (final Object? badScore in [12, -1, 'cao', null]) {
        final Map<String, dynamic> response = _buildResponse();
        (response['fns'] as Map<String, Object?>)['score'] = badScore;
        expect(ProductModel.fromJson(response).score, isNull, reason: '$badScore');
      }
      final Map<String, dynamic> response = _buildResponse();
      (response['fns'] as Map<String, Object?>)['status'] = 'GREAT';
      expect(ProductModel.fromJson(response).score, isNull);
    });

    test('đọc aiError khi backend trả aiAnalysis null, điểm FNS vẫn còn', () {
      final Map<String, dynamic> response = _buildResponse();
      response['aiAnalysis'] = null;
      response['aiError'] = 'AI_RATE_LIMITED';

      final ProductModel product = ProductModel.fromJson(response);

      expect(product.hasAnalysis, isFalse);
      expect(product.aiError, 'AI_RATE_LIMITED');
      expect(product.deepThink, isEmpty);
      expect(product.suggestedAllergens, isEmpty);
      expect(product.score, 7.8);
    });

    test('aiAnalysis null mà không có aiError thì dùng AI_UNAVAILABLE', () {
      final Map<String, dynamic> response = _buildResponse()..['aiAnalysis'] = null;
      expect(ProductModel.fromJson(response).aiError, 'AI_UNAVAILABLE');
    });

    test('aiError là null khi có phân tích AI', () {
      final ProductModel product = ProductModel.fromJson(_buildResponse());

      expect(product.hasAnalysis, isTrue);
      expect(product.aiError, isNull);
    });

    test('dùng giá trị mặc định khi thiếu thông tin sản phẩm', () {
      final ProductModel product = ProductModel.fromJson({
        'aiAnalysis': {'deepThink': 'a'},
      });

      expect(product.name, 'Sản phẩm chưa có tên');
      expect(product.calories, isNull);
      expect(product.score, isNull);
      expect(product.declaredAllergens, isEmpty);
      expect(product.suggestedAllergens, isEmpty);
    });

    test('giữ null khi backend báo thiếu dữ liệu dinh dưỡng, phân biệt với giá trị 0', () {
      final Map<String, dynamic> response = _buildResponse();
      (response['product'] as Map<String, dynamic>)['nutriments'] = {'energy-kcal': 0, 'proteins': null};

      final ProductModel product = ProductModel.fromJson(response);

      expect(product.calories, 0);
      expect(product.protein, isNull);
      expect(product.fat, isNull);
      expect(product.sodiumMg, isNull);
    });
  });

  group('FnsResult.fromJson', () {
    test('đọc điểm thành phần, điều kiện modifier và giới hạn', () {
      final FnsResult fns = FnsResult.fromJson(fnsJson());

      expect(fns.isScored, isTrue);
      expect(fns.rawScore, 3);
      expect(fns.baselineComponents, ['energy', 'saturated_fat', 'total_sugars', 'sodium']);
      expect(fns.componentPoints['protein'], 2);
      expect(fns.proteinEligible, isTrue);
      expect(fns.fiberEligible, isTrue);
      expect(fns.hasLimitation('FVNL_ESTIMATED'), isTrue);
    });

    test('không phải object -> không chấm', () {
      for (final Object? json in [null, 'x', 42, <Object>[]]) {
        expect(FnsResult.fromJson(json).isScored, isFalse);
      }
    });
  });

  group('ScoreLevel.fromScore', () {
    test('phân loại theo ngưỡng FNS 0-10', () {
      expect(ScoreLevel.fromScore(10), ScoreLevel.good);
      expect(ScoreLevel.fromScore(6.7), ScoreLevel.good);
      expect(ScoreLevel.fromScore(5.6), ScoreLevel.moderate);
      expect(ScoreLevel.fromScore(3.3), ScoreLevel.moderate);
      expect(ScoreLevel.fromScore(2.2), ScoreLevel.poor);
      expect(ScoreLevel.fromScore(0), ScoreLevel.poor);
    });
  });
}
