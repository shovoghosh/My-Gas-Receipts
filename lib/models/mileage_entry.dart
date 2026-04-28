class MileageEntry {
  final int? id;
  final int? vehicleId;
  final DateTime date;
  final double startOdometer;
  final double endOdometer;
  final String? purpose;
  final String? notes;
  final DateTime createdAt;

  MileageEntry({
    this.id,
    this.vehicleId,
    required this.date,
    required this.startOdometer,
    required this.endOdometer,
    this.purpose,
    this.notes,
    required this.createdAt,
  });

  double get miles => endOdometer - startOdometer;

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicleId': vehicleId,
        'date': date.toIso8601String(),
        'startOdometer': startOdometer,
        'endOdometer': endOdometer,
        'purpose': purpose,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MileageEntry.fromMap(Map<String, dynamic> map) => MileageEntry(
        id: map['id'] as int?,
        vehicleId: map['vehicleId'] as int?,
        date: DateTime.parse(map['date'] as String),
        startOdometer: (map['startOdometer'] as num).toDouble(),
        endOdometer: (map['endOdometer'] as num).toDouble(),
        purpose: map['purpose'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  MileageEntry copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    double? startOdometer,
    double? endOdometer,
    String? purpose,
    String? notes,
    DateTime? createdAt,
  }) {
    return MileageEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      startOdometer: startOdometer ?? this.startOdometer,
      endOdometer: endOdometer ?? this.endOdometer,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
