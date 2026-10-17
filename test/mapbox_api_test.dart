import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roadvision_nav/src/domain/geo_coordinate.dart';
import 'package:roadvision_nav/src/services/mapbox_api.dart';

void main() {
  test('search parses geocoding coordinates and name', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.mapbox.com');
      expect(request.url.queryParameters['language'], 'ar');
      return http.Response.bytes(utf8.encode('''{"features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[46.68,24.72]},"properties":{"name":"موقع تجريبي","full_address":"الرياض","coordinates":{"longitude":46.68,"latitude":24.72}}}]}'''), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = MapboxApi('pk.mock', client: client);
    final places = await api.search('الرياض');
    expect(places, hasLength(1));
    expect(places.first.location.latitude, 24.72);
    expect(places.first.name, 'موقع تجريبي');
    api.dispose();
  });

  test('directions parses full GeoJSON geometry and maneuver instructions', () async {
    final client = MockClient((request) async {
      expect(request.url.path, contains('/directions/v5/mapbox/driving-traffic/'));
      expect(request.url.queryParameters['steps'], 'true');
      return http.Response.bytes(utf8.encode('''{"code":"Ok","routes":[{"distance":820.0,"duration":100.0,"geometry":{"type":"LineString","coordinates":[[46.68,24.72],[46.69,24.73]]},"legs":[{"steps":[{"distance":820.0,"maneuver":{"instruction":"انعطف يميناً","type":"turn","modifier":"right","location":[46.68,24.72]}}]}]}]}'''), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    });
    final api = MapboxApi('pk.mock', client: client);
    final route = await api.calculate(
      origin: const GeoCoordinate(latitude: 24.72, longitude: 46.68),
      destination: const GeoCoordinate(latitude: 24.73, longitude: 46.69),
    );
    expect(route.coordinates, hasLength(2));
    expect(route.durationSeconds, 100);
    expect(route.steps.first.modifier, 'right');
    api.dispose();
  });

  test('directions surfaces service errors', () async {
    final client = MockClient((request) async =>
        http.Response('{"code":"InvalidInput","message":"Bad route"}', 422));
    final api = MapboxApi('pk.mock', client: client);
    await expectLater(api.calculate(
      origin: const GeoCoordinate(latitude: 24, longitude: 46),
      destination: const GeoCoordinate(latitude: 25, longitude: 47),
    ), throwsStateError);
    api.dispose();
  });
}
