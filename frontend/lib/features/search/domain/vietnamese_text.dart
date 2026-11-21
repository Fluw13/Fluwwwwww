// Comparable forms of Vietnamese text. Dart has no Unicode normalization, and keyboards send both precomposed
// letters ("ố") and base letters with combining marks ("ô" + U+0301), so both are turned into one decomposed form.

const String _modifierMarks = '̛̂̆';
const String _toneMarks = '̣̀́̃̉';

/// Each row: the letter without tone, then grave, acute, hook above, tilde, dot below.
const List<String> _vowelRows = [
  'aàáảãạ',
  'ăằắẳẵặ',
  'âầấẩẫậ',
  'eèéẻẽẹ',
  'êềếểễệ',
  'iìíỉĩị',
  'oòóỏõọ',
  'ôồốổỗộ',
  'ơờớởỡợ',
  'uùúủũụ',
  'ưừứửữự',
  'yỳýỷỹỵ',
];

const Map<String, String> _baseOf = {'ă': 'ă', 'â': 'â', 'ê': 'ê', 'ô': 'ô', 'ơ': 'ơ', 'ư': 'ư'};

const List<String> _toneByColumn = ['', '̀', '́', '̉', '̃', '̣'];

final Map<String, String> _decomposed = {
  for (final row in _vowelRows)
    for (var column = 0; column < _toneByColumn.length; column++)
      row[column]: (_baseOf[row[0]] ?? row[0]) + _toneByColumn[column],
};

bool _isMark(String character) => _modifierMarks.contains(character) || _toneMarks.contains(character);

/// Lower case, letters decomposed with the vowel mark before the tone mark, anything that is not a letter or digit
/// turned into one space: "Cà-chua " → "cà chua".
String canonicalVietnamese(String text) {
  final buffer = StringBuffer();
  var marks = <String>[];
  void flushMarks() {
    marks.sort((first, second) => (_toneMarks.contains(first) ? 1 : 0) - (_toneMarks.contains(second) ? 1 : 0));
    marks.forEach(buffer.write);
    marks = [];
  }

  for (final rune in text.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    if (_isMark(character)) {
      marks.add(character);
      continue;
    }
    flushMarks();
    final decomposed = _decomposed[character];
    if (decomposed != null) {
      buffer.write(decomposed[0]);
      marks.addAll(decomposed.substring(1).split(''));
    } else {
      buffer.write(RegExp('[a-z0-9đ]').hasMatch(character) ? character : ' ');
    }
  }
  flushMarks();
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// [canonicalVietnamese] without any mark and with đ as d, as typed on a keyboard without Vietnamese input.
String foldVietnamese(String text) =>
    canonicalVietnamese(text).split('').where((character) => !_isMark(character)).join().replaceAll('đ', 'd');
