import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roadvision_nav/src/features/settings/camera_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('source choices include phone, car feed, and original camera', () {
    expect(CameraSource.values, containsAll([
      CameraSource.phone, CameraSource.carNetwork, CameraSource.carOriginal,
    ]));
  });

  test('camera URL requires secure scheme and excludes URL credentials', () {
    expect(CameraPreferences.isValidNetworkUrl('https://cam.example/live.mjpg'), true);
    expect(CameraPreferences.isValidNetworkUrl('http://cam.example/stream'), false);
    expect(CameraPreferences.isValidNetworkUrl('rtsp://cam.example/stream'), false);
    expect(CameraPreferences.isValidNetworkUrl('https://user:password@cam.example/live'), false);
    expect(CameraPreferences.isValidNetworkUrl(''), false);
  });

  test('camera settings are persisted and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CameraPreferencesStore();
    await store.save(const CameraPreferences(
      source: CameraSource.carNetwork,
      networkUrl: 'https://example.org/feed.mjpeg',
      fallbackToPhone: false,
    ));
    final actual = await store.load();
    expect(actual.source, CameraSource.carNetwork);
    expect(actual.networkUrl, 'https://example.org/feed.mjpeg');
    expect(actual.fallbackToPhone, false);
  });
}
