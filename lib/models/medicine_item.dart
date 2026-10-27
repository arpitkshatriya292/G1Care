class MedicineItem {
  final String name;
  final String dosage;
  final String frequency;
  final String? instructions;

  const MedicineItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'instructions': instructions,
    };
  }

  factory MedicineItem.fromMap(Map<String, dynamic> map) {
    return MedicineItem(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      instructions: map['instructions'],
    );
  }

  MedicineItem copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? instructions,
  }) {
    return MedicineItem(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  String toString() => '$name ($dosage, $frequency)';
}
