import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../domain/navigation_route.dart';
import '../services/location_service.dart';
import '../services/mapbox_api.dart';
import '../services/voice_service.dart';

class NavigationController extends ChangeNotifier {
  NavigationController()
      : api = MapboxApi(AppConfig.mapboxPublicToken),
        location = LocationService(),
        voice = VoiceService();

  final MapboxApi api;
  final LocationService location;
  final VoiceService voice;
  StreamSubscription<VehiclePose>? _locationSubscription;
  VehiclePose? pose;
  Destination? destination;
  NavigationRoute? route;
  String? error;
  bool busy = false;
  bool guiding = false;
  int stepIndex = 0;
  bool _disposed = false;

  NavigationStep? get nextStep => route == null || route!.steps.isEmpty
      ? null
      : route!.steps[stepIndex.clamp(0, route!.steps.length - 1).toInt()];

  double? get metersToNextStep => pose == null || nextStep == null
      ? null
      : pose!.location.distanceTo(nextStep!.location);

  bool get locationReliable {
    final p = pose;
    return p != null &&
        p.horizontalAccuracyMeters <= 30 &&
        DateTime.now().difference(p.timestamp).inSeconds.abs() < 12;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> locate() async {
    busy = true;
    error = null;
    _notify();
    try {
      pose = await location.current();
      await _locationSubscription?.cancel();
      _locationSubscription = location.watch().listen(
        _onPose,
        onError: (Object e) { error = 'انقطع تحديث الموقع: $e'; _notify(); },
      );
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _onPose(VehiclePose updated) {
    pose = updated;
    final step = nextStep;
    if (guiding && step != null && updated.horizontalAccuracyMeters <= 30) {
      // Simplified turn-proximity advance, not map-matched or safety-certified.
      if (updated.location.distanceTo(step.location) < 32 &&
          stepIndex < (route?.steps.length ?? 1) - 1) {
        stepIndex++;
        final instruction = nextStep?.instruction;
        if (instruction != null) voice.speak(instruction);
      }
    }
    _notify();
  }

  Future<void> chooseDestination(Destination selected) async {
    destination = selected;
    guiding = false;
    route = null;
    stepIndex = 0;
    error = null;
    _notify();
    await recalculate();
  }

  Future<void> recalculate() async {
    if (!AppConfig.hasMapboxToken) {
      error = 'يلزم مفتاح Mapbox عام لتشغيل البحث وحساب المسارات.';
      _notify();
      return;
    }
    if (destination == null) return;
    if (pose == null) await locate();
    if (pose == null) {
      error ??= 'لا يمكن حساب الطريق قبل تحديد موقعك.';
      _notify();
      return;
    }
    busy = true;
    error = null;
    _notify();
    try {
      // This invokes a live traffic-aware Mapbox Directions API route.
      final calculated = await api.calculate(
        origin: pose!.location,
        destination: destination!.location,
      );
      route = calculated;
      stepIndex = calculated.steps.length > 1 ? 1 : 0;
      guiding = false;
    } catch (e) {
      error = '$e';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> toggleGuidance() async {
    if (route == null) return;
    guiding = !guiding;
    if (guiding && nextStep != null) await voice.speak(nextStep!.instruction);
    if (!guiding) await voice.stop();
    _notify();
  }

  void toggleVoice() {
    voice.enabled = !voice.enabled;
    _notify();
  }

  void clearRoute() {
    destination = null;
    route = null;
    guiding = false;
    stepIndex = 0;
    voice.stop();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSubscription?.cancel();
    api.dispose();
    voice.stop();
    super.dispose();
  }
}
