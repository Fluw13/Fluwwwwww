import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/data/recent_searches_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late RecentSearchesStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = RecentSearchesStorage(await SharedPreferences.getInstance());
  });

  test('mới nhất đứng đầu; tìm lại (khác hoa thường) thì đưa lên đầu, không trùng', () async {
    await storage.add('phở');
    await storage.add('sữa chua');
    final result = await storage.add('PHỞ');

    expect(result, ['PHỞ', 'sữa chua']);
    expect(storage.read(), result);
  });

  test('giữ tối đa 8 mục; xóa một mục; xóa hết', () async {
    for (var i = 0; i < 10; i++) {
      await storage.add('món $i');
    }
    expect(storage.read(), hasLength(RecentSearchesStorage.maxEntries));
    expect(storage.read().first, 'món 9');

    expect(await storage.remove('món 9'), isNot(contains('món 9')));
    await storage.clear();
    expect(storage.read(), isEmpty);
  });

  test('không có kho cài đặt (đọc lỗi lúc mở app) thì vẫn chạy, chỉ không nhớ', () async {
    const storage = RecentSearchesStorage(null);

    expect(await storage.add('phở'), ['phở']);
    expect(storage.read(), isEmpty);
  });
}
