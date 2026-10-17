import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'jpeg_frame_extractor.dart';

/// Prototype viewer for a user-approved HTTPS MJPEG endpoint.
class MjpegCameraView extends StatefulWidget {
  const MjpegCameraView({super.key, required this.url, this.onFailure});
  final String url;
  final VoidCallback? onFailure;

  @override
  State<MjpegCameraView> createState() => _MjpegCameraViewState();
}

class _MjpegCameraViewState extends State<MjpegCameraView>
    with WidgetsBindingObserver {
  http.Client? _client;
  Uint8List? _frame;
  String? _error;
  bool _running = false;
  bool _stopped = false;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    final current = ++_session;
    final client = http.Client();
    _client = client;
    _stopped = false;
    setState(() { _running = true; _error = null; });
    try {
      final request = http.Request('GET', Uri.parse(widget.url));
      request.headers['Accept'] = 'multipart/x-mixed-replace, image/jpeg';
      final response = await client.send(request).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) throw StateError('HTTP ${response.statusCode}');
      final mime = response.headers['content-type']?.toLowerCase() ?? '';
      if (!mime.contains('multipart') && !mime.contains('image/jpeg')) {
        throw StateError('الخادم لا يقدم بث MJPEG مدعوماً.');
      }
      final extractor = JpegFrameExtractor();
      await for (final chunk in response.stream.timeout(const Duration(seconds: 15))) {
        if (_stopped || current != _session) break;
        for (final frame in extractor.add(chunk)) {
          if (!mounted || _stopped || current != _session) break;
          setState(() => _frame = frame);
        }
      }
      if (current == _session && !_stopped) throw StateError('انقطع بث الكاميرا.');
    } catch (e) {
      if (mounted && current == _session && !_stopped) {
        setState(() => _error = 'تعذر عرض كاميرا السيارة: $e');
        widget.onFailure?.call();
      }
    } finally {
      client.close();
      if (current == _session && mounted) setState(() => _running = false);
    }
  }

  void _stop() {
    _stopped = true;
    _session++;
    _client?.close();
    _client = null;
  }

  @override
  void didUpdateWidget(covariant MjpegCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _stop();
      _frame = null;
      _start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stop();
    } else if (state == AppLifecycleState.resumed && _stopped) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
    const ColoredBox(color: Colors.black),
    if (_frame != null) Image.memory(_frame!, gaplessPlayback: true, fit: BoxFit.contain),
    if (_frame == null) Center(child: _running && _error == null
        ? const CircularProgressIndicator()
        : Padding(padding: const EdgeInsets.all(20), child: Text(
          _error ?? 'بث الكاميرا غير متصل', textAlign: TextAlign.center,
        ))),
  ]);
}
