import 'emergency_contact.dart';
import 'emergency_qr_payload.dart';
import 'medicine_item.dart';

class MedicalProfile {
  final String uid;
  final String medicalId;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String phone;
  final String address;
  final String emergencyContact; // Legacy string representation
  final EmergencyContactInfo emergencyContactInfo; // Structured contact
  final String bloodGroup;
  final List<String> allergies;
  final List<MedicineItem> medicines;
  final List<String> medicalConditions;
  final List<String> previousSurgeries;
  final List<String> previousIllnesses;
  final String emergencyNotes;
  final String primaryDoctor;
  final String lastUpdatedBy; // e.g. 'patient' or 'hospital:HOSPITAL_NAME'
  final DateTime updatedAt;

  MedicalProfile({
    required this.uid,
    required this.medicalId,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.phone,
    required this.address,
    required this.emergencyContact,
    required this.emergencyContactInfo,
    required this.bloodGroup,
    required this.allergies,
    required this.medicines,
    required this.medicalConditions,
    required this.previousSurgeries,
    required this.previousIllnesses,
    required this.emergencyNotes,
    required this.primaryDoctor,
    this.lastUpdatedBy = 'system',
    required this.updatedAt,
  });

  factory MedicalProfile.empty(String uid, String name, String phone, {String? medicalId}) {
    return MedicalProfile(
      uid: uid,
      medicalId: medicalId ?? '',
      fullName: name,
      dateOfBirth: 'Not specified',
      gender: 'Not specified',
      phone: phone,
      address: 'Not specified',
      emergencyContact: 'Not specified',
      emergencyContactInfo: EmergencyContactInfo.empty(),
      bloodGroup: 'Unknown',
      allergies: [],
      medicines: [],
      medicalConditions: [],
      previousSurgeries: [],
      previousIllnesses: [],
      emergencyNotes: 'No special emergency notes provided.',
      primaryDoctor: 'Not specified',
      lastUpdatedBy: 'system',
      updatedAt: DateTime.now(),
    );
  }

