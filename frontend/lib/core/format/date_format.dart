/// "30/10/2025", in the device's time zone.
String formatVietnameseDate(DateTime date) {
  final DateTime local = date.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
}
