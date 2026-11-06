import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/history/session_history.dart';
import 'package:frontend/models/product_summary.dart';

ProductSummary _product(String barcode, {String name = 'Sản phẩm'}) {
  return ProductSummary(barcode: barcode, name: name, brand: '', imageUrl: '');
}

void main() {
  test('sản phẩm mới quét lên đầu; quét lại thì chuyển lên đầu, không trùng', () {
    final SessionHistory history = SessionHistory()
      ..addScan(_product('1'))
      ..addScan(_product('2'))
      ..addScan(_product('1'));

    expect(history.scans.map((product) => product.barcode), ['1', '2']);
  });

  test('sản phẩm không có mã vạch thì so theo tên, không phân biệt hoa thường', () {
    final SessionHistory history = SessionHistory()
      ..addScan(_product('', name: 'Mì Hảo Hảo'))
      ..addScan(_product('', name: 'mì hảo hảo'));

    expect(history.scans, hasLength(1));
  });

  test('từ khóa: bỏ khoảng trắng, bỏ rỗng, không trùng (không phân biệt hoa thường)', () {
    final SessionHistory history = SessionHistory()
      ..addSearch('  Sữa chua ')
      ..addSearch('   ')
      ..addSearch('mì')
      ..addSearch('SỮA CHUA');

    expect(history.searches, ['SỮA CHUA', 'mì']);
  });

  test('giữ tối đa ${SessionHistory.maxEntries} mục, bỏ mục cũ nhất', () {
    final SessionHistory history = SessionHistory();
    for (int i = 0; i < SessionHistory.maxEntries + 5; i++) {
      history
        ..addScan(_product('$i'))
        ..addSearch('từ khóa $i');
    }

    expect(history.scans, hasLength(SessionHistory.maxEntries));
    expect(history.scans.first.barcode, '${SessionHistory.maxEntries + 4}');
    expect(history.searches, hasLength(SessionHistory.maxEntries));
  });

  test('báo thay đổi khi thêm hoặc xóa, không báo khi xóa danh sách đã rỗng', () {
    final SessionHistory history = SessionHistory();
    int notifications = 0;
    history.addListener(() => notifications++);

    history
      ..clearScans()
      ..addScan(_product('1'))
      ..clearScans()
      ..addSearch('a')
      ..clearSearches()
      ..clearSearches();

    expect(notifications, 4);
    expect(history.scans, isEmpty);
    expect(history.searches, isEmpty);
  });

  test('danh sách trả ra không sửa được từ bên ngoài', () {
    final SessionHistory history = SessionHistory()..addSearch('a');

    expect(() => history.searches.add('b'), throwsUnsupportedError);
    expect(() => history.scans.clear(), throwsUnsupportedError);
  });
}
