class EmergencyContactInfo {
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;

  const EmergencyContactInfo({
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = true,
  });

  factory EmergencyContactInfo.empty() {
    return EmergencyContactInfo(
      name: '',
      phone: '',
      relationship: 'Emergency Contact',
      isPrimary: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isPrimary': isPrimary,
    };
  }

  factory EmergencyContactInfo.fromMap(Map<String, dynamic> map) {
    return EmergencyContactInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? 'Emergency Contact',
      isPrimary: map['isPrimary'] ?? true,
    );
  }

  EmergencyContactInfo copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
  }) {
    return EmergencyContactInfo(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
