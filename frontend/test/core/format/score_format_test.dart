import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/format/date_format.dart';
import 'package:frontend/core/format/score_format.dart';
import 'package:frontend/core/format/vietnamese_number.dart';
import 'package:frontend/models/score/additives_score.dart';
import 'package:frontend/models/score/score_indicator.dart';

import '../../helpers/product_fixtures.dart';

void main() {
  group('formatVietnameseNumber', () {
    test('dấu phẩy thập phân, dấu chấm hàng nghìn, bỏ số 0 thừa, dấu trừ', () {
      expect(formatVietnameseNumber(3.5), '3,5');
      expect(formatVietnameseNumber(1340), '1.340');
      expect(formatVietnameseNumber(30.6), '30,6');
      expect(formatVietnameseNumber(0.7, maxFractionDigits: 3), '0,7');
      expect(formatVietnameseNumber(-3), '−3');
      expect(formatVietnameseNumber(-0.001), '0');
      expect(
        formatVietnameseNumber(1234567.891, maxFractionDigits: 1),
        '1.234.567,9',
      );
    });
  });

  group('phép tính điểm tổng', () {
    test('in từ số backend gửi, có bước làm tròn khi cần', () {
      expect(
        ScoreFormat.calculation(productDetails('product-food-complete').score),
        '18 × 0,7 + 60 × 0,3 = 30,6 → 31',
      );
      expect(
        ScoreFormat.calculation(productDetails('product-water').score),
        '100 × 0,7 + 100 × 0,3 = 100',
      );
    });

    test('ví dụ trong đặc tả: 80 × 0,7 + 60 × 0,3 = 74', () {
      final score = productDetails(
        'product-food-complete',
        edit: (_, score) {
          (score['total'] as Map<String, dynamic>)
            ..['value'] = 74
            ..['calculation'] = {
              'nutritionWeighted': 56,
              'additivesWeighted': 18,
              'sum': 74,
            };
          (score['nutrition'] as Map<String, dynamic>)['value'] = 80;
        },
      ).score;
      expect(ScoreFormat.calculation(score), '80 × 0,7 + 60 × 0,3 = 74');
    });

    test('thiếu điểm tổng hoặc thành phần thì không có phép tính', () {
      expect(
        ScoreFormat.calculation(
          productDetails('product-needs-prepared-data').score,
        ),
        isNull,
      );
    });

    test('dòng điểm thành phần kèm trọng số', () {
      expect(
        ScoreFormat.component('Dinh dưỡng', '80/100', 0.7),
        'Dinh dưỡng 80/100 · trọng số 70%',
      );
      expect(
        ScoreFormat.component('Phụ gia', '60/100', null),
        'Phụ gia 60/100',
      );
    });
  });

  group('khoảng ngưỡng', () {
    test('biên đóng/mở và khoảng hở', () {
      expect(
        ScoreFormat.range(
          const IndicatorRange(
            min: 1675,
            minInclusive: false,
            max: 2010,
            maxInclusive: true,
          ),
          'kJ',
        ),
        '> 1.675 – ≤ 2.010 kJ',
      );
      expect(
        ScoreFormat.range(
          const IndicatorRange(max: 3, maxInclusive: true),
          'g',
        ),
        '≤ 3 g',
      );
      expect(
        ScoreFormat.range(
          const IndicatorRange(min: 10, minInclusive: false),
          'g',
        ),
        '> 10 g',
      );
      expect(
        ScoreFormat.range(
          const IndicatorRange(
            min: 10,
            minInclusive: true,
            max: 16,
            maxInclusive: false,
          ),
          '%',
        ),
        '≥ 10 – < 16%',
      );
      expect(ScoreFormat.range(null, 'g'), isNull);
    });

    test('giá trị chỉ số theo đơn vị', () {
      expect(ScoreFormat.indicatorValue(2000, 'kJ'), '2.000 kJ');
      expect(ScoreFormat.indicatorValue(0.01, 'g'), '0,01 g');
      expect(ScoreFormat.indicatorValue(40, '%'), '40%');
      expect(ScoreFormat.indicatorValue(1, 'count'), '1 chất');
    });
  });

  group('dải', () {
    test('dải điểm thô và dải điểm, kể cả số âm và dải mở', () {
      expect(ScoreFormat.pointsInterval(19, 55), '19 … 55');
      expect(ScoreFormat.pointsInterval(-17, 0), '−17 … 0');
      expect(ScoreFormat.scoreInterval(0, 19), '0–19');
      expect(
        ScoreFormat.additivesInterval(
          const AdditivesBand(countMin: 3, countMax: 4),
        ),
        '3–4 phụ gia',
      );
      expect(
        ScoreFormat.additivesInterval(
          const AdditivesBand(countMin: 0, countMax: 0),
        ),
        '0 phụ gia',
      );
      expect(
        ScoreFormat.additivesInterval(const AdditivesBand(countMin: 10)),
        'từ 10 phụ gia trở lên',
      );
    });
  });

  test('ngày theo kiểu Việt Nam', () {
    expect(formatVietnameseDate(DateTime(2025, 10, 30)), '30/10/2025');
  });
}
