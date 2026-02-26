/// Trip model - represents a travel trip
class Trip {
  final int id;
  final String name;
  final String? coverImagePath;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int displayOrder;

  Trip({
    required this.id,
    required this.name,
    this.coverImagePath,
    DateTime? createdAt,
    this.startDate,
    this.endDate,
    this.displayOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Trip copyWith({
    int? id,
    String? name,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? displayOrder,
  }) {
    return Trip(
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
