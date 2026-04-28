class Receipt {
  final int? id;
  final String imagePath;
  final double? amount;
  final DateTime date;
  final String? stationName;
  final String? notes;
  final DateTime createdAt;

  Receipt({
    this.id,
    required this.imagePath,
    this.amount,
    required this.date,
    this.stationName,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'amount': amount,
        'date': date.toIso8601String(),
        'stationName': stationName,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
        id: map['id'] as int?,
        imagePath: map['imagePath'] as String,
        amount: (map['amount'] as num?)?.toDouble(),
        date: DateTime.parse(map['date'] as String),
        stationName: map['stationName'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  Receipt copyWith({
    int? id,
    String? imagePath,
    double? amount,
    DateTime? date,
    String? stationName,
    String? notes,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      stationName: stationName ?? this.stationName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
