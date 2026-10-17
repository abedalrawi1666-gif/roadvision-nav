import 'package:flutter/material.dart';
import 'camera_preferences.dart';

class CameraSettingsSheet extends StatefulWidget {
  const CameraSettingsSheet({super.key, required this.initial});
  final CameraPreferences initial;

  @override
  State<CameraSettingsSheet> createState() => _CameraSettingsSheetState();
}

class _CameraSettingsSheetState extends State<CameraSettingsSheet> {
  late CameraSource _source;
  late bool _fallback;
  late TextEditingController _url;
  String? _error;

  @override
  void initState() {
    super.initState();
    _source = widget.initial.source;
    _fallback = widget.initial.fallbackToPhone;
    _url = TextEditingController(text: widget.initial.networkUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (_source == CameraSource.carNetwork &&
        !CameraPreferences.isValidNetworkUrl(_url.text)) {
      setState(() => _error = 'أدخل رابط بث MJPEG يبدأ بـ https:// ومن دون بيانات دخول في الرابط.');
      return;
    }
    Navigator.of(context).pop(CameraPreferences(
      source: _source, networkUrl: _url.text.trim(),
      fallbackToPhone: _fallback,
    ));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('مصدر كاميرا الطريق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
          const SizedBox(height: 8),
          const Text('اختر الكاميرا التي تريد عرضها في وضع الملاحة بالكاميرا. تعمل خرائط 3D بشكل مستقل.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          RadioListTile<CameraSource>(
            value: CameraSource.phone, groupValue: _source,
            onChanged: (v) => setState(() { _source = v!; _error = null; }),
            title: const Text('كاميرا الموبايل'),
            subtitle: const Text('الكاميرا الخلفية للهاتف أو الجهاز اللوحي'),
            secondary: const Icon(Icons.smartphone),
          ),
          RadioListTile<CameraSource>(
            value: CameraSource.carNetwork, groupValue: _source,
            onChanged: (v) => setState(() { _source = v!; _error = null; }),
            title: const Text('كاميرا سيارة ببث شبكي'),
            subtitle: const Text('كاميرا أو محول متوافق يدعم HTTPS MJPEG'),
            secondary: const Icon(Icons.wifi_tethering),
          ),
          RadioListTile<CameraSource>(
            value: CameraSource.carOriginal, groupValue: _source,
            onChanged: (v) => setState(() { _source = v!; _error = null; }),
            title: const Text('كاميرا السيارة الأصلية'),
            subtitle: const Text('تتطلب موافقة الشركة المصنعة وواجهة وصول متوافقة'),
            secondary: const Icon(Icons.directions_car),
          ),
          if (_source == CameraSource.carNetwork) ...[
            TextField(
              controller: _url, keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              autocorrect: false, enableSuggestions: false,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'رابط بث HTTPS MJPEG',
                hintText: 'https://camera.example/live.mjpg',
              ),
            ),
            const SizedBox(height: 8),
            const Text('البث الشبكي تجريبي. يدعم MJPEG فقط، ولا يدعم RTSP أو H.264. تأكد من إذن الوصول ومن شهادة TLS.',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          if (_source == CameraSource.carOriginal)
            const Card(child: Padding(padding: EdgeInsets.all(12), child: Text(
              'كاميرات السيارة الأصلية غالباً غير متاحة للتطبيقات الخارجية عبر Android Auto أو CarPlay. '
              'هذا الخيار يوضح عدم توفر التكامل حالياً، ولا يدّعي فتح الكاميرا دون SDK معتمد من المصنع.',
              style: TextStyle(fontSize: 12),
            ))),
          SwitchListTile(
            title: const Text('الرجوع إلى كاميرا الهاتف عند التعذر'),
            subtitle: const Text('يمكن إيقاف الرجوع التلقائي من هنا'),
            value: _fallback, onChanged: (v) => setState(() => _fallback = v),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _save,
              icon: const Icon(Icons.check), label: const Text('حفظ الاختيار')),
          const SizedBox(height: 10),
        ]),
      )),
    ),
  );
}
