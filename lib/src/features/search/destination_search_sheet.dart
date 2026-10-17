import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../domain/navigation_route.dart';
import '../../services/navigation_controller.dart';

class DestinationSearchSheet extends StatefulWidget {
  const DestinationSearchSheet({super.key, required this.navigation});
  final NavigationController navigation;

  @override
  State<DestinationSearchSheet> createState() => _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends State<DestinationSearchSheet> {
  final TextEditingController _text = TextEditingController();
  Timer? _timer;
  int _generation = 0;
  List<Destination> _results = const [];
  bool _busy = false;
  String? _error;

  void _onQuery(String value) {
    _timer?.cancel();
    final generation = ++_generation;
    if (value.trim().length < 2) {
      setState(() { _results = []; _error = null; _busy = false; });
      return;
    }
    _timer = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() { _busy = true; _error = null; });
      try {
        final result = await widget.navigation.api.search(
          value,
          proximity: widget.navigation.pose?.location,
        );
        if (!mounted || generation != _generation) return;
        setState(() { _results = result; _busy = false; });
      } catch (e) {
        if (!mounted || generation != _generation) return;
        setState(() { _error = '$e'; _busy = false; });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(
              color: Colors.white30, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _text,
                autofocus: true,
                enabled: AppConfig.hasMapboxToken,
                onChanged: _onQuery,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مدينة، شارع أو عنوان',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'مسح', onPressed: () { _text.clear(); _onQuery(''); },
                    icon: const Icon(Icons.clear),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (!AppConfig.hasMapboxToken)
              const Padding(padding: EdgeInsets.all(24),
                child: Text('أضف MAPBOX_PUBLIC_TOKEN لتشغيل البحث عن الوجهات.')),
            if (_error != null) Padding(padding: const EdgeInsets.all(18),
              child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
            Expanded(child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(item.name),
                  subtitle: Text(item.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).pop(item),
                );
              },
            )),
            if (_results.isEmpty && _error == null && !_busy && AppConfig.hasMapboxToken)
              const Padding(padding: EdgeInsets.all(16),
                  child: Text('اكتب اسم الوجهة لعرض نتائج البحث')),
          ]),
        ),
      ),
    );
  }
}
