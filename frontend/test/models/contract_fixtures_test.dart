import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/api/api_error_kind.dart';
import 'package:frontend/data/api/fluw_api_client.dart';
import 'package:frontend/data/api/fluw_api_exception.dart';
import 'package:frontend/models/analysis/product_analysis.dart';
import 'package:frontend/models/product/product_details.dart';
import 'package:frontend/models/product/product_nutrition.dart';
import 'package:frontend/models/score/additives_score.dart';
import 'package:frontend/models/score/nutrition_score.dart';
import 'package:frontend/models/score/score_indicator.dart';
import 'package:frontend/models/score_level.dart';
import 'package:frontend/models/search/search_results.dart';
import 'package:http/testing.dart';

import '../helpers/contract_fixtures.dart';

ProductDetails _product(String name) =>
    ProductDetails.fromJson(ContractFixture.load(name).body);

void main() {
  group('mọi fixture contract đều đọc được', () {
    final List<ContractFixture> fixtures = ContractFixture.loadAll();

    test('thư mục fixture có đủ các nhóm', () {
      final Set<String> prefixes = fixtures
          .map((fixture) => fixture.name.split('-').first)
          .toSet();
      expect(prefixes, containsAll(['search', 'product', 'analysis', 'error']));
    });

    for (final ContractFixture fixture in fixtures) {
      test(fixture.name, () async {
        final String prefix = fixture.name.split('-').first;
        switch (prefix) {
          case 'search':
            final SearchResults results = SearchResults.fromJson(fixture.body);
            expect(
              results.items.length,
              (fixture.body['results'] as List).length,
            );
          case 'product':
            final ProductDetails details = ProductDetails.fromJson(
              fixture.body,
            );
            expect(details.product.barcode, isNotEmpty);
            expect(details.score.version, 'fluw-score-1.0');
          case 'analysis':
            final ProductAnalysis analysis = ProductAnalysis.fromJson(
              fixture.body,
            );
            expect(
              (analysis.explanation == null) != (analysis.aiError == null),
              isTrue,
            );
          case 'error':
            final FluwApiClient client = FluwApiClient(
              httpClient: MockClient((_) async => fixture.toResponse()),
            );
            final Uri path = fixture.requestUri;
            final Future<Object> call = path.pathSegments.contains('search')
                ? client.search(path.queryParameters['q'] ?? '')
                : client.product(path.pathSegments.last);
            await expectLater(
              call,
              throwsA(
                isA<FluwApiException>()
                    .having((e) => e.code, 'code', fixture.body['code'])
                    .having(
                      (e) => e.kind,
                      'kind',
                      ApiErrorKind.fromCode(fixture.body['code'] as String),
                    )
                    .having((e) => e.message, 'message', fixture.body['error'])
                    .having((e) => e.statusCode, 'statusCode', fixture.status),
              ),
            );
          default:
            fail('Fixture mới "${fixture.name}" chưa có test đọc trong app');
        }
      });
    }
  });

  group('tìm kiếm', () {
    test(
      'kết quả khớp đủ: đọc mọi trường, giữ null, không đánh dấu gần đúng',
      () {
        final SearchResults results = SearchResults.fromJson(
          ContractFixture.load('search-results').body,
        );

        expect(results.query, 'Hảo hảo');
        expect(results.total, 8);
        expect(results.isApproximate, isFalse);
        final SearchResultItem first = results.items.first;
        expect(first.barcode, '8934563122201');
        expect(first.name, 'Mỳ Hảo Hảo');
        expect(first.brand, 'Acecook');
        expect(first.quantity, isNull);
        expect(first.imageUrl, isNull);
        expect(results.items[3].quantity, '74g');
        expect(
          results.items[3].imageUrl,
          startsWith('https://images.openfoodfacts.org/'),
        );
        expect(
          results.items.last.barcode,
          '0626594000112',
          reason: 'giữ số 0 ở đầu mã vạch',
        );
      },
    );

    test('kết quả gần đúng và kết quả rỗng', () {
      expect(
        SearchResults.fromJson(
          ContractFixture.load('search-partial-results').body,
        ).isApproximate,
        isTrue,
      );
      final SearchResults empty = SearchResults.fromJson(
        ContractFixture.load('search-empty').body,
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.isApproximate, isFalse);
    });

    test(
      'bỏ mục không có mã vạch và ảnh không thuộc máy chủ ảnh Open Food Facts',
      () {
        final SearchResults results = SearchResults.fromJson({
          'success': true,
          'results': [
            {'name': 'Không có mã'},
            {
              'barcode': '8934563122201',
              'imageUrl': 'https://example.com/a.jpg',
            },
          ],
        });
        expect(results.items.single.barcode, '8934563122201');
        expect(results.items.single.imageUrl, isNull);
        expect(results.total, 1);
      },
    );

    test('thiếu danh sách kết quả là dữ liệu sai', () {
      expect(
        () => SearchResults.fromJson({'success': true}),
        throwsFormatException,
      );
    });
  });

  group('sản phẩm đủ dữ liệu (bánh quy)', () {
    final ProductDetails details = _product('product-food-complete');

    test('thông tin sản phẩm', () {
      final product = details.product;
      expect(product.barcode, '8930000000019');
      expect(product.name, 'Bánh quy bơ (dữ liệu thử)');
      expect(product.genericName, 'Bánh quy');
      expect(product.quantity, '120 g');
      expect(product.brandOwner, 'Công ty Thử nghiệm Fluw');
      expect(product.manufacturingPlaces, 'Việt Nam');
      expect(product.images.front?.small, endsWith('front_vi.5.200.jpg'));
      expect(product.images.front?.full, endsWith('front_vi.5.full.jpg'));
      expect(product.images.nutrition, isNull);
      expect(product.ingredientsText, startsWith('Bột mì'));
      expect(product.allergens.map((tag) => tag.label), [
        'gluten',
        'sữa',
        'đậu nành',
      ]);
      expect(product.traces.single.label, 'trứng');
      expect(product.additives.map((additive) => additive.code), [
        'E322i',
        'E471',
        'E500',
        'E503',
      ]);
      expect(product.additives[1].name, 'Mono- và diglycerid của axit béo');
      expect(product.novaGroup, 4);
      expect(product.nutrition.basis, NutritionBasis.per100g);
      expect(product.nutrition.per100?.energyKj, 2000);
      expect(product.nutrition.per100?.salt, 0.5);
      expect(product.nutrition.preparedPer100, isNull);
      expect(product.source.license, 'ODbL');
      expect(product.source.imagesLicense, 'CC BY-SA');
      expect(
        product.source.url,
        'https://world.openfoodfacts.org/product/8930000000019',
      );
      expect(
        product.source.lastModified,
        DateTime.utc(2025, 10, 30, 4, 53, 20),
      );
    });

    test('điểm: tổng, trọng số, phép tính và mức do backend gửi', () {
      final score = details.score;
      expect(score.nutritionWeight, 0.7);
      expect(score.additivesWeight, 0.3);
      expect(score.total.value, 31);
      expect(score.total.level, ScoreLevel.limit);
      expect(score.total.label, 'Nên hạn chế');
      expect(score.total.calculation?.sum, 30.6);
      expect(score.total.calculation?.nutritionWeighted, 12.6);
      expect(score.disclaimer, contains('không phải chẩn đoán'));
    });

    test('điểm dinh dưỡng: dải, chỉ số, khoảng ngưỡng mở và trạng thái', () {
      final nutrition = details.score.nutrition;
      expect(nutrition.status, NutritionStatus.computed);
      expect(nutrition.productTypeLabel, 'Thực phẩm');
      expect(nutrition.basis, NutritionScoreBasis.asSold);
      expect(nutrition.points, 21);
      expect(nutrition.band?.pointsMin, 19);
      expect(nutrition.band?.scoreMax, 19);
      expect(nutrition.indicators, hasLength(7));

      final energy = nutrition.indicators.first;
      expect(energy.effect, IndicatorEffect.negative);
      expect(energy.range?.min, 1675);
      expect(energy.range?.minInclusive, isFalse);
      expect(energy.range?.maxInclusive, isTrue);

      final proteins = nutrition.indicators.firstWhere(
        (indicator) => indicator.key == 'proteins',
      );
      expect(proteins.status, IndicatorStatus.excludedByRule);
      expect(proteins.note, contains('Nutri-Score'));

      final fiber = nutrition.indicators.firstWhere(
        (indicator) => indicator.key == 'fiber',
      );
      expect(fiber.range?.min, isNull);
      expect(fiber.range?.max, 3);

      expect(nutrition.indicators.last.status, IndicatorStatus.estimated);
      expect(nutrition.indicators.last.per, isNull);
    });

    test('điểm phụ gia', () {
      final additives = details.score.additives;
      expect(additives.value, 60);
      expect(additives.status, AdditivesStatus.computed);
      expect(additives.count, 4);
      expect(additives.band?.countMin, 3);
      expect(additives.band?.countMax, 4);
    });
  });

  group('các trạng thái thiếu dữ liệu', () {
    test('cần số liệu sau khi pha: không có điểm tổng, vẫn có điểm phụ gia, dải mở', () {
      final score = _product('product-needs-prepared-data').score;
      expect(score.total.isAvailable, isFalse);
      expect(score.total.level, isNull);
      expect(score.total.label, isNull);
      expect(score.total.calculation, isNull);
      expect(score.nutrition.status, NutritionStatus.needsPreparedData);
      expect(score.nutrition.indicators, isEmpty);
      expect(score.additives.value, 0);
      expect(score.additives.band?.countMax, isNull);
      expect(
        score.missing.single.label,
        'Dinh dưỡng của sản phẩm sau khi pha chế',
      );
    });

    test('thiếu danh mục và thành phần', () {
      final details = _product('product-missing-category');
      expect(details.product.ingredientsText, isNull);
      expect(details.product.novaGroup, isNull);
      expect(details.product.nutrition.per100?.saturatedFat, isNull);
      expect(details.product.nutrition.per100?.energyKj, 1715.4);
      expect(details.score.nutrition.status, NutritionStatus.missingData);
      expect(details.score.nutrition.productType, isNull);
      expect(
        details.score.additives.status,
        AdditivesStatus.missingIngredients,
      );
      expect(details.score.additives.value, isNull);
      expect(details.score.missing.map((item) => item.key), [
        'nutrition.productType',
        'additives.ingredients',
      ]);
    });

    test('không áp dụng (bia), thiếu chất xơ, thành phần chưa nhận diện', () {
      expect(
        _product('product-not-applicable').score.nutrition.status,
        NutritionStatus.notApplicable,
      );
      expect(_product('product-not-applicable').score.missing, isEmpty);
      expect(
        _product('product-missing-fiber').score.missing.single.label,
        'Chất xơ',
      );
      final unrecognized = _product('product-ingredients-not-recognized').score;
      expect(
        unrecognized.additives.status,
        AdditivesStatus.ingredientsNotRecognized,
      );
      expect(unrecognized.nutrition.value, 20);
    });

    test(
      'nước: điểm dinh dưỡng 100, không có dải và chỉ số, dinh dưỡng toàn null',
      () {
        final details = _product('product-water');
        expect(details.score.nutrition.productType, 'water');
        expect(details.score.nutrition.value, 100);
        expect(details.score.nutrition.band, isNull);
        expect(details.score.total.level, ScoreLevel.good);
        expect(details.product.nutrition.basis, NutritionBasis.per100ml);
        expect(details.product.nutrition.per100?.energyKcal, isNull);
        expect(details.product.images.front, isNull);
      },
    );

    test('đồ uống có chỉ số chất tạo ngọt không có khoảng ngưỡng', () {
      final indicators = _product('product-beverage')
          .score
          .nutrition
          .indicators;
      final sweeteners = indicators.firstWhere(
        (indicator) => indicator.key == 'nonNutritiveSweeteners',
      );
      expect(sweeteners.unit, 'count');
      expect(sweeteners.range, isNull);
    });
  });

  group('Zero giải thích', () {
    test('có nội dung: không có trường điểm, đủ các phần', () {
      final analysis = ProductAnalysis.fromJson(
        ContractFixture.load('analysis-ok').body,
      );
      expect(analysis.aiError, isNull);
      expect(analysis.scoreVersion, 'fluw-score-1.0');
      expect(analysis.explanation?.summary, contains('31/100'));
      expect(analysis.explanation?.highlights, hasLength(5));
      expect(analysis.explanation?.recommendation, isNotNull);
      expect(analysis.explanation?.alternatives, hasLength(3));
      expect(analysis.disclaimer, contains('AI không chấm điểm'));
    });

    test('mã lỗi AI', () {
      expect(
        ProductAnalysis.fromJson(
          ContractFixture.load('analysis-ai-unavailable').body,
        ).aiError,
        AiErrorCode.unavailable,
      );
      expect(
        ProductAnalysis.fromJson(
          ContractFixture.load('analysis-ai-daily-limit').body,
        ).aiError,
        AiErrorCode.dailyLimit,
      );
      expect(
        ProductAnalysis.fromJson({'aiAnalysis': null, 'aiError': 'AI_NEW_CODE'})
            .aiError,
        AiErrorCode.unknown,
      );
    });

    test('giới hạn 5 ý chính và 3 nhóm thay thế; câu trả lời rỗng coi như sai định dạng', () {
      final analysis = ProductAnalysis.fromJson({
        'aiAnalysis': {
          'summary': 'Tóm tắt',
          'highlights': ['1', '2', '3', '4', '5', '6'],
          'alternatives': ['a', 'b', 'c', 'd'],
        },
      });
      expect(analysis.explanation?.highlights, hasLength(5));
      expect(analysis.explanation?.alternatives, hasLength(3));
      expect(
        ProductAnalysis.fromJson({
          'aiAnalysis': {'summary': ' '},
        }).aiError,
        AiErrorCode.invalidResponse,
      );
    });
  });

  group('đọc an toàn trường sai kiểu', () {
    test('sản phẩm chỉ có mã vạch vẫn đọc được, mọi trường khác rỗng', () {
      final details = ProductDetails.fromJson({
        'product': {
          'barcode': '8930000000019',
          'name': 42,
          'allergens': 'sai',
          'novaGroup': 9,
          'images': [],
        },
        'score': {
          'total': {'value': '74', 'level': 'excellent'},
        },
      });
      expect(details.product.name, isNull);
      expect(details.product.allergens, isEmpty);
      expect(details.product.novaGroup, isNull);
      expect(details.product.images.front, isNull);
      expect(details.product.nutrition.per100, isNull);
      expect(details.score.total.value, isNull);
      expect(details.score.total.level, isNull);
      expect(details.score.nutrition.indicators, isEmpty);
    });

    test('ảnh ngoài máy chủ ảnh Open Food Facts bị bỏ', () {
      final details = ProductDetails.fromJson({
        'product': {
          'barcode': '8930000000019',
          'images': {
            'front': {
              'small': 'http://images.openfoodfacts.org/a.jpg',
              'full': 'https://evil.example/a.jpg',
            },
          },
          'source': {'url': 'javascript:alert(1)'},
        },
        'score': <String, dynamic>{},
      });
      expect(details.product.images.front, isNull);
      expect(details.product.source.url, isNull);
    });

    test('thiếu product, barcode hoặc score là dữ liệu sai', () {
      expect(
        () => ProductDetails.fromJson({'score': <String, dynamic>{}}),
        throwsFormatException,
      );
      expect(
        () => ProductDetails.fromJson({
          'product': <String, dynamic>{},
          'score': <String, dynamic>{},
        }),
        throwsFormatException,
      );
      expect(
        () => ProductDetails.fromJson({
          'product': {'barcode': '1'},
        }),
        throwsFormatException,
      );
    });
  });
}
