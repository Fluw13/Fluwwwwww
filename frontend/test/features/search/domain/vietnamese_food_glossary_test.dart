import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/domain/vietnamese_food_glossary.dart';
import 'package:fluw/features/search/domain/vietnamese_text.dart';

void main() {
  test('bảng có ít nhất 150 tên, mỗi tên một dạng chuẩn, tiếng Anh 2–100 ký tự như máy chủ nhận', () {
    expect(vietnameseFoodGlossary.length, greaterThanOrEqualTo(150));
    final canonical = vietnameseFoodGlossary.keys.map(canonicalVietnamese).toList();
    expect(canonical.toSet(), hasLength(canonical.length), reason: 'không có hai tên trùng sau khi chuẩn hóa');
    for (final MapEntry(:key, :value) in vietnameseFoodGlossary.entries) {
      expect(value.length, inInclusiveRange(2, 100), reason: key);
      expect(value.trim(), value, reason: key);
    }
  });

  test('mọi tên trong bảng (có dấu) đều tra ra đúng tiếng Anh của nó', () {
    for (final MapEntry(:key, :value) in vietnameseFoodGlossary.entries) {
      expect(englishSearchTermFor(key), value, reason: key);
    }
  });

  test('gõ không dấu vẫn khớp, trừ khi bỏ dấu thì trùng hai món khác nhau', () {
    final englishByFolded = <String, Set<String>>{};
    for (final MapEntry(:key, :value) in vietnameseFoodGlossary.entries) {
      englishByFolded.putIfAbsent(foldVietnamese(key), () => {}).add(value);
    }
    for (final MapEntry(:key, :value) in vietnameseFoodGlossary.entries) {
      final folded = foldVietnamese(key);
      final exactPlain = vietnameseFoodGlossary.keys.where((other) => canonicalVietnamese(other) == folded).firstOrNull;
      final expected = exactPlain != null
          ? vietnameseFoodGlossary[exactPlain]
          : (englishByFolded[folded]!.length == 1 ? value : null);
      expect(englishSearchTermFor(folded), expected, reason: '$key → $folded');
    }
    expect(englishSearchTermFor('ca chua'), 'tomato');
    expect(englishSearchTermFor('UC GA'), 'chicken breast');
    expect(englishSearchTermFor('dua'), isNull, reason: 'dứa hay dừa');
    expect(englishSearchTermFor('me'), 'tamarind', reason: '"me" đúng là một tên trong bảng');
  });

  test('chữ có dấu khác thì không bỏ dấu để khớp: "của" không phải "cua"', () {
    expect(englishSearchTermFor('của'), isNull);
    expect(englishSearchTermFor('bơ'), isNull, reason: 'bơ là quả bơ hay bơ động vật, không đoán');
    expect(englishSearchTermFor('chuối'), 'banana');
  });

  test('chữ hoa, dấu câu, dấu rời đều không ảnh hưởng', () {
    expect(englishSearchTermFor('  CÀ   CHUA! '), 'tomato');
    expect(englishSearchTermFor('Cà chua'), 'tomato');
  });

  test('tên món kèm từ mô tả cách nấu/loại vẫn khớp; cụm dài nhất được ưu tiên', () {
    expect(englishSearchTermFor('ức gà luộc'), 'chicken breast');
    expect(englishSearchTermFor('quả chuối chín'), 'banana');
    expect(englishSearchTermFor('trứng luộc'), 'hard-boiled egg', reason: 'có tên riêng thì dùng tên riêng');
    expect(englishSearchTermFor('sữa chua'), 'yogurt', reason: 'không chỉ là "sữa"');
    expect(englishSearchTermFor('thit bo nuong'), 'beef');
    expect(englishSearchTermFor('trai chuoi'), 'banana');
    expect(englishSearchTermFor('gạo thơm'), 'white rice');
  });

  test('món ăn hay sản phẩm có từ lạ thì không gửi tiếng Anh của một phần (phở bò không phải thịt bò)', () {
    for (final query in [
      'phở bò',
      'cơm gà',
      'sữa chua vinamilk',
      'bánh xèo',
      'mì tôm hảo hảo',
      'chicken',
      'luộc',
      'cá kho',
      'ca kho',
      'cá khô',
      'gà chiên',
      'trứng rán',
      'rau muống xào',
    ]) {
      expect(englishSearchTermFor(query), isNull, reason: query);
    }
    expect(englishSearchTermFor(''), isNull);
  });
}
