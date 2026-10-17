import 'package:flutter_test/flutter_test.dart';
import 'package:roadvision_nav/src/services/video/jpeg_frame_extractor.dart';

void main() {
  test('decodes multiple chunked JPEGs amid MJPEG metadata', () {
    final extractor = JpegFrameExtractor();
    expect(extractor.add([45, 45, 88, 0xFF]), isEmpty);
    expect(extractor.add([0xD8, 3, 4, 0xFF]), isEmpty);
    final frames = extractor.add([
      0xD9, 45, 45, 88, 0xFF, 0xD8, 7, 8, 0xFF, 0xD9,
    ]);
    expect(frames.length, 2);
    expect(frames[0], [0xFF, 0xD8, 3, 4, 0xFF, 0xD9]);
    expect(frames[1], [0xFF, 0xD8, 7, 8, 0xFF, 0xD9]);
  });

  test('drops oversized incomplete frames', () {
    final extractor = JpegFrameExtractor(maxFrameBytes: 10);
    expect(extractor.add([0xFF, 0xD8, ...List.filled(12, 1)]), isEmpty);
    final frames = extractor.add([0xFF, 0xD8, 5, 0xFF, 0xD9]);
    expect(frames.single, [0xFF, 0xD8, 5, 0xFF, 0xD9]);
  });
}
