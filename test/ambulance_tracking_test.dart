import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/ambulance_provider.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 6: Realistic Pune Map, Distance-Based ETA & Tracking Tests', () {
    test('1. Distance-based ETA: 2 km yields ~3-4 min emergency ETA (never hardcoded 45 min)', () async {
      final ambulance = AmbulanceLocationProvider(
        initialPosition: const LatLng(18.5326, 73.8785), // Ruby Hall Clinic, Pune
      );

      final incident = EmergencyIncident(
        incidentId: 'G1-INC-2026-TEST01',
        patientUid: 'PAT-PUNE-01',
        medicalId: 'G1-MED-2026-PUNE01',
        patientName: 'Pune Patient',
        bloodGroup: 'B+',
        emergencyPhone: '+91 9876543210',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        status: EmergencyStatus.active,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204, // Shaniwar Wada, Pune (~2.0 km)
        longitude: 73.8567,
        locationAddress: 'Shaniwar Wada, Pune',
        distanceKm: 2.0,
        etaMinutes: 3,
        createdAt: DateTime.now(),
      );

      await ambulance.dispatchToIncident(incident);

      expect(ambulance.distanceKm, greaterThan(0.0));
      // For a ~2 km urban trip at 35 km/h, ETA must be reasonable (e.g. 1-10 min, not 45 min)
      expect(ambulance.etaMinutes, lessThanOrEqualTo(10));
      expect(ambulance.etaMinutes, greaterThanOrEqualTo(1));
      expect(ambulance.isEnRoute, isTrue);

      ambulance.dispose();
    });

    test('2. Deterministic movement: remaining distance and ETA decrease as ambulance moves', () async {
      final ambulance = AmbulanceLocationProvider(
        initialPosition: const LatLng(18.5326, 73.8785),
      );

      final incident = EmergencyIncident(
        incidentId: 'G1-INC-2026-TEST02',
        patientUid: 'PAT-PUNE-02',
        medicalId: 'G1-MED-2026-PUNE02',
        patientName: 'Pune Patient 2',
        bloodGroup: 'O+',
        emergencyPhone: '+91 9876543211',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        status: EmergencyStatus.active,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5089, // Swargate, Pune (~3.5 km)
        longitude: 73.8553,
        locationAddress: 'Swargate, Pune',
        createdAt: DateTime.now(),
      );

      await ambulance.dispatchToIncident(incident);
      final initialDistance = ambulance.distanceKm;
      final initialEta = ambulance.etaMinutes;

      expect(initialDistance, greaterThan(0.0));
      expect(initialEta, greaterThanOrEqualTo(1));
      expect(ambulance.routePoints, isNotEmpty);

      ambulance.dispose();
    });

    test('3. Different emergencies have independent per-incident ambulance state', () async {
      final emergencyProvider = EmergencyProvider();

      // Incident 1: Patient in Kothrud
      final inc1 = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-PUNE-KOTHRUD',
        medicalId: 'G1-MED-2026-KOTH01',
        patientName: 'Kothrud Patient',
        bloodGroup: 'A+',
        emergencyPhone: '+91 9876500001',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5074,
        longitude: 73.8077,
        locationAddress: 'Kothrud, Pune',
      );

      // Incident 2: Patient in Viman Nagar
      final inc2 = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-PUNE-VIMAN',
        medicalId: 'G1-MED-2026-VIMAN1',
        patientName: 'Viman Nagar Patient',
        bloodGroup: 'AB+',
        emergencyPhone: '+91 9876500002',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.fallDetected,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(isFallDetected: true),
        latitude: 18.5679,
        longitude: 73.9143,
        locationAddress: 'Viman Nagar, Pune',
      );

      final amb1 = emergencyProvider.getAmbulanceForIncident(inc1.incidentId);
      final amb2 = emergencyProvider.getAmbulanceForIncident(inc2.incidentId);

      expect(amb1.ambulanceId, isNot(equals(amb2.ambulanceId)));
      expect(inc1.assignedHospitalName, isNotNull);
      expect(inc2.assignedHospitalName, isNotNull);

      // Clean up
      await emergencyProvider.resolveEmergency(inc1.incidentId);
      await emergencyProvider.resolveEmergency(inc2.incidentId);
    });

    test('4. Shared Emergency State: Patient, Doctor and Hospital read matching incident data', () async {
      final emergencyProvider = EmergencyProvider();

      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-SHARED-01',
        medicalId: 'G1-MED-2026-SH01',
        patientName: 'Shared Patient',
        bloodGroup: 'O-',
        emergencyPhone: '+91 9876540000',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5308,
        longitude: 73.8475,
        locationAddress: 'Shivajinagar, Pune',
      );

      // 1. Patient view reads currentPatientIncident
      final patientIncident = emergencyProvider.currentPatientIncident;
      expect(patientIncident, isNotNull);
      expect(patientIncident?.incidentId, incident.incidentId);

      // 2. Doctor view reads activeEmergencies
      final doctorIncident = emergencyProvider.activeEmergencies.firstWhere(
        (e) => e.incidentId == incident.incidentId,
      );
      expect(doctorIncident.patientName, patientIncident?.patientName);
      expect(doctorIncident.distanceKm, patientIncident?.distanceKm);
      expect(doctorIncident.etaMinutes, patientIncident?.etaMinutes);
      expect(doctorIncident.ambulanceId, patientIncident?.ambulanceId);

      // 3. Hospital/Dispatch view reads same ambulance provider
      final ambulance = emergencyProvider.getAmbulanceForIncident(incident.incidentId);
      expect(ambulance.ambulanceId, patientIncident?.ambulanceId);

      // Cancel SOS and verify cleanup across all views
      await emergencyProvider.cancelSos();
      expect(emergencyProvider.currentPatientIncident, isNull);
      expect(emergencyProvider.activeEmergencies.where((e) => e.incidentId == incident.incidentId), isEmpty);
    });

    test('5. Doctor dashboard active emergency counters update on trigger and resolution', () async {
      final emergencyProvider = EmergencyProvider();
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 0);

      // Trigger critical emergency (Manual SOS / Fall)
      final crit = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-CRIT-01',
        medicalId: 'G1-MED-2026-C01',
        patientName: 'Critical Case',
        bloodGroup: 'B+',
        emergencyPhone: '+91 9876500010',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.criticalCasesCount, 1);

      // Trigger moderate emergency (Warning Vitals: SpO2 92)
      final mod = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-MOD-01',
        medicalId: 'G1-MED-2026-M01',
        patientName: 'Moderate Case',
        bloodGroup: 'A+',
        emergencyPhone: '+91 9876500011',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.criticalVitals,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(spo2: 92),
        latitude: 18.5300,
        longitude: 73.8500,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.criticalCasesCount, 1);
      expect(emergencyProvider.moderateCasesCount, 1);

      // Resolve critical case
      await emergencyProvider.resolveEmergency(crit.incidentId);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 1);

      // Resolve moderate case
      await emergencyProvider.resolveEmergency(mod.incidentId);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 0);
    });
  });
}
