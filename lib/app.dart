import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/trip_list_screen.dart';

class MapCaptureApp extends StatelessWidget {
  const MapCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapCapture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const TripListScreen(),
    );
  }
}
