import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Real API v1 responses recorded by the backend (`contracts/fixtures`).
/// Tests run from `frontend/`, so the folder is one level up.
final Directory contractFixturesDirectory = Directory('../contracts/fixtures');

class ContractFixture {
  const ContractFixture({
    required this.name,
    required this.request,
    required this.status,
    required this.headers,
    required this.body,
  });

  factory ContractFixture.load(String name) {
    final File file = File('${contractFixturesDirectory.path}/$name.json');
    final Map<String, dynamic> json =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return ContractFixture(
      name: name,
      request: json['request'] as String,
      status: json['status'] as int,
      headers: (json['headers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as String),
      ),
      body: json['body'] as Map<String, dynamic>,
    );
  }

  static List<ContractFixture> loadAll() {
    final List<String> names =
        contractFixturesDirectory
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((fileName) => fileName.endsWith('.json'))
            .map(
              (fileName) =>
                  fileName.substring(0, fileName.length - '.json'.length),
            )
            .toList()
          ..sort();
    return [for (final String name in names) ContractFixture.load(name)];
  }

  final String name;

  /// e.g. "GET /api/v1/products/8930000000019".
  final String request;
  final int status;
  final Map<String, String> headers;
  final Map<String, dynamic> body;

  /// Path and query of [request], as a URI relative to the server origin.
  Uri get requestUri => Uri.parse(request.substring(request.indexOf(' ') + 1));

  http.Response toResponse() {
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8', ...headers},
    );
  }
}
