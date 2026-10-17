import 'package:flutter_test/flutter_test.dart';
import 'package:roadvision_nav/src/domain/geo_coordinate.dart';
import 'package:roadvision_nav/src/features/ar/geometry/route_projector.dart';

void main() {
  const origin = GeoCoordinate(latitude: 24, longitude: 46);
  const intrinsics = PinholeIntrinsics(fx: 900, fy: 900, cx: 640, cy: 360);
  const pose = CameraPose3d(
    enuPosition: EnuPoint(0, 0, 0),
    worldToCameraRotation: [1, 0, 0, 0, 1, 0, 0, 0, 1],
  );
  const projector = RouteProjector(intrinsics: intrinsics, pose: pose);

  test('ENU origin maps to zero', () {
    final p = RouteProjector.toEnu(origin, origin);
    expect(p.east, 0);
    expect(p.north, 0);
  });
  test('pinhole camera center projection', () {
    final pixel = projector.project(const EnuPoint(0, 0, 10));
    expect(pixel, isNotNull);
    expect(pixel!.u, 640);
    expect(pixel.v, 360);
  });
  test('rejects points behind camera', () {
    expect(projector.project(const EnuPoint(0, 0, -1)), isNull);
  });
  test('east shift becomes rightwards image displacement in identity test pose', () {
    expect(projector.project(const EnuPoint(1, 0, 10))!.u, closeTo(730, .01));
  });
}
