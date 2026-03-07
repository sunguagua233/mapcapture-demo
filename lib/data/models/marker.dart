import 'core/utils/uuid_helper.dart';
import 'core/utils/date_helper.dart';

class Marker {
  final String id;
  final String tripId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? link;
  final int displayOrder;
  final DateTime createdAt;

  // Extended fields
  final String? category;
  final String color;

  // Associated data (not stored in database)
  final List<MarkerImage> images;

  const Marker({
    required this.id,
    required this.tripId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.link,
    required this.displayOrder,
    required this.createdAt,
    this.category,
    this.color = '#FF5722',
    this.images = const [],
  });

  Marker copyWith({
    String? id,
    String? tripId,
    String? title,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    String? link,
    int? displayOrder,
    DateTime? createdAt,
    String? category,
    String? color,
    List<MarkerImage>? images,
  }) {
    return Marker(
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
      category: category ?? this.category,
      color: color ?? this.color,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'link': link,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
      'category': category,
      'color': color,
      'images': images.map((e) => e.toJson()).toList(),
    };
  }

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      notes: json['notes'] as String?,
      link: json['link'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(json['created_at'] as int),
      category: json['category'] as String?,
      color: json['color'] as String? ?? '#FF5722',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => MarkerImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'title': title,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'link': link,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
      'category': category,
      'color': color,
    };
  }

  factory Marker.fromDbMap(Map<String, dynamic> map) {
    return Marker(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      title: map['title'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      notes: map['notes'] as String?,
      link: map['link'] as String?,
      displayOrder: map['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(map['created_at'] as int),
      category: map['category'] as String?,
      color: map['color'] as String? ?? '#FF5722',
    );
  }

  /// Create a new Marker with generated ID and timestamp
  factory Marker.create({
    required String tripId,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
    String? notes,
    String? link,
    int? displayOrder,
    String? category,
    String? color,
  }) {
    final now = DateTime.now();
    return Marker(
      id: UuidHelper.generate(),
      tripId: tripId,
      title: title,
      address: address,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      link: link,
      displayOrder: displayOrder ?? 0,
      createdAt: now,
      category: category,
      color: color ?? '#FF5722',
    );
  }

  bool get isValid {
    return title.trim().isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  String getCoordinatesString() {
    return '$latitude, $longitude';
  }
}

/// Marker image model
class MarkerImage {
  final String id;
  final String markerId;
  final String filePath;
  final int displayOrder;
  final DateTime createdAt;

  const MarkerImage({
    required this.id,
    required this.markerId,
    required this.filePath,
    required this.displayOrder,
    required this.createdAt,
  });

  MarkerImage copyWith({
    String? id,
    String? markerId,
    String? filePath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return MarkerImage(
      id: id ?? this.id,
      markerId: markerId ?? this.markerId,
      filePath: filePath ?? this.filePath,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marker_id': markerId,
      'file_path': filePath,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
    };
  }

  factory MarkerImage.fromJson(Map<String, dynamic> json) {
    return MarkerImage(
      id: json['id'] as String,
      markerId: json['marker_id'] as String,
      filePath: json['file_path'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'marker_id': markerId,
      'file_path': filePath,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
    };
  }

  factory MarkerImage.fromDbMap(Map<String, dynamic> map) {
    return MarkerImage(
      id: map['id'] as String,
      markerId: map['marker_id'] as String,
      filePath: map['file_path'] as String,
      displayOrder: map['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(map['created_at'] as int),
    );
  }

  /// Create a new MarkerImage with generated ID and timestamp
  factory MarkerImage.create({
    required String markerId,
    required String filePath,
    int? displayOrder,
  }) {
    final now = DateTime.now();
    return MarkerImage(
      id: UuidHelper.generate(),
      markerId: markerId,
      filePath: filePath,
      displayOrder: displayOrder ?? 0,
      createdAt: now,
    );
  }
}
