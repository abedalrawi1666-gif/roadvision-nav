class AppConfig {
  AppConfig._();
  /// Mapbox public token is passed at build/run time, not committed to source.
  static const mapboxPublicToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');
  static bool get hasMapboxToken => mapboxPublicToken.startsWith('pk.');
}
