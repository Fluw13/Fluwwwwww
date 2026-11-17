import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluw/features/scan/domain/photo_metadata.dart';

Uint8List _fixture(String name) => File('test/fixtures/photos/$name').readAsBytesSync();

bool _contains(Uint8List bytes, String text) {
  final needle = text.codeUnits;
  for (var start = 0; start + needle.length <= bytes.length; start++) {
    var matches = true;
    for (var index = 0; index < needle.length && matches; index++) {
      matches = bytes[start + index] == needle[index];
    }
    if (matches) {
      return true;
    }
  }
  return false;
}

void main() {
  testWidgets('JPEG: bỏ EXIF (vị trí GPS, máy, giờ chụp), XMP, ghi chú và dữ liệu nối sau ảnh; ảnh vẫn mở được', (
    tester,
  ) async {
    final original = _fixture('with_location.jpg');
    expect(_contains(original, 'Exif') && _contains(original, 'GPS') && _contains(original, 'Hanoi'), isTrue);

    final clean = removePhotoMetadata(original)!;

    expect(clean.contentType, 'image/jpeg');
    for (final text in ['Exif', 'GPS', 'Hanoi', 'PhoneMaker', '2026:11:16', 'xmpmeta', 'TrailingGPS']) {
      expect(_contains(clean.bytes, text), isFalse, reason: text);
    }
    expect(clean.bytes.sublist(clean.bytes.length - 2), [0xFF, 0xD9]);
    final image = await tester.runAsync(
      () async => (await (await ui.instantiateImageCodec(clean.bytes)).getNextFrame()).image,
    );
    expect(image!.width, 16);
  });

  testWidgets('PNG: bỏ eXIf và các khối chữ (tEXt, iTXt có XMP); ảnh vẫn mở được', (tester) async {
    final original = _fixture('with_location.png');

    final clean = removePhotoMetadata(original)!;

    expect(clean.contentType, 'image/png');
    for (final text in ['eXIf', 'tEXt', 'iTXt', 'Hanoi', 'GPS']) {
      expect(_contains(clean.bytes, text), isFalse, reason: text);
    }
    final image = await tester.runAsync(
      () async => (await (await ui.instantiateImageCodec(clean.bytes)).getNextFrame()).image,
    );
    expect(image!.height, 16);
  });

  test('định dạng khác (GIF, HEIC, WebP) hoặc file hỏng thì không gửi', () {
    final jpeg = _fixture('with_location.jpg');
    final png = _fixture('with_location.png');
    for (final bytes in [
      Uint8List.fromList('GIF89a....'.codeUnits),
      Uint8List.fromList([0, 0, 0, 24, ...'ftypheic'.codeUnits, 0, 0, 0, 0]),
      Uint8List.fromList([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits]),
      Uint8List(0),
      Uint8List.sublistView(jpeg, 0, 300),
      Uint8List.sublistView(png, 0, 60),
    ]) {
      expect(removePhotoMetadata(bytes), isNull);
    }
  });
}
