/// Parses the three HTTP-date formats a recipient must accept (RFC 9110
/// §5.6.7): IMF-fixdate, obsolete RFC 850 and asctime. Returns UTC, or null
/// for anything else.
DateTime? parseHttpDate(String raw) {
  final String value = raw.trim();
  return _parseImfFixdate(value) ?? _parseRfc850(value) ?? _parseAsctime(value);
}

final RegExp _imfFixdate = RegExp(
  r'^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);
final RegExp _rfc850 = RegExp(
  r'^[A-Za-z]{6,9}, (\d{2})-([A-Za-z]{3})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);
final RegExp _asctime = RegExp(
  r'^[A-Za-z]{3} ([A-Za-z]{3}) ([ \d]\d) (\d{2}):(\d{2}):(\d{2}) (\d{4})$',
);

const List<String> _months = [
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

DateTime? _parseImfFixdate(String value) {
  final RegExpMatch? m = _imfFixdate.firstMatch(value);
  if (m == null) return null;
  return _build(
    year: int.parse(m[3]!),
    month: m[2]!,
    day: int.parse(m[1]!),
    hour: int.parse(m[4]!),
    minute: int.parse(m[5]!),
    second: int.parse(m[6]!),
  );
}

DateTime? _parseRfc850(String value) {
  final RegExpMatch? m = _rfc850.firstMatch(value);
  if (m == null) return null;
  final int shortYear = int.parse(m[3]!);
  return _build(
    year: shortYear < 70 ? 2000 + shortYear : 1900 + shortYear,
    month: m[2]!,
    day: int.parse(m[1]!),
    hour: int.parse(m[4]!),
    minute: int.parse(m[5]!),
    second: int.parse(m[6]!),
  );
}

DateTime? _parseAsctime(String value) {
  final RegExpMatch? m = _asctime.firstMatch(value);
  if (m == null) return null;
  return _build(
    year: int.parse(m[6]!),
    month: m[1]!,
    day: int.parse(m[2]!.trim()),
    hour: int.parse(m[3]!),
    minute: int.parse(m[4]!),
    second: int.parse(m[5]!),
  );
}

DateTime? _build({
  required int year,
  required String month,
  required int day,
  required int hour,
  required int minute,
  required int second,
}) {
  final int monthIndex = _months.indexOf(month.toLowerCase()) + 1;
  if (monthIndex == 0 || hour > 23 || minute > 59 || second > 60) return null;

  final DateTime result = DateTime.utc(
    year,
    monthIndex,
    day,
    hour,
    minute,
    second == 60 ? 59 : second,
  );
  // DateTime.utc rolls invalid days over (31 Feb -> 3 Mar); reject those.
  if (result.month != monthIndex || result.day != day) return null;
  return result;
}
