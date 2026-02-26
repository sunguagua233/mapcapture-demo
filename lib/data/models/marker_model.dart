import 'package:mapcapture/data/database/database.dart';

/// Marker entity for domain layer
class MarkerEntity {
  final int? id;
  final int tripId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? link;
  final int displayOrder;
  final DateTime? createdAt;

  MarkerEntity({
    this.id,
    required this.tripId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.link,
    this.displayOrder = 0,
    this.createdAt,
  });

  /// Convert from database model
  factory MarkerEntity.fromMarker(TripMarker marker) {
    return MarkerEntity(
      id: marker.id,
      tripId: marker.tripId,
      title: marker.title,
      address: marker.address,
      latitude: marker.latitude,
      longitude: marker.longitude,
      notes: marker.notes,
      link: marker.link,
      displayOrder: marker.displayOrder,
      createdAt: marker.createdAt,
    );
  }

  /// Convert to database companion for insert/update
  MarkersCompanion toCompanion() {
    return MarkersCompanion(
      id: id == null ? const Absent() : Value(id!),
      tripId: Value(tripId),
      title: Value(title),
      address: Value(address),
      latitude: Value(latitude),
      longitude: Value(longitude),
      notes: notes == null ? const Value.absent() : Value(notes!),
      link: link == null ? const Value.absent() : Value(link!),
      displayOrder: Value(displayOrder),
      createdAt: createdAt == null
          ? const Value.absent()
          : Value(createdAt!),
    );
  }

  /// Copy with method
  MarkerEntity copyWith({
    int? id,
    int? tripId,
    String? title,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    String? link,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return MarkerEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      title: title ?? this.title,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      link: link ?? this.link,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Marker with images entity
class MarkerWithImagesEntity {
  final MarkerEntity marker;
  final List<ImageEntity> images;

  MarkerWithImagesEntity({
    required this.marker,
    required this.images,
  });
}
