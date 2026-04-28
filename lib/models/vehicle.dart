class Vehicle {
  final int? id;
  final String name;
  final String? make;
  final String? model;
  final int? year;
  final bool isDefault;

  Vehicle({
    this.id,
    required this.name,
    this.make,
    this.model,
    this.year,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'make': make,
        'model': model,
        'year': year,
        'isDefault': isDefault ? 1 : 0,
      };

  factory Vehicle.fromMap(Map<String, dynamic> map) => Vehicle(
        id: map['id'] as int?,
        name: map['name'] as String,
        make: map['make'] as String?,
        model: map['model'] as String?,
        year: map['year'] as int?,
        isDefault: (map['isDefault'] as int?) == 1,
      );

  Vehicle copyWith({
    int? id,
    String? name,
    String? make,
    String? model,
    int? year,
    bool? isDefault,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
