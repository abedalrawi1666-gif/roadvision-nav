import 'package:flutter/material.dart';
import '../../domain/navigation_route.dart';
import '../../services/navigation_controller.dart';
import '../ar/ar_camera_screen.dart';
import '../map3d/map_3d_screen.dart';
import '../search/destination_search_sheet.dart';
import '../settings/camera_preferences.dart';
import '../settings/camera_settings_sheet.dart';

enum NavigationMode { map3d, camera }

String formatMeters(double value) {
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} كم';
  return '${value.round()} م';
}

String formatDuration(double seconds) {
  final min = (seconds / 60).ceil();
  if (min < 60) return '$min دقيقة';
  return '${min ~/ 60} س ${min % 60} د';
}

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});
  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  final NavigationController navigation = NavigationController();
  NavigationMode mode = NavigationMode.map3d;
  final CameraPreferencesStore _cameraStore = CameraPreferencesStore();
  CameraPreferences _cameraPreferences = const CameraPreferences();

  @override
  void initState() {
    super.initState();
    _loadCameraSettings();
  }

  Future<void> _loadCameraSettings() async {
    try {
      final loaded = await _cameraStore.load();
      if (mounted) setState(() => _cameraPreferences = loaded);
    } catch (_) {
      // Preferences are optional; phone is the safe default.
    }
  }

  Future<void> _cameraSettings() async {
    final selected = await showModalBottomSheet<CameraPreferences>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF112637),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: CameraSettingsSheet(initial: _cameraPreferences),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _cameraPreferences = selected);
    try {
      await _cameraStore.save(selected);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ اختيار الكاميرا على هذا الجهاز.')),
      );
    }
  }


  @override
  void dispose() {
    navigation.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final selected = await showModalBottomSheet<Destination>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF112637),
      showDragHandle: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DestinationSearchSheet(navigation: navigation),
      ),
    );
    if (selected != null) await navigation.chooseDestination(selected);
  }

  void _showAbout() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('عن RoadVision'),
      content: const Text('نسخة هندسية أولية. وضع 3D يوفر عرض الخريطة والمسار المحسوب. '
          'وضع الكاميرا يعرض فيديو مباشراً وإرشادات غير مثبتة على الأرض. '
          'لم يُتحقق من دقة الملاحة أو ملاءمة القيادة الحقيقية بعد. '
          'الموقع يُستخدم أثناء فتح التطبيق فقط، والكاميرا لا تُسجّل الفيديو.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('موافق'))],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: navigation,
      builder: (context, _) {
        final route = navigation.route;
        final next = navigation.nextStep;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 14,
            title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RoadVision', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21)),
              Text('ملاحة ثلاثية الأبعاد وكاميرا الطريق', style: TextStyle(fontSize: 10, color: Colors.white60)),
            ]),
            actions: [
              IconButton(
                tooltip: navigation.voice.enabled ? 'إيقاف الصوت' : 'تفعيل الإرشاد الصوتي',
                onPressed: navigation.toggleVoice,
                icon: Icon(navigation.voice.enabled ? Icons.volume_up : Icons.volume_off_outlined),
              ),
              IconButton(tooltip: 'إعدادات الكاميرا', onPressed: _cameraSettings,
                  icon: const Icon(Icons.settings_input_component)),
              IconButton(tooltip: 'عن التطبيق', onPressed: _showAbout,
                  icon: const Icon(Icons.info_outline)),
            ],
          ),
          body: SafeArea(child: Column(children: [
            _searchHeader(),
            if (navigation.busy) const LinearProgressIndicator(minHeight: 2),
            if (navigation.error != null) _errorBanner(navigation.error!),
            if (route != null && next != null) _instructionBanner(next),
            Expanded(child: mode == NavigationMode.map3d
                ? Map3dScreen(navigation: navigation)
                : ArCameraScreen(navigation: navigation,
                    preferences: _cameraPreferences, onSettings: _cameraSettings)),
            if (route != null) _routeControl(route),
            _modeSelector(),
          ])),
        );
      },
    );
  }

  Widget _searchHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    child: Row(children: [
      Expanded(child: Material(
        color: const Color(0xFF152C3C),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: navigation.busy ? null : _search,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(children: [
              const Icon(Icons.search, color: Color(0xFF38C7E2)),
              const SizedBox(width: 10),
              Expanded(child: Text(navigation.destination?.name ?? 'إلى أين تريد الذهاب؟',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14))),
            ])),
        ),
      )),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        tooltip: 'تحديد موقعي',
        onPressed: navigation.busy ? null : navigation.locate,
        icon: const Icon(Icons.my_location_rounded),
      ),
    ]),
  );

  Widget _errorBanner(String message) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF59372B),
        borderRadius: BorderRadius.circular(12)),
    child: Text(message, style: const TextStyle(fontSize: 12)),
  );

  Widget _instructionBanner(NavigationStep step) {
    final modifier = step.modifier.toLowerCase();
    final icon = modifier.contains('left') ? Icons.turn_left_rounded
        : modifier.contains('right') ? Icons.turn_right_rounded
        : step.maneuverType == 'arrive' ? Icons.flag_outlined
        : Icons.straight_rounded;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF124B65), Color(0xFF102F47)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(icon, size: 36, color: const Color(0xFF79E4FF)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.instruction, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(navigation.metersToNextStep == null
              ? 'انتظار تحديد الموقع'
              : 'المسافة المباشرة للتوجيه التالي: ${formatMeters(navigation.metersToNextStep!)} (تقديرية)',
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _routeControl(NavigationRoute route) => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    color: const Color(0xFF0F2231),
    child: Column(children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(formatDuration(route.durationSeconds),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          Text('${formatMeters(route.distanceMeters)} • تقدير وقت الرحلة من خدمة الطرق',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
        FilledButton.icon(
          onPressed: navigation.toggleGuidance,
          icon: Icon(navigation.guiding ? Icons.pause_circle : Icons.navigation_rounded),
          label: Text(navigation.guiding ? 'إيقاف التوجيه' : 'بدء التوجيه'),
        ),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton.icon(onPressed: navigation.recalculate,
          icon: const Icon(Icons.refresh, size: 17), label: const Text('تحديث الطريق')),
        TextButton.icon(onPressed: navigation.clearRoute,
          icon: const Icon(Icons.close, size: 17), label: const Text('مسح')),
      ]),
    ]),
  );

  Widget _modeSelector() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 9, 14, 12),
    child: SizedBox(width: double.infinity, child: SegmentedButton<NavigationMode>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.comfortable),
      segments: const [
        ButtonSegment(value: NavigationMode.map3d,
          icon: Icon(Icons.view_in_ar), label: Text('خرائط 3D')),
        ButtonSegment(value: NavigationMode.camera,
          icon: Icon(Icons.videocam_outlined), label: Text('كاميرا الطريق')),
      ],
      selected: {mode},
      onSelectionChanged: (selected) => setState(() => mode = selected.first),
    )),
  );
}
