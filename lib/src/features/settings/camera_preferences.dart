import 'package:shared_preferences/shared_preferences.dart';

/// Phone camera works with the camera plugin. Car video sources depend on
/// manufacturer permission or a user-accessible network camera video feed.
enum CameraSource { phone, carNetwork, carOriginal }

class CameraPreferences {
  const CameraPreferences({
    this.source = CameraSource.phone,
    this.networkUrl = '',
    this.fallbackToPhone = true,
  });

  final CameraSource source;
  final String networkUrl;
  final bool fallbackToPhone;

  CameraPreferences copyWith({CameraSource? source, String? networkUrl,
      bool? fallbackToPhone}) => CameraPreferences(
        source: source ?? this.source,
        networkUrl: networkUrl ?? this.networkUrl,
        fallbackToPhone: fallbackToPhone ?? this.fallbackToPhone,
      );

  /// TLS is required: cleartext camera streams are rejected by default.
  static bool isValidNetworkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty &&
        uri.userInfo.isEmpty && uri.fragment.isEmpty;
  }
}

class CameraPreferencesStore {
  static const _source = 'roadvision.camera.source';
  static const _networkUrl = 'roadvision.camera.networkUrl';
  static const _fallback = 'roadvision.camera.fallback';

  Future<CameraPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceName = prefs.getString(_source);
    final source = CameraSource.values.where((s) => s.name == sourceName)
        .firstOrNull ?? CameraSource.phone;
    return CameraPreferences(
      source: source,
      networkUrl: prefs.getString(_networkUrl) ?? '',
      fallbackToPhone: prefs.getBool(_fallback) ?? true,
    );
  }

  Future<void> save(CameraPreferences settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_source, settings.source.name);
    await prefs.setString(_networkUrl, settings.networkUrl.trim());
    await prefs.setBool(_fallback, settings.fallbackToPhone);
  }
}
