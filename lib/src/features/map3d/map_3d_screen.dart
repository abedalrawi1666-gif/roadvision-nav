import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/app_config.dart';
import '../../domain/navigation_route.dart';
import '../../services/navigation_controller.dart';

class Map3dScreen extends StatefulWidget {
  const Map3dScreen({super.key, required this.navigation});
  final NavigationController navigation;
  @override
  State<Map3dScreen> createState() => _Map3dScreenState();
}

class _Map3dScreenState extends State<Map3dScreen> {
  MapboxMap? _map;
  PolylineAnnotationManager? _lines;
  NavigationRoute? _lastDrawn;
  bool _styleReady = false;
  int _routeDrawSequence = 0;
  DateTime? _lastRecenter;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.navigation.addListener(_navigationChanged);
  }

  @override
  void didUpdateWidget(covariant Map3dScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigation != widget.navigation) {
      oldWidget.navigation.removeListener(_navigationChanged);
      widget.navigation.addListener(_navigationChanged);
      _lastDrawn = null;
      _navigationChanged();
    }
  }

  @override
  void dispose() {
    widget.navigation.removeListener(_navigationChanged);
    super.dispose();
  }

  void _navigationChanged() {
    _syncRoute();
    final map = _map;
    final pose = widget.navigation.pose;
    if (map == null || pose == null) return;
    final now = DateTime.now();
    if (_lastRecenter != null && now.difference(_lastRecenter!).inMilliseconds < 1000) return;
    _lastRecenter = now;
    map.setCamera(CameraOptions(
      center: Point(coordinates: Position(pose.location.longitude, pose.location.latitude)),
      zoom: widget.navigation.guiding ? 17.3 : 15.7,
      pitch: widget.navigation.guiding ? 65.0 : 55.0,
      bearing: widget.navigation.guiding && widget.navigation.locationReliable
          ? pose.headingDegrees : 0.0,
    ));
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    if (_map == null || !mounted) return;
    _styleReady = true;
    _lines = await _map!.annotations.createPolylineAnnotationManager();
    if (mounted) _syncRoute();
  }

  Future<void> _syncRoute() async {
    final manager = _lines;
    if (!_styleReady || manager == null) return;
    final route = widget.navigation.route;
    if (identical(_lastDrawn, route)) return;
    _lastDrawn = route;
    final version = ++_routeDrawSequence;
    try {
      await manager.deleteAll();
      if (!mounted || version != _routeDrawSequence || route == null) return;
      await manager.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: route.coordinates
            .map((p) => Position(p.longitude, p.latitude)).toList()),
        lineColor: 0xFF22B9F5,
        lineWidth: 9.0,
        lineOpacity: 0.93,
      ));
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر رسم الطريق: $e');
    }
  }

  Future<void> _recenter() async {
    final nav = widget.navigation;
    if (nav.pose == null) await nav.locate();
    final pos = nav.pose;
    if (pos == null || _map == null) return;
    await _map!.setCamera(CameraOptions(
      center: Point(coordinates: Position(pos.location.longitude, pos.location.latitude)),
      zoom: 16, pitch: 55,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxToken) {
      return const Center(child: Padding(padding: EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.key_outlined, size: 50), SizedBox(height: 12),
          Text('خريطة 3D تحتاج مفتاح Mapbox عاماً. أضفه عند تشغيل التطبيق عبر MAPBOX_PUBLIC_TOKEN.',
            textAlign: TextAlign.center),
        ]),
      ));
    }
    return Stack(children: [
      MapWidget(
        key: const ValueKey('roadvision-map'),
        styleUri: MapboxStyles.STANDARD,
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(46.6753, 24.7111)),
          zoom: 15.5, pitch: 60.0, bearing: 0.0,
        ),
        onMapCreated: _onMapCreated,
        onStyleLoadedListener: _onStyleLoaded,
      ),
      Positioned(left: 14, bottom: 16, child: FloatingActionButton.small(
        tooltip: 'الانتقال إلى موقعي',
        onPressed: _recenter,
        child: const Icon(Icons.my_location),
      )),
      if (_error != null)
        Positioned(top: 8, left: 12, right: 12,
          child: Material(color: Colors.deepOrange.shade900,
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!)))),
    ]);
  }
}
