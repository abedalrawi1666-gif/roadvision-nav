import 'package:flutter_test/flutter_test.dart';
import 'package:roadvision_nav/src/domain/geo_coordinate.dart';

void main() {
  test('distance is zero for same coordinate', () {
    const riyadh = GeoCoordinate(latitude: 24.7136, longitude: 46.6753);
    expect(riyadh.distanceTo(riyadh), closeTo(0, 0.001));
  });
  test('haversine distance is symmetric and plausible', () {
    const a = GeoCoordinate(latitude: 24.7136, longitude: 46.6753);
    const b = GeoCoordinate(latitude: 24.7236, longitude: 46.6753);
    expect(a.distanceTo(b), inInclusiveRange(1100, 1120));
    expect(a.distanceTo(b), closeTo(b.distanceTo(a), 0.0001));
  });
}
