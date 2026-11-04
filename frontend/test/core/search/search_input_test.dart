import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/search/search_input.dart';

String _invalidMessage(String raw) =>
    (SearchInput.parse(raw) as InvalidSearchInput).message;

void main() {
  test('8, 12, 13 hoặc 14 chữ số là mã vạch, mở thẳng sản phẩm', () {
    for (final String raw in [
      '89345631',
      '036000291452',
      '8934563122201',
      '08934563122201',
      '  8934563122201 ',
    ]) {
      expect(SearchInput.parse(raw), isA<BarcodeSearchInput>(), reason: raw);
    }
    expect(
      (SearchInput.parse('0626594000112') as BarcodeSearchInput).barcode,
      '0626594000112',
    );
  });

  test('mã vạch chép từ nhãn có khoảng trắng hoặc gạch nối vẫn nhận', () {
    expect(
      (SearchInput.parse('893 4563 122201') as BarcodeSearchInput).barcode,
      '8934563122201',
    );
    expect(
      (SearchInput.parse('893-4563-122201') as BarcodeSearchInput).barcode,
      '8934563122201',
    );
  });

  test('toàn chữ số nhưng sai độ dài: báo ngay, không gửi đi', () {
    for (final String raw in [
      '333',
      '1234567',
      '123456789',
      '12345678901',
      '123456789012345',
    ]) {
      expect(
        _invalidMessage(raw),
        SearchInput.barcodeLengthMessage,
        reason: raw,
      );
    }
  });

  test(
    'từ khóa có chữ: bỏ khoảng trắng đầu cuối; chữ kèm số vẫn là từ khóa',
    () {
      expect(
        (SearchInput.parse('  mì hảo hảo ') as KeywordSearchInput).query,
        'mì hảo hảo',
      );
      expect(
        (SearchInput.parse('bia 333') as KeywordSearchInput).query,
        'bia 333',
      );
    },
  );

  test('rỗng thì không làm gì', () {
    expect(SearchInput.parse('   '), isA<EmptySearchInput>());
  });

  test('1 ký tự, quá 100 ký tự hoặc không có chữ/số: báo lỗi, không gửi', () {
    expect(_invalidMessage('a'), SearchInput.tooShortMessage);
    expect(_invalidMessage('ạ'), SearchInput.tooShortMessage);
    expect(_invalidMessage('a' * 101), SearchInput.tooLongMessage);
    expect(SearchInput.parse('ạ' * 100), isA<KeywordSearchInput>());
    expect(_invalidMessage('!!'), SearchInput.noLetterMessage);
    expect(_invalidMessage('—…'), SearchInput.noLetterMessage);
  });
}
