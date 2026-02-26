import 'package:mapcapture/data/database/database.dart';

/// Image entity for domain layer
class ImageEntity {
  final int? id;
  final int markerId;
  final String filePath;
  final int displayOrder;
  final DateTime? createdAt;

  ImageEntity({
    this.id,
    required this.markerId,
    required this.filePath,
    this.displayOrder = 0,
    this.createdAt,
  });

  /// Convert from database model
  factory ImageEntity.fromImage(MarkerImage image) {
    return ImageEntity(
      id: image.id,
      markerId: image.markerId,
      filePath: image.filePath,
      displayOrder: image.displayOrder,
      createdAt: image.createdAt,
    );
  }

  /// Convert to database companion for insert/update
  ImagesCompanion toCompanion() {
    return ImagesCompanion(
      id: id == null ? const Absent() : Value(id!),
      markerId: Value(markerId),
      filePath: Value(filePath),
      displayOrder: Value(displayOrder),
      createdAt: createdAt == null
          ? const Value.absent()
          : Value(createdAt!),
    );
  }

  /// Copy with method
  ImageEntity copyWith({
    int? id,
    int? markerId,
    String? filePath,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return ImageEntity(
      id: id ?? this.id,
      markerId: markerId ?? this.markerId,
      filePath: filePath ?? this.filePath,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
