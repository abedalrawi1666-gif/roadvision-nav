import 'dart:typed_data';

/// Extract JPEG frames from a byte stream, including MJPEG multipart payloads.
/// For trusted, camera-provided MJPEG only; not a complete multipart parser.
class JpegFrameExtractor {
  JpegFrameExtractor({this.maxFrameBytes = 3 * 1024 * 1024});

  final int maxFrameBytes;
  final List<int> _buffer = [];

  List<Uint8List> add(List<int> chunk) {
    _buffer.addAll(chunk);
    final result = <Uint8List>[];
    while (true) {
      final start = _findPair(_buffer, 0xFF, 0xD8);
      if (start == -1) {
        if (_buffer.length > maxFrameBytes) {
          final last = _buffer.last;
          _buffer.clear();
          if (last == 0xFF) _buffer.add(last);
        }
        break;
      }
      if (start > 0) _buffer.removeRange(0, start);
      final end = _findPair(_buffer, 0xFF, 0xD9, from: 2);
      if (end == -1) {
        if (_buffer.length > maxFrameBytes) _buffer.clear();
        break;
      }
      final length = end + 2;
      if (length <= maxFrameBytes) {
        result.add(Uint8List.fromList(_buffer.sublist(0, length)));
      }
      _buffer.removeRange(0, length);
    }
    return result;
  }

  static int _findPair(List<int> bytes, int a, int b, {int from = 0}) {
    for (var i = from; i + 1 < bytes.length; i++) {
      if (bytes[i] == a && bytes[i + 1] == b) return i;
    }
    return -1;
  }
}
