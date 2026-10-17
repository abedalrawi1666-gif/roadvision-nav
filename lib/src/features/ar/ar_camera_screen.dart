import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../services/navigation_controller.dart';
import '../../services/video/mjpeg_camera_view.dart';
import '../settings/camera_preferences.dart';

/// Live video and text guidance only. Route arrows are NOT anchored to the
/// roadway; video alignment requires calibrated AR tracking and validation.
class ArCameraScreen extends StatefulWidget {
  const ArCameraScreen({super.key, required this.navigation,
      required this.preferences, required this.onSettings});
  final NavigationController navigation;
  final CameraPreferences preferences;
  final VoidCallback onSettings;

  @override
  State<ArCameraScreen> createState() => _ArCameraScreenState();
}

class _ArCameraScreenState extends State<ArCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  String? _error;
  bool _paused = false;
  bool _forcePhone = false;
  int _cameraSequence = 0;

  bool get _usePhone => widget.preferences.source == CameraSource.phone ||
      _forcePhone || (widget.preferences.source == CameraSource.carOriginal &&
          widget.preferences.fallbackToPhone);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_usePhone) _openCamera();
  }

  void _closePhone() {
    _cameraSequence++;
    final old = _camera;
    _camera = null;
    old?.dispose();
  }

  Future<void> _openCamera() async {
    if (_camera != null || _paused || !_usePhone) return;
    final current = ++_cameraSequence;
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) throw StateError('لا توجد كاميرا متاحة.');
      final selected = devices.firstWhere(
        (d) => d.lensDirection == CameraLensDirection.back,
        orElse: () => devices.first,
      );
      final next = CameraController(selected, ResolutionPreset.high,
          enableAudio: false);
      await next.initialize();
      if (!mounted || _paused || !_usePhone || current != _cameraSequence) {
        await next.dispose();
        return;
      }
      setState(() { _camera = next; _error = null; });
    } catch (e) {
      if (mounted && current == _cameraSequence) {
        setState(() => _error = 'تعذر تشغيل كاميرا الهاتف: $e');
      }
    }
  }

  @override
  void didUpdateWidget(covariant ArCameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences.source != widget.preferences.source ||
        oldWidget.preferences.networkUrl != widget.preferences.networkUrl ||
        oldWidget.preferences.fallbackToPhone != widget.preferences.fallbackToPhone) {
      _forcePhone = false;
      _closePhone();
      _error = null;
      if (_usePhone) _openCamera();
    }
  }

  void _networkFailure() {
    if (!mounted || _forcePhone || !widget.preferences.fallbackToPhone) return;
    setState(() => _forcePhone = true);
    _openCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _paused = true;
      _closePhone();
    } else if (state == AppLifecycleState.resumed) {
      _paused = false;
      if (_usePhone) _openCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closePhone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    final source = widget.preferences.source;
    final usesPhone = _usePhone;
    return Stack(fit: StackFit.expand, children: [
      if (usesPhone)
        if (cam != null && cam.value.isInitialized)
          ColoredBox(color: Colors.black, child: Center(child: CameraPreview(cam)))
        else
          ColoredBox(color: const Color(0xFF0B131B), child: Center(
            child: _error == null ? const CircularProgressIndicator()
                : Padding(padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center)),
          ))
      else if (source == CameraSource.carNetwork &&
          CameraPreferences.isValidNetworkUrl(widget.preferences.networkUrl))
        MjpegCameraView(
          url: widget.preferences.networkUrl,
          onFailure: _networkFailure,
        )
      else
        ColoredBox(color: const Color(0xFF0B131B), child: Center(
          child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_outlined, size: 44),
              const SizedBox(height: 12),
              Text(source == CameraSource.carOriginal
                  ? 'الوصول إلى كاميرا السيارة الأصلية غير مدعوم مباشرةً دون واجهة مصنّع معتمدة.'
                  : 'أدخل عنوان بث HTTPS MJPEG لكاميرا متوافقة.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: widget.onSettings,
                  child: const Text('إعدادات الكاميرا')),
            ]),
          ),
        )),
      Positioned(top: 12, left: 12, right: 12, child: DecoratedBox(
        decoration: BoxDecoration(color: const Color(0xE1122635),
            borderRadius: BorderRadius.circular(14)),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(usesPhone ? Icons.smartphone : Icons.directions_car,
                color: Colors.lightBlueAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(usesPhone
                ? source == CameraSource.phone ? 'كاميرا الهاتف' : 'كاميرا الهاتف (بديل)'
                : 'كاميرا السيارة — ${source == CameraSource.carNetwork ? 'بث شبكي' : 'تكامل المصنع غير متوفر'}',
                style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(onPressed: widget.onSettings,
                tooltip: 'تغيير الكاميرا', icon: const Icon(Icons.tune)),
          ]),
          const Text('تعليمات الملاحة تظهر خارج الصورة؛ لا يوجد إسقاط AR أرضي معاير.',
              style: TextStyle(fontSize: 11, color: Colors.white70)),
        ])),
      )),
      const Positioned(bottom: 12, left: 12, right: 12,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xDB301B1B),
              borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Padding(padding: EdgeInsets.all(10),
            child: Text('نسخة اختبارية: لا تعتمد على هذه الشاشة أثناء القيادة.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
        ),
      ),
    ]);
  }
}
