import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/hospital.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/location_provider.dart';
import 'package:g1care/services/emergency_service.dart';
import 'package:g1care/services/firestore_service.dart';
import 'package:g1care/services/routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
    EmergencyService.clearInMemoryEmergenciesForTesting();
  });

  group('Milestone 5: Location, Hospital & Pune Regional Routing Tests', () {
    test('1. LocationProvider default Pune prototype coordinates', () async {
      final provider = LocationProvider();
      expect(provider.latitude, 18.5204);
      expect(provider.longitude, 73.8567);
      expect(provider.isSimulated, isTrue);
      expect(provider.address, contains('Pune'));

      provider.setSimulatedLocation(18.5302, 73.8770, addr: 'Sassoon Road, Pune');
      expect(provider.latitude, 18.5302);
      expect(provider.longitude, 73.8770);
      expect(provider.address, 'Sassoon Road, Pune');
    });

    test('2. Pune Curated Hospital Data and Nearest Hospital Finder', () {
      expect(Hospital.defaultHospitals.length, greaterThanOrEqualTo(5));

      // Nearest to Central Pune (18.5204, 73.8567)
      final nearest = Hospital.findNearest(18.5204, 73.8567);
      expect(nearest.name, contains('KEM Hospital Pune'));
      expect(nearest.latitude, 18.5218);
      expect(nearest.longitude, 73.8715);

      final distance = Hospital.calculateDistanceKm(
        18.5204,
        73.8567,
        nearest.latitude,
        nearest.longitude,
      );
      expect(distance, greaterThan(0.0));
      expect(distance, lessThan(3.0)); // Realistic ~1.6 km in Pune
    });

    test('3. Geometric Route Interpolation (Offline/Fallback Routing in Pune)', () {
      final start = const LatLng(18.5326, 73.8785); // Ruby Hall Clinic, Pune
      final end = const LatLng(18.5204, 73.8567); // FC Road, Pune

      final route = RouteResult.interpolate(start, end, steps: 10);
      expect(route.waypoints.length, 11);
      expect(route.distanceKm, greaterThan(0.5));
      expect(route.distanceKm, lessThan(8.0)); // Realistic city distance
      expect(route.durationMinutes, greaterThanOrEqualTo(1));
      expect(route.isSimulatedRoute, isTrue);
      expect(route.waypoints.first.latitude, start.latitude);
    });
  });

  group('Milestone 5: Patient <-> Doctor Shared Location Consistency Tests', () {
    test('4. Exact Coordinates Shared Across Patient, Doctor, Map & Route', () async {
      const patientLocationX = LatLng(18.5204, 73.8567);
      final emergencyProvider = EmergencyProvider();

      // 1. Patient creates an emergency at location X
      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-PUNE-01',
        medicalId: 'G1-MED-2026-PUNE01',
        patientName: 'Aarav Deshmukh',
        bloodGroup: 'O+',
        emergencyPhone: '+91 9822012345',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: patientLocationX.latitude,
        longitude: patientLocationX.longitude,
        locationAddress: 'FC Road, Shivajinagar, Pune',
      );

      // 2. EmergencyIncident stores location X
      expect(incident.latitude, patientLocationX.latitude);
      expect(incident.longitude, patientLocationX.longitude);

      // 3. Doctor retrieves the emergency from provider / service
      final allActive = emergencyProvider.activeEmergencies;
      expect(allActive.length, 1);
      final doctorViewedIncident = allActive.first;

      // 4. Doctor sees exactly location X
      expect(doctorViewedIncident.latitude, patientLocationX.latitude);
      expect(doctorViewedIncident.longitude, patientLocationX.longitude);

      // 5. Patient map uses location X
      final patientMapIncident = emergencyProvider.currentPatientIncident!;
      expect(patientMapIncident.latitude, patientLocationX.latitude);
      expect(patientMapIncident.longitude, patientLocationX.longitude);

      // 6. Ambulance route uses location X as destination
      expect(patientMapIncident.assignedHospitalName, isNotNull);
      expect(patientMapIncident.hospitalLatitude, isNotNull);
      expect(patientMapIncident.hospitalLongitude, isNotNull);

      // Verify coordinates did not silently mutate
      expect(doctorViewedIncident.latitude, patientMapIncident.latitude);
      expect(doctorViewedIncident.longitude, patientMapIncident.longitude);
    });
  });

  group('Milestone 5: Doctor Active Emergency Counter Synchronization Tests', () {
    test('Test 1: Create one CRITICAL active emergency -> Critical: 1, Moderate: 0', () async {
      final emergencyProvider = EmergencyProvider();

      await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-CRIT-01',
        medicalId: 'G1-MED-2026-C01',
        patientName: 'Critical Patient',
        bloodGroup: 'B+',
        emergencyPhone: '+91 9999900001',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos, // Manual SOS is Critical
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.criticalCasesCount, 1);
      expect(emergencyProvider.moderateCasesCount, 0);
      expect(emergencyProvider.activeEmergencies.length, 1);
    });

    test('Test 2: Create one MODERATE active emergency -> Critical: 0, Moderate: 1', () async {
      final emergencyProvider = EmergencyProvider();

      await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-MOD-01',
        medicalId: 'G1-MED-2026-M01',
        patientName: 'Moderate Patient',
        bloodGroup: 'A+',
        emergencyPhone: '+91 9999900002',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.criticalVitals,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(
          heartRate: 110, // Level 2 Warning
          spo2: 92, // Level 2 Warning
        ),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 1);
      expect(emergencyProvider.activeEmergencies.length, 1);
    });

    test('Test 3: Create one CRITICAL + one MODERATE emergency -> Critical: 1, Moderate: 1', () async {
      final emergencyProvider = EmergencyProvider();

      // 1. Critical Incident
      final critIncident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-CRIT-02',
        medicalId: 'G1-MED-2026-C02',
        patientName: 'Critical Patient 2',
        bloodGroup: 'O+',
        emergencyPhone: '+91 9999900003',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.fallDetected,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(isFallDetected: true),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      // 2. Moderate Incident
      final modIncident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-MOD-02',
        medicalId: 'G1-MED-2026-M02',
        patientName: 'Moderate Patient 2',
        bloodGroup: 'AB+',
        emergencyPhone: '+91 9999900004',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.criticalVitals,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(spo2: 92),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.criticalCasesCount, 1);
      expect(emergencyProvider.moderateCasesCount, 1);
      expect(emergencyProvider.activeEmergencies.length, 2);

      // Test 4: Resolve the critical emergency -> Critical: 0, Moderate: 1
      await emergencyProvider.resolveEmergency(critIncident.incidentId);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 1);
      expect(emergencyProvider.activeEmergencies.length, 1);

      // Test 5: Resolve the moderate emergency -> Critical: 0, Moderate: 0
      await emergencyProvider.resolveEmergency(modIncident.incidentId);
      expect(emergencyProvider.criticalCasesCount, 0);
      expect(emergencyProvider.moderateCasesCount, 0);
      expect(emergencyProvider.activeEmergencies, isEmpty);
    });

    test('Test 6: The same emergency appearing on the map is reflected in dashboard counters', () async {
      final emergencyProvider = EmergencyProvider();

      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-SYNC-01',
        medicalId: 'G1-MED-2026-SYNC01',
        patientName: 'Sync Test Patient',
        bloodGroup: 'O-',
        emergencyPhone: '+91 9888877777',
        criticalAllergies: ['Sulfa'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Erandwane, Pune',
      );

      // Map reads currentPatientIncident or activeEmergencies
      expect(emergencyProvider.activeEmergencies.any((e) => e.incidentId == incident.incidentId), isTrue);
      // Dashboard reads criticalCasesCount
      expect(emergencyProvider.criticalCasesCount, 1);

      // Respond by doctor
      await emergencyProvider.respondToEmergency(
        incidentId: incident.incidentId,
        doctorId: 'DOC-10',
        doctorName: 'Dr. Neha Kulkarni',
      );
      // Counter remains 1 because responded is still an active status
      expect(emergencyProvider.criticalCasesCount, 1);

      // Cancel/Resolve
      await emergencyProvider.cancelSos();
      // Counter decrements to 0
      expect(emergencyProvider.criticalCasesCount, 0);
    });
  });
}
