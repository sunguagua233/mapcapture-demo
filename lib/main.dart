import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/trip_provider.dart';
import 'providers/marker_provider.dart';
import 'providers/map_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => MarkerProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
      ],
      child: const MapCaptureApp(),
    ),
  );
}
