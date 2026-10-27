class HospitalAccount {
  final String id;
  final String hospitalName;
  final String registrationNumber;
  final String hospitalType; // Government, Private, Multi-specialty, Clinic / Other
  final String address;
  final String city;
  final String state;
  final String pinCode;
  final String officialPhone;
  final String officialEmail;
  final String adminName;
  final String adminPhone;
  final String verificationStatus; // Verified, Pending Verification, Rejected
  final DateTime createdAt;

  const HospitalAccount({
    required this.id,
    required this.hospitalName,
    required this.registrationNumber,
    required this.hospitalType,
    required this.address,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.officialPhone,
    required this.officialEmail,
    required this.adminName,
    required this.adminPhone,
    this.verificationStatus = 'Verified',
    required this.createdAt,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hospitalName': hospitalName,
      'registrationNumber': registrationNumber,
      'hospitalType': hospitalType,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'officialPhone': officialPhone,
      'officialEmail': officialEmail,
      'adminName': adminName,
      'adminPhone': adminPhone,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HospitalAccount.fromMap(Map<String, dynamic> map) {
    return HospitalAccount(
      id: map['id'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      hospitalType: map['hospitalType'] ?? 'Multi-specialty',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pinCode: map['pinCode'] ?? '',
      officialPhone: map['officialPhone'] ?? '',
      officialEmail: map['officialEmail'] ?? '',
      adminName: map['adminName'] ?? '',
      adminPhone: map['adminPhone'] ?? '',
      verificationStatus: map['verificationStatus'] ?? 'Verified',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Default curated demo verified hospital
  static final HospitalAccount demoHospital = HospitalAccount(
    id: 'PUNE-HOSP-001',
    hospitalName: 'Ruby Hall Clinic (Emergency Coordination Center)',
    registrationNumber: 'MAH-PUN-MED-2024-8891',
    hospitalType: 'Multi-specialty',
    address: '40 Sassoon Road, Pune Station Area',
    city: 'Pune',
    state: 'Maharashtra',
    pinCode: '411001',
    officialPhone: '+91 20 6645 5100',
    officialEmail: 'emergency@rubyhall.com',
    adminName: 'Suresh Nair (Hospital Administrator)',
    adminPhone: '+91 98220 54321',
    verificationStatus: 'Verified',
    createdAt: DateTime(2024, 1, 15),
  );
}
