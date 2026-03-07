import 'core/utils/uuid_helper.dart';
import 'core/utils/date_helper.dart';

class Trip {
  final String id;
  final String name;
  final String? coverImagePath;
  final DateTime? startDate;
  final DateTime? endDate;
  final int displayOrder;
  final DateTime createdAt;

  // Associated data (not stored in database)
  final int markerCount;

  const Trip({
    required this.id,
    required this.name,
    this.coverImagePath,
    this.startDate,
    this.endDate,
    required this.displayOrder,
    required this.createdAt,
    this.markerCount = 0,
  });

  Trip copyWith({
    String? id,
    String? name,
    String? coverImagePath,
    DateTime? startDate,
    DateTime? endDate,
    int? displayOrder,
    DateTime? createdAt,
    int? markerCount,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      markerCount: markerCount ?? this.markerCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cover_image_path': coverImagePath,
      'start_date': startDate != null ? DateHelper.toUnixTimestamp(startDate!) : null,
      'end_date': endDate != null ? DateHelper.toUnixTimestamp(endDate!) : null,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
      'marker_count': markerCount,
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      name: json['name'] as String,
      coverImagePath: json['cover_image_path'] as String?,
      startDate: json['start_date'] != null
          ? DateHelper.fromUnixTimestamp(json['start_date'] as int)
          : null,
      endDate: json['end_date'] != null
          ? DateHelper.fromUnixTimestamp(json['end_date'] as int)
          : null,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(json['created_at'] as int),
      markerCount: json['marker_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'name': name,
      'cover_image_path': coverImagePath,
      'start_date': startDate != null ? DateHelper.toUnixTimestamp(startDate!) : null,
      'end_date': endDate != null ? DateHelper.toUnixTimestamp(endDate!) : null,
      'display_order': displayOrder,
      'created_at': DateHelper.toUnixTimestamp(createdAt),
    };
  }

  factory Trip.fromDbMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      name: map['name'] as String,
      coverImagePath: map['cover_image_path'] as String?,
      startDate: map['start_date'] != null
          ? DateHelper.fromUnixTimestamp(map['start_date'] as int)
          : null,
      endDate: map['end_date'] != null
          ? DateHelper.fromUnixTimestamp(map['end_date'] as int)
          : null,
      displayOrder: map['display_order'] as int? ?? 0,
      createdAt: DateHelper.fromUnixTimestamp(map['created_at'] as int),
    );
  }

  /// Create a new Trip with generated ID and timestamp
  factory Trip.create({
    required String name,
    String? coverImagePath,
    DateTime? startDate,
    DateTime? endDate,
    int? displayOrder,
  }) {
    final now = DateTime.now();
    return Trip(
      id: UuidHelper.generate(),
      name: name,
      coverImagePath: coverImagePath,
      startDate: startDate,
      endDate: endDate,
      displayOrder: displayOrder ?? 0,
      createdAt: now,
    );
  }

  String get durationDisplay => DateHelper.getDurationString(startDate, endDate);

  bool get isValid {
    if (startDate != null && endDate != null) {
      return !endDate!.isBefore(startDate!);
    }
    return true;
  }
}
