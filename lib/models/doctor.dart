import '../core/constants/app_constants.dart';

class DoctorUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String medicalRegistrationNumber;
  final String specialization;
  final String hospital;
  final DoctorVerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DoctorUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role = UserRole.doctor,
    required this.medicalRegistrationNumber,
    required this.specialization,
    required this.hospital,
    this.verificationStatus = DoctorVerificationStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isApproved => verificationStatus == DoctorVerificationStatus.approved;
  bool get isPending => verificationStatus == DoctorVerificationStatus.pending;
  bool get isRejected => verificationStatus == DoctorVerificationStatus.rejected;
  bool get isSuspended => verificationStatus == DoctorVerificationStatus.suspended;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'medicalRegistrationNumber': medicalRegistrationNumber,
      'specialization': specialization,
      'hospital': hospital,
      'verificationStatus': verificationStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory DoctorUser.fromMap(Map<String, dynamic> map) {
    DoctorVerificationStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'approved':
          return DoctorVerificationStatus.approved;
        case 'rejected':
          return DoctorVerificationStatus.rejected;
        case 'suspended':
          return DoctorVerificationStatus.suspended;
        default:
          return DoctorVerificationStatus.pending;
      }
    }

    return DoctorUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.doctor,
      medicalRegistrationNumber: map['medicalRegistrationNumber'] ?? '',
      specialization: map['specialization'] ?? '',
      hospital: map['hospital'] ?? '',
      verificationStatus: parseStatus(map['verificationStatus']),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }

  DoctorUser copyWith({
    String? name,
    String? phone,
    String? medicalRegistrationNumber,
    String? specialization,
    String? hospital,
    DoctorVerificationStatus? verificationStatus,
    DateTime? updatedAt,
  }) {
    return DoctorUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      medicalRegistrationNumber:
          medicalRegistrationNumber ?? this.medicalRegistrationNumber,
      specialization: specialization ?? this.specialization,
      hospital: hospital ?? this.hospital,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
