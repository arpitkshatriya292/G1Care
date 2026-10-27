import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/hospital_doctor.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/ambulance_provider.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/hospital_provider.dart';
import 'package:g1care/services/emergency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Post-Testing Stability: Doctor Data Persistence Across App Restarts', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('HospitalProvider loads default demo doctors and persists to SharedPreferences', () async {
      final provider = HospitalProvider();
      await provider.loadDoctorsFromStorage();

      expect(provider.totalDoctorsCount, equals(HospitalDoctor.demoDoctors.length));
      expect(provider.verifiedDoctorsCount, equals(4));
      expect(provider.unverifiedDoctorsCount, equals(1));

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('g1care_hospital_doctors');
      expect(storedJson, isNotNull);
      final List<dynamic> decoded = jsonDecode(storedJson!);
      expect(decoded.length, equals(HospitalDoctor.demoDoctors.length));
    });

    test('Added doctor persists in SharedPreferences and survives provider re-initialization', () async {
      final provider1 = HospitalProvider();
      await provider1.loadDoctorsFromStorage();

      await provider1.addDoctor(
        name: 'Dr. Neha Kulkarni',
        medicalRegistrationNumber: 'MAH-PUN-9921',
        specialty: 'Trauma Surgery',
        department: 'Emergency & Critical Care',
        role: 'Senior Consultant',
        phone: '+91 98221 11223',
        email: 'neha.k@hospital.demo',
        yearsOfExperience: 12,
        joiningDate: '2024-03-01',
        isVerified: false,
      );

      expect(provider1.totalDoctorsCount, equals(6));
      expect(provider1.unverifiedDoctorsCount, equals(2));

      // Verify and persist
      final newDocId = provider1.doctors.first.id;
      await provider1.verifyDoctor(newDocId);
      expect(provider1.verifiedDoctorsCount, equals(5));

      // Simulate App Restart with new HospitalProvider instance
      final provider2 = HospitalProvider();
      await provider2.loadDoctorsFromStorage();

      expect(provider2.totalDoctorsCount, equals(6));
      expect(provider2.verifiedDoctorsCount, equals(5));
      final reloadedDoctor = provider2.doctors.firstWhere((d) => d.name == 'Dr. Neha Kulkarni');
      expect(reloadedDoctor.isVerified, isTrue);
      expect(reloadedDoctor.medicalRegistrationNumber, equals('MAH-PUN-9921'));
    });

    test('Doctor verification toggle persists accurately', () async {
      final provider1 = HospitalProvider();
      await provider1.loadDoctorsFromStorage();

      final firstDocId = provider1.doctors.first.id;
      expect(provider1.doctors.first.isVerified, isTrue);

      // Revoke access
      await provider1.toggleDoctorVerification(firstDocId);
      expect(provider1.doctors.first.isVerified, isFalse);

      // Re-instantiate provider (app restart simulation)
      final provider2 = HospitalProvider();
      await provider2.loadDoctorsFromStorage();
      final reloaded = provider2.doctors.firstWhere((d) => d.id == firstDocId);
      expect(reloaded.isVerified, isFalse);
    });
  });

  group('Post-Testing Stability: Wall-Clock Time Ambulance Navigation & Arrival', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      EmergencyService.clearInMemoryEmergenciesForTesting();
    });

    test('Ambulance ETA calculates accurately based on elapsed wall-clock time', () async {
      final startTime = DateTime.now().subtract(const Duration(minutes: 5));
      final incident = EmergencyIncident(
        incidentId: 'INC-WALLCLOCK-01',
        patientUid: 'PAT-01',
        medicalId: 'G1-MED-1234',
        patientName: 'Rahul Deshmukh',
        bloodGroup: 'B+',
        emergencyPhone: '+91 98220 12345',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        status: EmergencyStatus.enRoute,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Shivajinagar, Pune',
        initialDistanceKm: 7.0,
        initialDurationSeconds: 12 * 60, // 12 minutes total
        dispatchedAt: startTime,
        createdAt: startTime,
      );

      final ambulance = AmbulanceLocationProvider();
      await ambulance.syncWithIncident(incident);

      // 5 minutes elapsed out of 12 minutes (~41.6% progress)
      expect(ambulance.status, equals(AmbulanceStatus.enRoute));
      expect(ambulance.etaMinutes, lessThanOrEqualTo(8));
      expect(ambulance.etaMinutes, greaterThanOrEqualTo(6));
      expect(ambulance.distanceKm, lessThan(7.0));
      expect(ambulance.distanceKm, greaterThan(2.0));
    });

    test('Ambulance automatically transitions to ARRIVED when elapsed time >= duration', () async {
      // Dispatched 20 minutes ago for a 10-minute journey
      final startTime = DateTime.now().subtract(const Duration(minutes: 20));
      final incident = EmergencyIncident(
        incidentId: 'INC-WALLCLOCK-02',
        patientUid: 'PAT-02',
        medicalId: 'G1-MED-5678',
        patientName: 'Ananya Roy',
        bloodGroup: 'O+',
        emergencyPhone: '+91 98220 54321',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.fallDetected,
        status: EmergencyStatus.enRoute,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Kothrud, Pune',
        initialDistanceKm: 5.0,
        initialDurationSeconds: 10 * 60, // 10 minutes
        dispatchedAt: startTime,
        createdAt: startTime,
      );

      final ambulance = AmbulanceLocationProvider();
      await ambulance.syncWithIncident(incident);

      expect(ambulance.status, equals(AmbulanceStatus.arrived));
      expect(ambulance.hasArrived, isTrue);
      expect(ambulance.etaMinutes, equals(0));
      expect(ambulance.distanceKm, equals(0.0));
    });

    test('Arrival notification popup flag is tracked once and resets for new emergencies', () async {
      final emergencyService = EmergencyService();
      final emergencyProvider = EmergencyProvider(emergencyService: emergencyService);

      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-TEST-POPUP',
        medicalId: 'G1-MED-9999',
        patientName: 'Siddharth Patel',
        bloodGroup: 'AB+',
        emergencyPhone: '+91 98220 99999',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Viman Nagar, Pune',
      );

      expect(incident.arrivalPopupShown, isFalse);

      // Mark arrival popup shown
      await emergencyProvider.markArrivalPopupShown(incident.incidentId);
      expect(emergencyProvider.currentPatientIncident?.arrivalPopupShown, isTrue);

      // Cancel and create a NEW emergency
      await emergencyProvider.cancelSos();
      expect(emergencyProvider.currentPatientIncident, isNull);

      final newIncident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-TEST-POPUP',
        medicalId: 'G1-MED-9999',
        patientName: 'Siddharth Patel',
        bloodGroup: 'AB+',
        emergencyPhone: '+91 98220 99999',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Viman Nagar, Pune',
      );

      expect(newIncident.arrivalPopupShown, isFalse);
    });
  });
}
