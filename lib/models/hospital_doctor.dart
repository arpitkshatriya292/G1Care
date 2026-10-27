class HospitalDoctor {
  final String id;
  final String name;
  final String medicalRegistrationNumber;
  final String specialty;
  final String department;
  final String role;
  final String phone;
  final String email;
  final int yearsOfExperience;
  final String joiningDate;
  final bool isVerified;

  const HospitalDoctor({
    required this.id,
    required this.name,
    required this.medicalRegistrationNumber,
    required this.specialty,
    required this.department,
    required this.role,
    required this.phone,
    required this.email,
    required this.yearsOfExperience,
    required this.joiningDate,
    this.isVerified = true,
  });

  HospitalDoctor copyWith({
    String? id,
    String? name,
    String? medicalRegistrationNumber,
    String? specialty,
    String? department,
    String? role,
    String? phone,
    String? email,
    int? yearsOfExperience,
    String? joiningDate,
    bool? isVerified,
  }) {
    return HospitalDoctor(
      id: id ?? this.id,
      name: name ?? this.name,
      medicalRegistrationNumber: medicalRegistrationNumber ?? this.medicalRegistrationNumber,
      specialty: specialty ?? this.specialty,
      department: department ?? this.department,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      joiningDate: joiningDate ?? this.joiningDate,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'medicalRegistrationNumber': medicalRegistrationNumber,
      'specialty': specialty,
      'department': department,
      'role': role,
      'phone': phone,
      'email': email,
      'yearsOfExperience': yearsOfExperience,
      'joiningDate': joiningDate,
      'isVerified': isVerified,
    };
  }

  factory HospitalDoctor.fromMap(Map<String, dynamic> map) {
    return HospitalDoctor(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Doctor',
      medicalRegistrationNumber: map['medicalRegistrationNumber'] as String? ?? '',
      specialty: map['specialty'] as String? ?? 'General Medicine',
      department: map['department'] as String? ?? 'Emergency',
      role: map['role'] as String? ?? 'Physician',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      yearsOfExperience: (map['yearsOfExperience'] as num?)?.toInt() ?? 0,
      joiningDate: map['joiningDate'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
    );
  }

  /// 5 Fictional Demo Doctors for Prototype Testing (Matching Exact Milestone 7 Specification)
  static const List<HospitalDoctor> demoDoctors = [
    HospitalDoctor(
      id: 'DOC-PUN-001',
      name: 'Dr. Alex Sharma',
      medicalRegistrationNumber: 'MMC-2015-88421',
      specialty: 'Emergency Medicine',
      department: 'Emergency Department',
      role: 'Chief Emergency Physician',
      phone: '+91 98230 11001',
      email: 'dr.alex.sharma@rubyhall.demo',
      yearsOfExperience: 11,
      joiningDate: '12 Jan 2018',
      isVerified: true,
    ),
    HospitalDoctor(
      id: 'DOC-PUN-002',
      name: 'Dr. Priya Deshmukh',
      medicalRegistrationNumber: 'MMC-2017-45912',
      specialty: 'Cardiology',
      department: 'Cardiology',
      role: 'Senior Cardiologist',
      phone: '+91 98230 11002',
      email: 'dr.priya.deshmukh@rubyhall.demo',
      yearsOfExperience: 9,
      joiningDate: '05 Mar 2020',
      isVerified: true,
    ),
    HospitalDoctor(
      id: 'DOC-PUN-003',
      name: 'Dr. Rahul Mehta',
      medicalRegistrationNumber: 'MMC-2012-10823',
      specialty: 'General Medicine',
      department: 'General Medicine',
      role: 'Senior Physician & Critical Care',
      phone: '+91 98230 11003',
      email: 'dr.rahul.mehta@rubyhall.demo',
      yearsOfExperience: 14,
      joiningDate: '18 Aug 2016',
      isVerified: true,
    ),
    HospitalDoctor(
      id: 'DOC-PUN-004',
      name: 'Dr. Sneha Patil',
      medicalRegistrationNumber: 'MMC-2019-33109',
      specialty: 'Neurology',
      department: 'Neurology',
      role: 'Consultant Neurologist',
      phone: '+91 98230 11004',
      email: 'dr.sneha.patil@rubyhall.demo',
      yearsOfExperience: 7,
      joiningDate: '10 Nov 2021',
      isVerified: true,
    ),
    HospitalDoctor(
      id: 'DOC-PUN-005',
      name: 'Dr. Amit Kulkarni',
      medicalRegistrationNumber: 'MMC-2022-77234',
      specialty: 'Orthopedics',
      department: 'Orthopedics',
      role: 'Trauma & Orthopedic Specialist',
      phone: '+91 98230 11005',
      email: 'dr.amit.kulkarni@rubyhall.demo',
      yearsOfExperience: 4,
      joiningDate: '01 Feb 2024',
      isVerified: false, // UNVERIFIED DEMO DOCTOR
    ),
  ];
}
