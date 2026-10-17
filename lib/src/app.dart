import 'package:flutter/material.dart';
import 'features/shell/navigation_shell.dart';

class RoadVisionApp extends StatelessWidget {
  const RoadVisionApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'RoadVision | رؤية الطريق',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF08121D),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1AB4D2),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0D1B29)),
    ),
    home: const Directionality(
      textDirection: TextDirection.rtl,
      child: NavigationShell(),
    ),
  );
}
