import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/core/constants/app_constants.dart';
import 'package:g1care/models/emergency_contact.dart';
import 'package:g1care/models/medical_profile.dart';
import 'package:g1care/models/medicine_item.dart';
import 'package:g1care/providers/auth_provider.dart';
import 'package:g1care/services/firestore_service.dart';
import 'package:g1care/services/medical_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 3: Doctor QR Scanner, Triage & Medical Profile Tests', () {
    test('1. Valid G1Care QR payload parsing and triage snapshot extraction', () {
      final profile = MedicalProfile(
        uid: 'PATIENT-TRIAGE-01',
        medicalId: 'G1-MED-2026-TR1099',
        fullName: 'Aarav Sharma',
        dateOfBirth: '1988-11-20',
        gender: 'Male',
        phone: '+91 9876543210',
        address: '77 Residency Rd, Bengaluru',
        emergencyContact: '+91 9988776655',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Pooja Sharma',
          phone: '+91 9988776655',
          relationship: 'Spouse',
        ),
        bloodGroup: 'B+',
        allergies: ['Penicillin', 'Sulfa Drugs'],
        medicines: [
          MedicineItem(name: 'Atorvastatin', dosage: '20mg', frequency: 'Nightly'),
        ],
        medicalConditions: ['Coronary Artery Disease', 'Hypertension'],
        previousSurgeries: ['Stent Angioplasty 2021'],
        previousIllnesses: ['Pneumonia 2019'],
        emergencyNotes: 'High cardiac risk. Administer aspirin immediately if acute chest pain.',
        primaryDoctor: 'Dr. Vikram Patel',
        updatedAt: DateTime.parse('2026-08-18T12:00:00.000Z'),
      );

      final qrString = MedicalIdService.generateQrString(profile);
      final verification = MedicalIdService.verifyQrPayload(qrString);

      expect(verification.isValid, isTrue);
      expect(verification.error, isNull);

      final payload = verification.payload!;
      expect(payload.medId, 'G1-MED-2026-TR1099');
      expect(payload.name, 'Aarav Sharma');
      expect(payload.bg, 'B+');
      expect(payload.alrg, contains('Penicillin'));
      expect(payload.alrg, contains('Sulfa Drugs'));
      expect(payload.cond, contains('Coronary Artery Disease'));
      expect(payload.emPhone, '+91 9988776655');
      expect(payload.integrityTag, isNotEmpty);
    });

    test('2. Invalid & Malformed QR Payload Rejection', () {
      // Non-JSON string
      final res1 = MedicalIdService.verifyQrPayload('THIS_IS_NOT_A_VALID_QR_CODE');
      expect(res1.isValid, isFalse);
      expect(res1.payload, isNull);
      expect(res1.error, contains('Invalid QR payload format'));

      // Empty JSON object
      final res2 = MedicalIdService.verifyQrPayload('{}');
      expect(res2.isValid, isFalse);
      expect(res2.error, contains('Missing Medical ID'));

      // JSON missing Medical ID
      final res3 = MedicalIdService.verifyQrPayload(jsonEncode({
        'schema': 'g1/v1',
        'name': 'No Med ID',
        'bg': 'O+',
      }));
      expect(res3.isValid, isFalse);
      expect(res3.error, contains('Missing Medical ID'));
    });

    test('3. Cryptographic HMAC Prototype Integrity & Tamper Detection', () {
      final profile = MedicalProfile.empty(
        'UID-SEC-01',
        'Siddharth Roy',
        '+919000000001',
        medicalId: 'G1-MED-2026-SEC001',
      ).copyWith(
        bloodGroup: 'AB+',
        allergies: ['Morphine'],
        medicalConditions: ['Asthma'],
      );

      final validQr = MedicalIdService.generateQrString(profile);

      // Scenario A: Tamper Blood Group from AB+ to O-
      final mapA = jsonDecode(validQr) as Map<String, dynamic>;
      mapA['bg'] = 'O-';
      final tamperedA = MedicalIdService.verifyQrPayload(jsonEncode(mapA));
      expect(tamperedA.isValid, isFalse);
      expect(tamperedA.error, contains('Integrity verification failed'));

      // Scenario B: Tamper Emergency Phone Number
      final mapB = jsonDecode(validQr) as Map<String, dynamic>;
      mapB['emPhone'] = '+910000000000';
      final tamperedB = MedicalIdService.verifyQrPayload(jsonEncode(mapB));
      expect(tamperedB.isValid, isFalse);
      expect(tamperedB.error, contains('Integrity verification failed'));

      // Scenario C: Tamper Allergies list
      final mapC = jsonDecode(validQr) as Map<String, dynamic>;
      mapC['alrg'] = ['No Allergies'];
      final tamperedC = MedicalIdService.verifyQrPayload(jsonEncode(mapC));
      expect(tamperedC.isValid, isFalse);
      expect(tamperedC.error, contains('Integrity verification failed'));
    });

    test('4. Medical ID Format Validation', () {
      final validId1 = MedicalIdService.generateMedicalId(year: 2026);
      expect(RegExp(r'^G1-MED-2026-[A-Z2-9]{6}$').hasMatch(validId1), isTrue);

      final validId2 = 'G1-MED-2025-BCDFGH';
      expect(RegExp(r'^G1-MED-\d{4}-[A-Z0-9]{6}$').hasMatch(validId2), isTrue);

      final invalidId = 'RANDOM-12345';
      expect(RegExp(r'^G1-MED-\d{4}-[A-Z0-9]{6}$').hasMatch(invalidId), isFalse);
    });

    test('5. Patient Lookup by Medical ID (Online vs Offline/Cached source)', () async {
      final firestoreService = FirestoreService();

      final profile = MedicalProfile(
        uid: 'UID-LOOKUP-01',
        medicalId: 'G1-MED-2026-LOOKUP',
        fullName: 'Meera Nambiar',
        dateOfBirth: '1992-04-15',
        gender: 'Female',
        phone: '+91 9845012345',
        address: '5th Cross, Indiranagar',
        emergencyContact: '+91 9845099999',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Kiran Nambiar',
          phone: '+91 9845099999',
          relationship: 'Brother',
        ),
        bloodGroup: 'A+',
        allergies: ['Aspirin'],
        medicines: [],
        medicalConditions: ['Migraine'],
        previousSurgeries: [],
        previousIllnesses: [],
        emergencyNotes: 'Severe migraine aura.',
        primaryDoctor: 'Dr. Anita Roy',
        updatedAt: DateTime.now(),
      );

      // Save profile
      await firestoreService.saveMedicalProfile(profile);

      // Step A: Lookup by Medical ID from in-memory / cache
      final result1 = await firestoreService.fetchProfileWithSourceByMedicalId('G1-MED-2026-LOOKUP');
      expect(result1.profile, isNotNull);
      expect(result1.profile?.fullName, 'Meera Nambiar');
      expect(result1.profile?.bloodGroup, 'A+');
      expect(result1.profile?.allergies, contains('Aspirin'));

      // Step B: Simulate app restart / cold cache
      FirestoreService.clearInMemoryCacheForTesting();

      // Step C: Fallback lookup from persistent SharedPreferences
      final result2 = await firestoreService.fetchProfileWithSourceByMedicalId('G1-MED-2026-LOOKUP');
      expect(result2.profile, isNotNull);
      expect(result2.profile?.fullName, 'Meera Nambiar');
      expect(result2.source, ProfileDataSource.localCache);
      expect(result2.isLive, isFalse);
      expect(result2.sourceLabel, 'Cached Offline Record');
    });

    test('6. Handling Sparse/Missing Medical Fields without Crash', () {
      final minimalProfile = MedicalProfile.empty(
        'UID-MINIMAL-01',
        'Minimal Patient',
        '+919000000000',
        medicalId: 'G1-MED-2026-MIN001',
      );

      final snapshot = minimalProfile.toEmergencySnapshot();
      expect(snapshot.name, 'Minimal Patient');
      expect(snapshot.bg, 'Unknown');
      expect(snapshot.alrg, isEmpty);
      expect(snapshot.cond, isEmpty);
      expect(snapshot.emPhone, '+919000000000');

      final qrString = MedicalIdService.generateQrString(minimalProfile);
      final verification = MedicalIdService.verifyQrPayload(qrString);
      expect(verification.isValid, isTrue);
      expect(verification.payload?.bg, 'Unknown');
    });

    test('7. Patient Not Found Error Handling', () async {
      final firestoreService = FirestoreService();
      final result = await firestoreService.fetchProfileWithSourceByMedicalId('G1-MED-2026-NONEXISTENT');

      expect(result.profile, isNull);
      expect(result.source, ProfileDataSource.notFound);
      expect(result.errorMessage, contains('No medical profile found'));
    });

    test('8. Doctor Verification Gate: Pending vs Approved Authorization', () async {
      final authProvider = AuthProvider();

      // Register doctor
      await authProvider.registerDoctor(
        name: 'Dr. Maya Sen',
        email: 'maya@g1care.com',
        phone: '+919988776655',
        password: 'password123',
        medicalRegistrationNumber: 'MCI-5544',
        specialization: 'Emergency Medicine',
        hospital: 'Apex Trauma Center',
      );

      // Initially Pending
      expect(authProvider.isDoctor, isTrue);
      expect(authProvider.doctorVerificationStatus, DoctorVerificationStatus.pending);
      expect(authProvider.isDoctorApproved, isFalse);

      // Approve Doctor
      await authProvider.simulateDoctorApprovalToggle();
      expect(authProvider.doctorVerificationStatus, DoctorVerificationStatus.approved);
      expect(authProvider.isDoctorApproved, isTrue);
    });

    test('9. Full End-to-End Workflow: Patient QR Generation -> Doctor Triage -> Full Profile Retrieval', () async {
      final firestoreService = FirestoreService();

      // 1. Patient creates profile
      final patientProfile = MedicalProfile(
        uid: 'PATIENT-E2E-01',
        medicalId: 'G1-MED-2026-E2E001',
        fullName: 'Ramesh Patel',
        dateOfBirth: '1980-08-10',
        gender: 'Male',
        phone: '+91 9777888999',
        address: '12 Sector 4, Gandhinagar',
        emergencyContact: '+91 9777888000',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Geeta Patel',
          phone: '+91 9777888000',
          relationship: 'Spouse',
        ),
        bloodGroup: 'O+',
        allergies: ['Ibuprofen'],
        medicines: [
          MedicineItem(name: 'Amlodipine', dosage: '5mg', frequency: 'Once daily morning'),
        ],
        medicalConditions: ['Hypertension', 'Hyperlipidemia'],
        previousSurgeries: ['Hernia Repair 2017'],
        previousIllnesses: ['Malaria 2015'],
        emergencyNotes: 'Carry BP monitoring card.',
        primaryDoctor: 'Dr. Harish Vyas',
        updatedAt: DateTime.now(),
      );

      await firestoreService.saveMedicalProfile(patientProfile);

      // 2. Patient generates QR Code
      final patientQrString = MedicalIdService.generateQrString(patientProfile);
      expect(patientQrString, isNotEmpty);

      // 3. Doctor Scans QR
      final scanResult = MedicalIdService.verifyQrPayload(patientQrString);
      expect(scanResult.isValid, isTrue);
      final triageSnapshot = scanResult.payload!;

      // 4. Doctor inspects triage metrics
      expect(triageSnapshot.name, 'Ramesh Patel');
      expect(triageSnapshot.bg, 'O+');
      expect(triageSnapshot.alrg, ['Ibuprofen']);
      expect(triageSnapshot.emPhone, '+91 9777888000');

      // 5. Doctor retrieves full protected medical profile using Medical ID
      final retrievedResult = await firestoreService.fetchProfileWithSourceByMedicalId(triageSnapshot.medId);
      expect(retrievedResult.profile, isNotNull);

      final fullProfile = retrievedResult.profile!;
      expect(fullProfile.uid, 'PATIENT-E2E-01');
      expect(fullProfile.medicalId, 'G1-MED-2026-E2E001');
      expect(fullProfile.medicines.first.name, 'Amlodipine');
      expect(fullProfile.medicines.first.dosage, '5mg');
      expect(fullProfile.previousSurgeries, contains('Hernia Repair 2017'));
      expect(fullProfile.emergencyNotes, 'Carry BP monitoring card.');
      expect(fullProfile.primaryDoctor, 'Dr. Harish Vyas');
    });
  });
}
