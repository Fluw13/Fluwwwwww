import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('HomeScreen hiển thị màn hình chính và đánh thức máy chủ', (WidgetTester tester) async {
    final List<Uri> requests = [];
    final ApiService apiService = ApiService(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response('{"success":true,"status":"ok"}', 200);
      }),
    );

    await tester.pumpWidget(MaterialApp(home: HomeScreen(apiService: apiService)));
    await tester.pump();

    expect(find.text('Bạn đang ăn món gì?'), findsOneWidget);
    expect(find.text('QUÉT MÃ VẠCH'), findsOneWidget);
    expect(requests.map((url) => url.path), ['/health']);
  });
}
