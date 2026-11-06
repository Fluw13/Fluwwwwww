import 'dart:convert';

import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String sampleBarcode = '8934563138165';
const Map<String, String> jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

http.Response jsonResponse(String body, int status) => http.Response(body, status, headers: jsonHeaders);

/// A successful `/api/product/:query` body as the backend sends it.
String productBody({Object? score = 82, String barcode = sampleBarcode, String name = 'Sữa chua'}) {
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
    'aiAnalysis': {
      'score': score,
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
