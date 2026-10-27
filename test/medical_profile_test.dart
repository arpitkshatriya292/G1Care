import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/models/emergency_contact.dart';
import 'package:g1care/models/medical_profile.dart';
import 'package:g1care/models/medicine_item.dart';
import 'package:g1care/providers/medical_profile_provider.dart';
import 'package:g1care/providers/auth_provider.dart';
import 'package:g1care/services/firestore_service.dart';
import 'package:g1care/services/medical_id_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 2: Medical Profile & Security Tests', () {
    test('MedicalProfile serialization, deserialization & copyWith', () {
      final profile = MedicalProfile(
        uid: 'PATIENT-001',
        medicalId: 'G1-MED-2026-A8F9K2',
        fullName: 'Rahul Kumar',
        dateOfBirth: '1995-05-12',
        gender: 'Male',
        phone: '+91 9123456789',
        address: '42 Health St, Metro City',
        emergencyContact: '+91 9876543210',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Pooja Kumar',
          phone: '+91 9876543210',
          relationship: 'Spouse',
        ),
        bloodGroup: 'O+',
        allergies: ['Penicillin', 'Peanuts'],
        medicines: [
          MedicineItem(name: 'Metformin', dosage: '500mg', frequency: 'Twice daily'),
        ],
        medicalConditions: ['Type 2 Diabetes'],
        previousSurgeries: ['Appendectomy (2018)'],
        previousIllnesses: ['Dengue (2020)'],
        emergencyNotes: 'Diabetic patient. Carry glucose.',
        primaryDoctor: 'Dr. Alex Sharma',
        updatedAt: DateTime.parse('2026-08-18T10:00:00.000Z'),
      );

      final map = profile.toMap();
      final fromMap = MedicalProfile.fromMap(map);

      expect(fromMap.uid, 'PATIENT-001');
      expect(fromMap.medicalId, 'G1-MED-2026-A8F9K2');
      expect(fromMap.bloodGroup, 'O+');
      expect(fromMap.allergies.length, 2);
      expect(fromMap.medicines.first.name, 'Metformin');
      expect(fromMap.emergencyContactInfo.name, 'Pooja Kumar');

      final updated = profile.copyWith(bloodGroup: 'AB+');
      expect(updated.bloodGroup, 'AB+');
      expect(updated.fullName, 'Rahul Kumar');
    });

    test('Data Minimization: EmergencyQrPayload excludes private clinical data', () {
      final profile = MedicalProfile(
        uid: 'PATIENT-001',
        medicalId: 'G1-MED-2026-A8F9K2',
        fullName: 'Rahul Kumar',
        dateOfBirth: '1995-05-12',
        gender: 'Male',
        phone: '+91 9123456789',
        address: '42 Sensitive Residential Address, Private Apt 3B',
        emergencyContact: '+91 9876543210',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Pooja Kumar',
          phone: '+91 9876543210',
          relationship: 'Spouse',
        ),
        bloodGroup: 'O+',
        allergies: ['Penicillin'],
        medicines: [
          MedicineItem(name: 'SensitivePrescriptionDrug', dosage: '10mg', frequency: 'Daily'),
        ],
        medicalConditions: ['Hypertension'],
        previousSurgeries: ['Private Surgery 2021'],
        previousIllnesses: ['Private Illness 2019'],
        emergencyNotes: 'Private medical directive.',
        primaryDoctor: 'Dr. Alex Sharma',
        updatedAt: DateTime.now(),
      );

      final qrString = MedicalIdService.generateQrString(profile);
      final jsonMap = jsonDecode(qrString) as Map<String, dynamic>;

      // Verify minimal emergency fields are present
      expect(jsonMap['medId'], 'G1-MED-2026-A8F9K2');
      expect(jsonMap['name'], 'Rahul Kumar');
      expect(jsonMap['bg'], 'O+');
      expect(jsonMap['alrg'], ['Penicillin']);
      expect(jsonMap['cond'], ['Hypertension']);
      expect(jsonMap['emPhone'], '+91 9876543210');
      expect(jsonMap['integrityTag'], isNotEmpty);

      // Strictly verify that private clinical fields are EXCLUDED
      expect(jsonMap.containsKey('address'), isFalse);
      expect(jsonMap.containsKey('medicines'), isFalse);
      expect(jsonMap.containsKey('previousSurgeries'), isFalse);
      expect(jsonMap.containsKey('previousIllnesses'), isFalse);
      expect(jsonMap.containsKey('emergencyNotes'), isFalse);
      expect(jsonMap.containsKey('primaryDoctor'), isFalse);
      expect(jsonMap.containsKey('uid'), isFalse);

      // Verify raw JSON does not leak private strings
      expect(qrString.contains('Sensitive Residential Address'), isFalse);
      expect(qrString.contains('SensitivePrescriptionDrug'), isFalse);
      expect(qrString.contains('Private Surgery'), isFalse);
    });

    test('Unique Medical ID format generation', () {
      final medId = MedicalIdService.generateMedicalId(year: 2026);
      final regex = RegExp(r'^G1-MED-2026-[A-Z2-9]{6}$');
      expect(regex.hasMatch(medId), isTrue);

      // Verify uniqueness across multiple generations
      final idSet = <String>{};
      for (int i = 0; i < 50; i++) {
        final id = MedicalIdService.generateMedicalId(year: 2026);
        expect(idSet.contains(id), isFalse);
        idSet.add(id);
      }
    });

    test('Prototype HMAC integrity tag generation and tamper detection', () {
      final profile = MedicalProfile.empty('UID-100', 'Jane Doe', '+919999999999',
          medicalId: 'G1-MED-2026-TEST01')
        .copyWith(
          bloodGroup: 'B+',
          allergies: ['Aspirin'],
        );

      final qrJson = MedicalIdService.generateQrString(profile);

      // 1. Verify valid payload passes integrity check
      final verification = MedicalIdService.verifyQrPayload(qrJson);
      expect(verification.isValid, isTrue);
      expect(verification.payload?.bg, 'B+');
      expect(verification.payload?.medId, 'G1-MED-2026-TEST01');
      expect(verification.error, isNull);

      // 2. Simulate malicious client-side tampering of Blood Group
      final tamperedMap = jsonDecode(qrJson) as Map<String, dynamic>;
      tamperedMap['bg'] = 'AB-'; // Altered without re-generating valid HMAC
      final tamperedJson = jsonEncode(tamperedMap);

      final tamperedVerification = MedicalIdService.verifyQrPayload(tamperedJson);
      expect(tamperedVerification.isValid, isFalse);
      expect(tamperedVerification.error, contains('Integrity verification failed'));
    });

    test('MedicalProfileProvider state management & mutations', () async {
      final provider = MedicalProfileProvider();
      expect(provider.profile, isNull);

      await provider.loadProfile('PATIENT-NEW-01', name: 'Test User', phone: '+919876543210');
      expect(provider.profile, isNotNull);
      expect(provider.profile?.fullName, 'Test User');
      expect(provider.medicalId, startsWith('G1-MED-'));

      // Test allergy addition
      await provider.addAllergy('Latex');
      expect(provider.allergies, contains('Latex'));

      // Test medicine addition
      await provider.addMedicine(MedicineItem(
        name: 'Amoxicillin',
        dosage: '250mg',
        frequency: '3 times daily',
      ));
      expect(provider.medicines.any((m) => m.name == 'Amoxicillin'), isTrue);

      // Test emergency snapshot export
      final snapshot = provider.emergencySnapshot;
      expect(snapshot, isNotNull);
      expect(snapshot?.name, 'Test User');
      expect(snapshot?.alrg, contains('Latex'));
      expect(snapshot?.integrityTag, isNotEmpty);
    });

    test('Persistence across cold restarts (SharedPreferences fallback)', () async {
      final firestoreService = FirestoreService();

      // 1. Create and save a custom medical profile
      final initialProfile = MedicalProfile(
        uid: 'PATIENT-PERSIST-01',
        medicalId: 'G1-MED-2026-ZZ99XX',
        fullName: 'Persisted Patient',
        dateOfBirth: '1990-01-01',
        gender: 'Female',
        phone: '+91 9988776655',
        address: '100 Resilience Way',
        emergencyContact: '+91 9112233445',
        emergencyContactInfo: EmergencyContactInfo(
          name: 'Guardian Contact',
          phone: '+91 9112233445',
          relationship: 'Parent',
        ),
        bloodGroup: 'AB-',
        allergies: ['Sulfa Drugs', 'Pollen'],
        medicines: [
          MedicineItem(name: 'Thyroxine', dosage: '50mcg', frequency: 'Morning fasting'),
        ],
        medicalConditions: ['Hypothyroidism'],
        previousSurgeries: ['Knee Arthroscopy 2022'],
        previousIllnesses: ['COVID-19 2021'],
        emergencyNotes: 'Allergic to sulfa drugs. Take thyroid med empty stomach.',
        primaryDoctor: 'Dr. Priya Mehta',
        updatedAt: DateTime.now(),
      );

      await firestoreService.saveMedicalProfile(initialProfile);

      // 2. Simulate complete app kill/restart by wiping in-memory static maps
      FirestoreService.clearInMemoryCacheForTesting();

      // 3. Load profile from fresh FirestoreService instance
      final reloadedProfile = await firestoreService.getMedicalProfile('PATIENT-PERSIST-01');
      expect(reloadedProfile, isNotNull);
      expect(reloadedProfile?.fullName, 'Persisted Patient');
      expect(reloadedProfile?.bloodGroup, 'AB-');
      expect(reloadedProfile?.allergies, contains('Sulfa Drugs'));
      expect(reloadedProfile?.medicines.first.name, 'Thyroxine');
      expect(reloadedProfile?.emergencyContactInfo.name, 'Guardian Contact');

      // 4. Verify medical ID index lookup also survives cold restart
      final profileByMedId = await firestoreService.getProfileByMedicalId('G1-MED-2026-ZZ99XX');
      expect(profileByMedId, isNotNull);
      expect(profileByMedId?.uid, 'PATIENT-PERSIST-01');

      // 5. Verify createDefaultMedicalProfile does not overwrite existing saved profile
      final safeProfile = await firestoreService.createDefaultMedicalProfile(
        'PATIENT-PERSIST-01',
        'Should Not Overwrite',
        '+91 0000000000',
      );
      expect(safeProfile.fullName, 'Persisted Patient');
      expect(safeProfile.bloodGroup, 'AB-');
    });

    test('Patient registration, edit profile, and sign-in recovery across restarts', () async {
      final authProvider = AuthProvider();

      // 1. Register a new patient
      final regSuccess = await authProvider.registerPatient(
        name: 'Anita Desai',
        email: 'anita@g1care.com',
        phone: '+91 9876501234',
        password: 'password123',
      );
      expect(regSuccess, isTrue);
      final patientUid = authProvider.patientUser!.uid;

      // 2. Patient edits and updates medical profile
      final profileProvider = MedicalProfileProvider();
      await profileProvider.loadProfile(patientUid, name: 'Anita Desai', phone: '+91 9876501234');
      expect(profileProvider.profile, isNotNull);

      final updatedProfile = profileProvider.profile!.copyWith(
        bloodGroup: 'B+',
        allergies: ['Penicillin', 'Shellfish'],
        emergencyNotes: 'Severe shellfish anaphylaxis risk.',
      );
      final saveSuccess = await profileProvider.saveProfile(updatedProfile);
      expect(saveSuccess, isTrue);

      // 3. Simulate app process termination / cold restart
      FirestoreService.clearInMemoryCacheForTesting();

      // 4. Sign in with same email in new session
      final freshAuthProvider = AuthProvider();
      final loginSuccess = await freshAuthProvider.login('anita@g1care.com', 'password123');
      expect(loginSuccess, isTrue);
      expect(freshAuthProvider.patientUser?.uid, patientUid);

      // 5. Load profile in new session
      final freshProfileProvider = MedicalProfileProvider();
      await freshProfileProvider.loadProfile(patientUid);
      expect(freshProfileProvider.profile?.bloodGroup, 'B+');
      expect(freshProfileProvider.allergies, contains('Shellfish'));
      expect(freshProfileProvider.profile?.emergencyNotes, 'Severe shellfish anaphylaxis risk.');
    });

    test('Milestone 6: Opaque QR Token contains zero readable medical information', () {
      final token = MedicalIdService.generateQrToken();
      expect(token, startsWith('G1QR-'));
      expect(token.contains('{'), isFalse);
      expect(token.contains('medId'), isFalse);
      expect(token.contains('name'), isFalse);
      expect(token.contains('bg'), isFalse);
      expect(token.contains('alrg'), isFalse);
      expect(token.contains('cond'), isFalse);
      expect(token.contains('emPhone'), isFalse);
      expect(MedicalIdService.isOpaqueQrToken(token), isTrue);
    });

    test('Milestone 6: Opaque QR Token registration & resolution', () {
      MedicalIdService.clearQrTokenRegistryForTesting();
      final token = MedicalIdService.generateQrToken();
      MedicalIdService.registerQrToken(token, 'G1-MED-2026-X9Y8Z7');

      final resolvedMedId = MedicalIdService.lookupMedicalIdByToken(token);
      expect(resolvedMedId, 'G1-MED-2026-X9Y8Z7');

      // Unknown / expired token returns null
      final unknown = MedicalIdService.lookupMedicalIdByToken('G1QR-NONEXISTENT');
      expect(unknown, isNull);
    });

    test('Milestone 6: MedicalProfileProvider generates and holds opaque QR token', () async {
      final provider = MedicalProfileProvider();
      await provider.loadProfile('PATIENT-QR-01', name: 'Ravi Verma');
      expect(provider.hasQrToken, isTrue);
      expect(provider.qrToken, startsWith('G1QR-'));

      final resolvedMedId = MedicalIdService.lookupMedicalIdByToken(provider.qrToken);
      expect(resolvedMedId, provider.medicalId);
    });
  });
}
