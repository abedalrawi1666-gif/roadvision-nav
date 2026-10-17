import 'dart:math' as math;

/// App coordinates: latitude first. Mapbox expects longitude, latitude.
class GeoCoordinate {
  const GeoCoordinate({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;

  double distanceTo(GeoCoordinate other) {
    const earthMeters = 6371000.0;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(latitude * math.pi / 180) *
            math.cos(other.latitude * math.pi / 180) *
            math.pow(math.sin(dLon / 2), 2);
    final limitedA = a.toDouble().clamp(0.0, 1.0);
    return earthMeters * 2 * math.atan2(math.sqrt(limitedA), math.sqrt(1 - limitedA));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinate && latitude == other.latitude && longitude == other.longitude;
  @override
  int get hashCode => Object.hash(latitude, longitude);
}
