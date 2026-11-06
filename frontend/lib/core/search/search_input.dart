/// What the user typed in the search box, decided before any request is sent,
/// with the same rules the backend applies.
sealed class SearchInput {
  const SearchInput();

  static const int minQueryLength = 2;
  static const int maxQueryLength = 100;

  /// GTIN-8, UPC-A (12), EAN-13 and GTIN-14.
  static const Set<int> barcodeLengths = {8, 12, 13, 14};

  static const String tooShortMessage =
      'Nhập ít nhất $minQueryLength ký tự để tìm theo tên sản phẩm.';
  static const String tooLongMessage =
      'Từ khóa tìm kiếm dài tối đa $maxQueryLength ký tự.';
  static const String noLetterMessage =
      'Từ khóa cần có ít nhất một chữ cái hoặc chữ số.';

  static final RegExp _barcodeLike = RegExp(r'^[\d\s-]+$');
  static final RegExp _separators = RegExp(r'[\s-]');
  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  factory SearchInput.parse(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) return const EmptySearchInput();

    // Spaces and dashes are common when a barcode is copied from a label.
    // Digits of any other length are searched by name ("333" is a beer).
    if (_barcodeLike.hasMatch(text)) {
      final String digits = text.replaceAll(_separators, '');
      if (barcodeLengths.contains(digits.length)) {
        return BarcodeSearchInput(digits);
      }
    }

    // Counted in code points, so a Vietnamese letter counts once.
    final int length = text.runes.length;
    if (length < minQueryLength) {
      return const InvalidSearchInput(tooShortMessage);
    }
    if (length > maxQueryLength) {
      return const InvalidSearchInput(tooLongMessage);
    }
    if (!_letterOrDigit.hasMatch(text)) {
      return const InvalidSearchInput(noLetterMessage);
    }
    return KeywordSearchInput(text);
  }
}

class EmptySearchInput extends SearchInput {
  const EmptySearchInput();
}

/// 8, 12, 13 or 14 digits: opens the product directly instead of searching.
class BarcodeSearchInput extends SearchInput {
  const BarcodeSearchInput(this.barcode);

  final String barcode;
}

class KeywordSearchInput extends SearchInput {
  const KeywordSearchInput(this.query);

  final String query;
}

class InvalidSearchInput extends SearchInput {
  const InvalidSearchInput(this.message);

  final String message;
}
