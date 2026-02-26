/// Marker model - represents a map marker
class Marker {
  final int id;
  final int tripId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? notes;
  final String? link;
  final List<String> imagePaths;
  final int displayOrder;
  final DateTime createdAt;

  Marker({
    required this.id,
    required this.tripId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.link,
    List<String>? imagePaths,
    this.displayOrder = 0,
    DateTime? createdAt,
  })  : imagePaths = imagePaths ?? [],
        createdAt = createdAt ?? DateTime.now();

  Marker copyWith({
    int? id,
    int? tripId,
    String? title,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    String? link,
    List<String>? imagePaths,
    int? displayOrder,
    DateTime? createdAt,
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
      imagePaths: imagePaths ?? this.imagePaths,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format coordinates as string
  String get coordinateString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
