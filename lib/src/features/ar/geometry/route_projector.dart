import 'dart:math' as math;
import '../../../domain/geo_coordinate.dart';

/// Pure mathematical foundation for road geometry registration.
/// NOT CONNECTED TO CAMERA: requires validated intrinsics, timestamped
/// visual-inertial camera pose and ground height before any live use.
class PinholeIntrinsics {
  const PinholeIntrinsics({
    required this.fx,
    required this.fy,
    required this.cx,
    required this.cy,
  });
  final double fx, fy, cx, cy;
}

class EnuPoint {
  const EnuPoint(this.east, this.north, this.up);
  final double east, north, up;
}

class PixelPoint {
  const PixelPoint(this.u, this.v);
  final double u, v;
}

/// `worldToCameraRotation` is a row-major 3x3 rigid rotation matrix.
/// Optical camera coordinates: X right, Y down, Z forward.
/// Camera position is expressed in local ENU metres.
class CameraPose3d {
  const CameraPose3d({
    required this.enuPosition,
    required this.worldToCameraRotation,
  }) : assert(worldToCameraRotation.length == 9);
  final EnuPoint enuPosition;
  final List<double> worldToCameraRotation;
}

class RouteProjector {
  const RouteProjector({required this.intrinsics, required this.pose});
  final PinholeIntrinsics intrinsics;
  final CameraPose3d pose;

  static EnuPoint toEnu(GeoCoordinate point, GeoCoordinate reference, {double height = 0}) {
    const earthRadius = 6378137.0;
    const radians = math.pi / 180;
    final dLat = (point.latitude - reference.latitude) * radians;
    final dLon = (point.longitude - reference.longitude) * radians;
    return EnuPoint(
      earthRadius * dLon * math.cos(reference.latitude * radians),
      earthRadius * dLat,
      height,
    );
  }

  /// Returns null for points behind or too close to the camera optical plane.
  PixelPoint? project(EnuPoint world) {
    final dx = world.east - pose.enuPosition.east;
    final dy = world.north - pose.enuPosition.north;
    final dz = world.up - pose.enuPosition.up;
    final r = pose.worldToCameraRotation;
    final x = r[0] * dx + r[1] * dy + r[2] * dz;
    final y = r[3] * dx + r[4] * dy + r[5] * dz;
    final z = r[6] * dx + r[7] * dy + r[8] * dz;
    if (!z.isFinite || z <= 0.2) return null;
    return PixelPoint(
      intrinsics.fx * x / z + intrinsics.cx,
      intrinsics.fy * y / z + intrinsics.cy,
    );
  }
}
