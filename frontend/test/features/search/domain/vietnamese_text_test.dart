import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/search/domain/vietnamese_text.dart';

void main() {
  test('chữ dựng sẵn và chữ tổ hợp (dấu rời) cho cùng một dạng', () {
    const precomposed = 'Cà chua, PHỞ, ước';
    const combining = 'Cà chua, PHỞ, ước';
    expect(canonicalVietnamese(combining), canonicalVietnamese(precomposed));
  });

  test('dấu thanh gõ trước dấu mũ/móc vẫn cùng dạng', () {
    expect(canonicalVietnamese('ó̂'), canonicalVietnamese('ố'));
    expect(canonicalVietnamese('ố'), canonicalVietnamese('ố'));
  });

  test('chữ thường, dấu câu thành một dấu cách, bỏ cách thừa', () {
    expect(canonicalVietnamese('  Phô-mai   (Pháp) '), canonicalVietnamese('phô mai pháp'));
    expect(foldVietnamese('  Phô-mai   (Pháp) '), 'pho mai phap');
  });

  test('bỏ dấu: đ thành d, giữ chữ số', () {
    expect(foldVietnamese('Đậu phụ 100g'), 'dau phu 100g');
    expect(foldVietnamese('ỨC GÀ'), 'uc ga');
    expect(foldVietnamese('Sầu riêng, mãng cầu xiêm, dưa hấu'), 'sau rieng mang cau xiem dua hau');
  });

  test('đủ 12 nguyên âm × 6 thanh đều bỏ dấu đúng', () {
    const rows = {
      'a': 'aàáảãạăằắẳẵặâầấẩẫậ',
      'e': 'eèéẻẽẹêềếểễệ',
      'i': 'iìíỉĩị',
      'o': 'oòóỏõọôồốổỗộơờớởỡợ',
      'u': 'uùúủũụưừứửữự',
      'y': 'yỳýỷỹỵ',
    };
    for (final MapEntry(key: base, value: letters) in rows.entries) {
      expect(foldVietnamese(letters), base * letters.length, reason: letters);
    }
  });
}
