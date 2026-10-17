import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/geo_coordinate.dart';
import '../domain/navigation_route.dart';

class MapboxApi implements RoutingService {
  MapboxApi(this.publicToken, {http.Client? client}) : _client = client ?? http.Client();
  final String publicToken;
  final http.Client _client;

  Future<List<Destination>> search(String searchText, {GeoCoordinate? proximity}) async {
    if (searchText.trim().length < 2) return const [];
    final query = <String, String>{
      'q': searchText.trim(),
      'access_token': publicToken,
      'language': 'ar',
      'limit': '6',
    };
    if (proximity != null) {
      query['proximity'] = '${proximity.longitude},${proximity.latitude}';
    }
    final url = Uri.https('api.mapbox.com', '/search/geocode/v6/forward', query);
    final response = await _client.get(url).timeout(const Duration(seconds: 12));
    final json = _parse(response);
    final features = json['features'];
    if (features is! List) return const [];
    return features.map<Destination?>((value) {
      try {
        final feature = value as Map<String, dynamic>;
        final p = feature['properties'] as Map<String, dynamic>? ?? {};
        final coordinates = p['coordinates'] as Map<String, dynamic>?;
        final geo = feature['geometry'] as Map<String, dynamic>?;
        final raw = geo?['coordinates'] as List?;
        final lon = coordinates?['longitude'] as num? ?? (raw?[0] as num?);
        final lat = coordinates?['latitude'] as num? ?? (raw?[1] as num?);
        if (lon == null || lat == null) return null;
        return Destination(
          name: (p['name'] ?? p['full_address'] ?? 'موقع').toString(),
          address: (p['full_address'] ?? p['place_formatted'] ?? '').toString(),
          location: GeoCoordinate(latitude: lat.toDouble(), longitude: lon.toDouble()),
        );
      } catch (_) {
        return null;
      }
    }).whereType<Destination>().toList();
  }

  @override
  Future<NavigationRoute> calculate({
    required GeoCoordinate origin,
    required GeoCoordinate destination,
  }) async {
    final coordinates = '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final url = Uri.https('api.mapbox.com', '/directions/v5/mapbox/driving-traffic/$coordinates', {
      'access_token': publicToken,
      'geometries': 'geojson',
      'overview': 'full',
      'steps': 'true',
      'alternatives': 'false',
      'language': 'ar',
    });
    final response = await _client.get(url).timeout(const Duration(seconds: 20));
    final json = _parse(response);
    final routes = json['routes'];
    if (routes is! List || routes.isEmpty) {
      throw StateError('لا يوجد مسار متاح إلى الوجهة.');
    }
    final result = routes.first as Map<String, dynamic>;
    final geometry = result['geometry'] as Map<String, dynamic>;
    final points = (geometry['coordinates'] as List)
        .map((p) => GeoCoordinate(latitude: (p[1] as num).toDouble(), longitude: (p[0] as num).toDouble()))
        .toList(growable: false);
    final steps = <NavigationStep>[];
    for (final leg in (result['legs'] as List? ?? const [])) {
      for (final stepValue in ((leg as Map<String, dynamic>)['steps'] as List? ?? const [])) {
        final step = stepValue as Map<String, dynamic>;
        final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
        final point = maneuver['location'] as List?;
        if (point == null || point.length < 2) continue;
        steps.add(NavigationStep(
          instruction: (maneuver['instruction'] ?? step['name'] ?? 'تابع الطريق').toString(),
          location: GeoCoordinate(latitude: (point[1] as num).toDouble(), longitude: (point[0] as num).toDouble()),
          distanceMeters: (step['distance'] as num? ?? 0).toDouble(),
          maneuverType: (maneuver['type'] ?? '').toString(),
          modifier: (maneuver['modifier'] ?? '').toString(),
        ));
      }
    }
    if (points.length < 2) throw StateError('بيانات المسار غير مكتملة.');
    return NavigationRoute(
      coordinates: points,
      steps: steps,
      distanceMeters: (result['distance'] as num).toDouble(),
      durationSeconds: (result['duration'] as num).toDouble(),
    );
  }

  Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('تعذّر فهم استجابة خدمة الخرائط.');
    }
    if (response.statusCode != 200 || (json['code'] != null && json['code'] != 'Ok')) {
      final error = (json['message'] ?? json['error'] ?? 'تحقق من مفتاح Mapbox أو اتصال الإنترنت').toString();
      throw StateError('خطأ من خدمة الخرائط: $error');
    }
    return json;
  }

  void dispose() => _client.close();
}
