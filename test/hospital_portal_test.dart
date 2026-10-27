import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/hospital_account.dart';
import 'package:g1care/models/hospital_doctor.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/hospital_provider.dart';
import 'package:g1care/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 7: Hospital Emergency Portal & Case Management Tests', () {
    test('1. Verified Doctors Section contains 5 verified demo doctors with specialties and roles', () {
      final doctors = HospitalDoctor.demoDoctors;

      expect(doctors.length, greaterThanOrEqualTo(5));

      final drAlex = doctors.firstWhere((d) => d.name == 'Dr. Alex Sharma');
      expect(drAlex.specialty, 'Emergency Medicine');
      expect(drAlex.department, 'Emergency Department');
      expect(drAlex.isVerified, isTrue);

      final drPriya = doctors.firstWhere((d) => d.name == 'Dr. Priya Deshmukh');
      expect(drPriya.specialty, 'Cardiology');
      expect(drPriya.department, 'Cardiology');
      expect(drPriya.isVerified, isTrue);

      final drRahul = doctors.firstWhere((d) => d.name == 'Dr. Rahul Mehta');
      expect(drRahul.specialty, 'General Medicine');
      expect(drRahul.department, 'General Medicine');
      expect(drRahul.isVerified, isTrue);

      final drSneha = doctors.firstWhere((d) => d.name == 'Dr. Sneha Patil');
      expect(drSneha.specialty, 'Neurology');
      expect(drSneha.department, 'Neurology');
      expect(drSneha.isVerified, isTrue);

      final drAmit = doctors.firstWhere((d) => d.name == 'Dr. Amit Kulkarni');
      expect(drAmit.specialty, 'Orthopedics');
      expect(drAmit.department, 'Orthopedics');
      expect(drAmit.isVerified, isFalse); // Demo unverified doctor
    });

    test('2. Hospital Registration: creates verified hospital account in HospitalProvider', () async {
      final provider = HospitalProvider();

      final newHospital = HospitalAccount(
        id: 'HOSP-PUN-99',
        hospitalName: 'Jehangir Emergency Trauma Center',
        registrationNumber: 'MAH-PUN-2024-9912',
        hospitalType: 'Trauma & Emergency Center',
        address: '32 Sassoon Road',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411001',
        officialPhone: '+91 20 6681 1000',
        officialEmail: 'emergency@jehangir.demo',
        adminName: 'Dr. R. K. Jehangir (Director)',
        adminPhone: '+91 98220 99999',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      await provider.registerHospital(newHospital);

      expect(provider.currentHospital.hospitalName, 'Jehangir Emergency Trauma Center');
      expect(provider.currentHospital.isVerified, isTrue);
      expect(provider.currentHospital.city, 'Pune');
    });

    test('3. Doctor Registration & Verification in Hospital Portal', () async {
      final provider = HospitalProvider();
      final initialCount = provider.totalDoctorsCount;

      // 1. Add new doctor from Hospital Portal
      await provider.addDoctor(
        name: 'Dr. Vikram Malhotra',
        medicalRegistrationNumber: 'MMC-2023-99881',
        specialty: 'Pulmonology',
        department: 'Respiratory Medicine & ICU',
        role: 'Critical Care Specialist',
        phone: '+91 98230 55443',
        email: 'dr.vikram@rubyhall.demo',
        yearsOfExperience: 6,
        joiningDate: '01 June 2024',
        isVerified: false,
      );

      expect(provider.totalDoctorsCount, initialCount + 1);
      final addedDoc = provider.doctors.firstWhere((d) => d.name == 'Dr. Vikram Malhotra');
      expect(addedDoc.isVerified, isFalse); // Initially unverified

      // 2. Hospital Administrator verifies the doctor
      await provider.verifyDoctor(addedDoc.id);
      final verifiedDoc = provider.doctors.firstWhere((d) => d.id == addedDoc.id);
      expect(verifiedDoc.isVerified, isTrue);
    });

    test('4. Hospital Case Discharge: Resolving case removes it from active list and updates counters', () async {
      final emergencyProvider = EmergencyProvider();

      // Trigger 1 Critical incident and 1 Moderate incident
      final crit = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-HOSP-01',
        medicalId: 'G1-MED-2026-H01',
        patientName: 'Hospital Patient 1',
        bloodGroup: 'O+',
        emergencyPhone: '+91 9876500111',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5326,
        longitude: 73.8785,
        locationAddress: 'Pune Central',
      );

      final mod = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-HOSP-02',
        medicalId: 'G1-MED-2026-H02',
        patientName: 'Hospital Patient 2',
        bloodGroup: 'B+',
        emergencyPhone: '+91 9876500112',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.criticalVitals,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(spo2: 92),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune Camp',
      );

      expect(emergencyProvider.activeEmergencies.length, 2);
      expect(emergencyProvider.criticalCasesCount, 1);
      expect(emergencyProvider.moderateCasesCount, 1);

      // Hospital Receptionist resolves and discharges the critical case
      await emergencyProvider.resolveEmergency(crit.incidentId);

      expect(emergencyProvider.activeEmergencies.length, 1);
      expect(emergencyProvider.activeEmergencies.any((e) => e.incidentId == crit.incidentId), isFalse);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 1);

      // Hospital Receptionist resolves and discharges the moderate case
      await emergencyProvider.resolveEmergency(mod.incidentId);

      expect(emergencyProvider.activeEmergencies.isEmpty, isTrue);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 0);
    });

    test('5. Synchronized State: Discharged incident stops active ambulance tracking', () async {
      final emergencyProvider = EmergencyProvider();

      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-HOSP-SYNC',
        medicalId: 'G1-MED-2026-HSYNC',
        patientName: 'Sync Hospital Patient',
        bloodGroup: 'AB+',
        emergencyPhone: '+91 9876500113',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5135,
        longitude: 73.8340,
        locationAddress: 'Sahyadri Hospital Area, Pune',
      );

      final ambulance = emergencyProvider.getAmbulanceForIncident(incident.incidentId);
      expect(ambulance.isEnRoute, isTrue);

      // Discharge patient
      await emergencyProvider.resolveEmergency(incident.incidentId);

      // Active state cleared
      expect(emergencyProvider.activeEmergencies.where((e) => e.incidentId == incident.incidentId), isEmpty);
      expect(emergencyProvider.currentPatientIncident, isNull);
    });
  });
}