  /// Extracts the minimal, privacy-preserving emergency snapshot for offline QR triage
  EmergencyQrPayload toEmergencySnapshot({String? integrityTag}) {
    final effectivePhone = emergencyContactInfo.phone.isNotEmpty
        ? emergencyContactInfo.phone
        : (emergencyContact.isNotEmpty && emergencyContact != 'Not specified'
            ? emergencyContact
            : phone);

    return EmergencyQrPayload(
      medId: medicalId,
      name: fullName,
      bg: bloodGroup,
      alrg: allergies,
      cond: medicalConditions,
      emPhone: effectivePhone.isNotEmpty ? effectivePhone : 'Not specified',
      issuedAt: updatedAt.millisecondsSinceEpoch,
      integrityTag: integrityTag ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'medicalId': medicalId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyContactInfo': emergencyContactInfo.toMap(),
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'medicalConditions': medicalConditions,
      'previousSurgeries': previousSurgeries,
      'previousIllnesses': previousIllnesses,
      'emergencyNotes': emergencyNotes,
      'primaryDoctor': primaryDoctor,
      'lastUpdatedBy': lastUpdatedBy,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicalProfile.fromMap(Map<String, dynamic> map) {
    // Parse medicines backward-compatibly (supporting both string lists and structured maps)
    List<MedicineItem> parsedMedicines = [];
    if (map['medicines'] != null) {
      for (var item in (map['medicines'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedMedicines.add(MedicineItem.fromMap(item));
        } else if (item is String) {
          parsedMedicines.add(MedicineItem(
            name: item,
            dosage: 'As prescribed',
            frequency: 'Daily',
          ));
        }
      }
    }

    // Parse emergency contact backward-compatibly
    EmergencyContactInfo parsedContact;
    if (map['emergencyContactInfo'] != null &&
        map['emergencyContactInfo'] is Map<String, dynamic>) {
      parsedContact = EmergencyContactInfo.fromMap(
          map['emergencyContactInfo'] as Map<String, dynamic>);
    } else {
      parsedContact = EmergencyContactInfo(
        name: map['emergencyContact'] ?? 'Emergency Contact',
        phone: map['emergencyContact'] ?? '',
        relationship: 'Emergency Contact',
      );
    }

    return MedicalProfile(
      uid: map['uid'] ?? '',
      medicalId: map['medicalId'] ?? '',
      fullName: map['fullName'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      emergencyContactInfo: parsedContact,
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      allergies: List<String>.from(map['allergies'] ?? []),
      medicines: parsedMedicines,
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      previousSurgeries: List<String>.from(map['previousSurgeries'] ?? []),
      previousIllnesses: List<String>.from(map['previousIllnesses'] ?? []),
      emergencyNotes: map['emergencyNotes'] ?? '',
      primaryDoctor: map['primaryDoctor'] ?? '',
      lastUpdatedBy: map['lastUpdatedBy'] ?? 'system',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Patient-only update: Strictly updates personal & ICE contact data, preserving all hospital medical data
  MedicalProfile copyWithPatientDetails({
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? address,
    EmergencyContactInfo? emergencyContactInfo,
  }) {
    return copyWith(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      phone: phone,
      address: address,
      emergencyContact: emergencyContactInfo?.phone ?? emergencyContact,
      emergencyContactInfo: emergencyContactInfo,
      lastUpdatedBy: 'patient',
      updatedAt: DateTime.now(),
    );
  }

  /// Hospital-only update: Updates clinical and emergency medical data
  MedicalProfile copyWithHospitalMedicalData({
    String? bloodGroup,
    List<String>? allergies,
    List<MedicineItem>? medicines,
    List<String>? medicalConditions,
    List<String>? previousSurgeries,
    List<String>? previousIllnesses,
    String? emergencyNotes,
    String? primaryDoctor,
    String? hospitalTag,
  }) {
    String tag = 'hospital';
    if (hospitalTag != null && hospitalTag.isNotEmpty) {
      if (hospitalTag.startsWith('hospital (')) {
        tag = hospitalTag;
      } else if (hospitalTag.startsWith('hospital:')) {
        tag = 'hospital (${hospitalTag.substring(9)})';
      } else if (hospitalTag.startsWith('hospital')) {
        tag = hospitalTag;
      } else {
        tag = 'hospital ($hospitalTag)';
      }
    }
    return copyWith(
      bloodGroup: bloodGroup,
      allergies: allergies,
      medicines: medicines,
      medicalConditions: medicalConditions,
      previousSurgeries: previousSurgeries,
      previousIllnesses: previousIllnesses,
      emergencyNotes: emergencyNotes,
      primaryDoctor: primaryDoctor,
      lastUpdatedBy: tag,
      updatedAt: DateTime.now(),
    );
  }

  MedicalProfile copyWith({
    String? uid,
    String? medicalId,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? phone,
    String? address,
    String? emergencyContact,
    EmergencyContactInfo? emergencyContactInfo,
    String? bloodGroup,
    List<String>? allergies,
    List<MedicineItem>? medicines,
    List<String>? medicalConditions,
    List<String>? previousSurgeries,
    List<String>? previousIllnesses,
    String? emergencyNotes,
    String? primaryDoctor,
    String? lastUpdatedBy,
    DateTime? updatedAt,
  }) {
    return MedicalProfile(
      uid: uid ?? this.uid,
      medicalId: medicalId ?? this.medicalId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactInfo: emergencyContactInfo ?? this.emergencyContactInfo,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicines: medicines ?? this.medicines,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      previousSurgeries: previousSurgeries ?? this.previousSurgeries,
      previousIllnesses: previousIllnesses ?? this.previousIllnesses,
      emergencyNotes: emergencyNotes ?? this.emergencyNotes,
      primaryDoctor: primaryDoctor ?? this.primaryDoctor,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
