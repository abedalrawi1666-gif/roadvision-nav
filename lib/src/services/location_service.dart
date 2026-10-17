import 'package:geolocator/geolocator.dart';
import '../domain/geo_coordinate.dart';
import '../domain/navigation_route.dart';

class LocationService {
  Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('فعّل خدمة الموقع من إعدادات الهاتف.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw StateError('لم يتم السماح بتحديد الموقع. يمكنك تغييره من إعدادات الجهاز.');
    }
  }

  Future<VehiclePose> current() async {
    await ensurePermission();
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    ).timeout(const Duration(seconds: 20));
    return _convert(pos);
  }

  Stream<VehiclePose> watch() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    ),
  ).map(_convert);

  VehiclePose _convert(Position pos) => VehiclePose(
    location: GeoCoordinate(latitude: pos.latitude, longitude: pos.longitude),
    headingDegrees: pos.heading,
    horizontalAccuracyMeters: pos.accuracy,
    timestamp: pos.timestamp,
    speedMetersPerSecond: pos.speed,
  );
}
