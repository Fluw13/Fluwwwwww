import 'dart:convert';

import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String sampleBarcode = '8934563138165';
const Map<String, String> jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

http.Response jsonResponse(String body, int status) => http.Response(body, status, headers: jsonHeaders);

/// The `fns` object as the backend FNS engine sends it; `score: null` is a NOT_SCORED result.
Map<String, Object?> fnsJson({double? score = 6.7}) {
  if (score == null) {
    return {
      'scoring_system': 'FLUW_NUTRITION_SCORE',
      'status': 'NOT_SCORED',
      'score': null,
      'category': 'C2D',
      'missing_fields': ['sodium_mg'],
      'reason_codes': ['BASELINE_NUTRIENT_MISSING'],
      'limitations': <String>[],
    };
  }
  return {
    'scoring_system': 'FLUW_NUTRITION_SCORE',
    'scoring_version': '1.0.0',
    'status': 'PROVISIONAL',
    'score': score,
    'category': 'C2D',
    'basis': 'per_100g',
    'raw_score': 3,
    'baseline_components': ['energy', 'saturated_fat', 'total_sugars', 'sodium'],
    'component_points': {
      'energy': 1,
      'saturated_fat': 2,
      'total_sugars': 1,
      'sodium': 1,
      'fvnl': 0,
      'protein': 2,
      'fiber': 0,
    },
    'modifier_eligibility': {'fvnl': true, 'protein': true, 'fiber': true},
    'missing_fields': <String>[],
    'reason_codes': <String>[],
    'limitations': ['RULES_NEEDS_REVIEW', 'SOURCE_UNVERIFIED', 'FVNL_ESTIMATED'],
  };
}

/// A successful `/api/product/:query` body as the backend sends it.
String productBody({double? score = 6.7, String barcode = sampleBarcode, String name = 'Sữa chua'}) {
  return jsonEncode({
    'success': true,
    'barcode': barcode,
    'product': {
      'product_name': name,
      'brands': 'Thương hiệu mẫu',
      'image_front_url': '',
      'allergens': ['sữa'],
      'nutriments': {'energy-kcal': 95, 'proteins': 3.5, 'fat': 3, 'carbohydrates': 12.4},
    },
    'fns': fnsJson(score: score),
    'aiAnalysis': {
      'deepThink': 'Giàu canxi.',
      'recommendation': 'Dùng vừa phải.',
      'allergens': <String>[],
      'alternatives': <String>[],
    },
  });
}

/// An ApiService whose every request is answered with [productBody] and
/// recorded in [requests], so tests can see which service a screen used.
class RecordingApi {
  RecordingApi({String Function(Uri url)? body}) : _body = body ?? ((_) => productBody());

  final String Function(Uri url) _body;
  final List<Uri> requests = [];

  late final ApiService service = ApiService(
    client: MockClient((request) async {
      requests.add(request.url);
      return jsonResponse(_body(request.url), 200);
    }),
  );

  Iterable<Uri> get productRequests => requests.where((url) => url.path != '/health');
}
