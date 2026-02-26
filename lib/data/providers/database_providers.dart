import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapcapture/data/database/database.dart';
import 'package:mapcapture/data/repositories/image_repository.dart';
import 'package:mapcapture/data/repositories/marker_repository.dart';
import 'package:mapcapture/data/repositories/trip_repository.dart';

/// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.getInstance();
});

/// Trip repository provider
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return TripRepositoryImpl(database);
});

/// Marker repository provider
final markerRepositoryProvider = Provider<MarkerRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return MarkerRepositoryImpl(database);
});

/// Image repository provider
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return ImageRepositoryImpl(database);
});
