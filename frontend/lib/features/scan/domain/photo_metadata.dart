import 'dart:typed_data';

/// A photo ready to leave the phone: its real format, read from the first bytes (the picker keeps names like
/// `scaled_x.heic` on JPEG data), and the blocks that can hold where and when it was taken removed.
final class CleanPhoto {
  const CleanPhoto({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

/// Removes EXIF (GPS position, time, phone model), XMP, IPTC and text blocks from a JPEG or PNG. Returns null for any
/// other format or a damaged file: their metadata cannot be removed here, so they are not sent.
CleanPhoto? removePhotoMetadata(Uint8List bytes) {
  if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) {
    final clean = _cleanJpeg(bytes);
    return clean == null ? null : CleanPhoto(bytes: clean, contentType: 'image/jpeg');
  }
  if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    final clean = _cleanPng(bytes);
    return clean == null ? null : CleanPhoto(bytes: clean, contentType: 'image/png');
  }
  return null;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

// APP1 holds EXIF and XMP, APP13 holds IPTC, COM is free text.
const Set<int> _droppedJpegMarkers = {0xE1, 0xED, 0xFE};

/// Copies the segments before the image data except the dropped ones, then the image data up to its end marker.
/// Anything after that marker (extra pictures some phones append, each with its own EXIF) is left out.
Uint8List? _cleanJpeg(Uint8List bytes) {
  final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(bytes, 0, 2));
  var index = 2;
  while (index + 4 <= bytes.length) {
    if (bytes[index] != 0xFF) {
      return null;
    }
    final marker = bytes[index + 1];
    if (marker == 0xFF) {
      index++;
      continue;
    }
    if (marker == 0xDA) {
      final end = _jpegEnd(bytes, index);
      if (end == null) {
        return null;
      }
      out.add(Uint8List.sublistView(bytes, index, end));
      return out.takeBytes();
    }
    final length = (bytes[index + 2] << 8) | bytes[index + 3];
    final next = index + 2 + length;
    if (length < 2 || next > bytes.length) {
      return null;
    }
    if (!_droppedJpegMarkers.contains(marker)) {
      out.add(Uint8List.sublistView(bytes, index, next));
    }
    index = next;
  }
  return null;
}

/// The end of the image data: just after the first end-of-image marker. Inside the data a 0xFF byte is always followed
/// by 0x00 or a restart marker, so the first FF D9 is the real end.
int? _jpegEnd(Uint8List bytes, int start) {
  for (var index = start; index + 1 < bytes.length; index++) {
    if (bytes[index] == 0xFF && bytes[index + 1] == 0xD9) {
      return index + 2;
    }
  }
  return null;
}

// eXIf is EXIF; the three text chunks can carry XMP or comments; tIME is when the file was last changed.
const Set<String> _droppedPngChunks = {'eXIf', 'tEXt', 'zTXt', 'iTXt', 'tIME'};

Uint8List? _cleanPng(Uint8List bytes) {
  final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(bytes, 0, 8));
  var index = 8;
  while (index + 12 <= bytes.length) {
    final length = ByteData.sublistView(bytes, index, index + 4).getUint32(0);
    final type = String.fromCharCodes(bytes, index + 4, index + 8);
    final next = index + 12 + length;
    if (next > bytes.length) {
      return null;
    }
    if (!_droppedPngChunks.contains(type)) {
      out.add(Uint8List.sublistView(bytes, index, next));
    }
    if (type == 'IEND') {
      return out.takeBytes();
    }
    index = next;
  }
  return null;
}
