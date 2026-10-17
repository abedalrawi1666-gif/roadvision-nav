import 'geo_coordinate.dart';

class Destination {
  const Destination({required this.name, required this.address, required this.location});
  final String name;
  final String address;
  final GeoCoordinate location;
}

class NavigationStep {
  const NavigationStep({
    required this.instruction,
    required this.location,
    required this.distanceMeters,
    required this.maneuverType,
    this.modifier = '',
  });
  final String instruction;
  final GeoCoordinate location;
  final double distanceMeters;
  final String maneuverType;
  final String modifier;
}

class NavigationRoute {
  const NavigationRoute({
    required this.coordinates,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });
  final List<GeoCoordinate> coordinates;
  final List<NavigationStep> steps;
  final double distanceMeters;
  final double durationSeconds;
}

class VehiclePose {
  const VehiclePose({
    required this.location,
    required this.headingDegrees,
    required this.horizontalAccuracyMeters,
    required this.timestamp,
    this.speedMetersPerSecond = 0,
  });
  final GeoCoordinate location;
  final double headingDegrees;
  final double horizontalAccuracyMeters;
  final DateTime timestamp;
  final double speedMetersPerSecond;
}

abstract interface class RoutingService {
  Future<NavigationRoute> calculate({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  });
}
