import 'package:mapcapture/data/database/database.dart';

/// Trip entity for domain layer
class TripEntity {
  final int? id;
  final String name;
  final String? coverImagePath;
  final DateTime? createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int displayOrder;

  TripEntity({
    this.id,
    required this.name,
    this.coverImagePath,
    this.createdAt,
    this.startDate,
    this.endDate,
    this.displayOrder = 0,
  });

  /// Convert from database model
  factory TripEntity.fromTrip(Trip trip) {
    return TripEntity(
      id: trip.id,
      name: trip.name,
      coverImagePath: trip.coverImagePath,
      createdAt: trip.createdAt,
      startDate: trip.startDate,
      endDate: trip.endDate,
      displayOrder: trip.displayOrder,
    );
  }

  /// Convert to database companion for insert/update
  TripsCompanion toCompanion() {
    return TripsCompanion(
      id: id == null ? const Absent() : Value(id!),
      name: Value(name),
      coverImagePath: coverImagePath == null
          ? const Value.absent()
          : Value(coverImagePath!),
      createdAt: createdAt == null
          ? const Value.absent()
          : Value(createdAt!),
      startDate: startDate == null
          ? const Value.absent()
          : Value(startDate!),
      endDate: endDate == null ? const Value.absent() : Value(endDate!),
      displayOrder: Value(displayOrder),
    );
  }

  /// Copy with method
  TripEntity copyWith({
    int? id,
    String? name,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? displayOrder,
  }) {
    return TripEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
