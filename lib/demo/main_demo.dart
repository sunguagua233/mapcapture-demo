import 'package:flutter/material.dart';

import 'models/trip.dart';
import 'models/marker.dart';
import 'screens/trip_list_screen.dart';

void main() {
  runApp(const MapCaptureDemo());
}

class MapCaptureDemo extends StatelessWidget {
  const MapCaptureDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MapCapture Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TripListScreen(),
    );
  }
}
