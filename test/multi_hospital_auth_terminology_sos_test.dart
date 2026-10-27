import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:g1care/core/constants/app_constants.dart';
import 'package:g1care/models/disaster/disaster_models.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/hospital_account.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/ambulance_provider.dart';
import 'package:g1care/providers/auth_provider.dart';
import 'package:g1care/providers/disaster_provider.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/hospital_provider.dart';
import 'package:g1care/providers/location_provider.dart';
import 'package:g1care/providers/medical_profile_provider.dart';
import 'package:g1care/providers/wristband_provider.dart';
import 'package:g1care/screens/auth/login_screen.dart';
import 'package:g1care/screens/auth/register_screen.dart';
import 'package:g1care/screens/auth/role_selection_screen.dart';
import 'package:g1care/screens/disaster/disaster_hub_screen.dart';
import 'package:g1care/screens/patient/patient_home_screen.dart';
import 'package:g1care/services/disaster/disaster_data_provider.dart';
import 'package:g1care/services/emergency_service.dart';
import 'package:g1care/services/firestore_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestApp(Widget child, {EmergencyProvider? emergencyProvider, HospitalProvider? hospitalProvider}) {
    final ambProv = AmbulanceLocationProvider();
    final emergProv = emergencyProvider ?? EmergencyProvider(ambulanceProvider: ambProv);
    final hospProv = hospitalProvider ?? HospitalProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<MedicalProfileProvider>(create: (_) => MedicalProfileProvider()),
        ChangeNotifierProvider<LocationProvider>(create: (_) => LocationProvider()),
        ChangeNotifierProvider<WristbandProvider>(create: (_) => WristbandProvider(autoConnect: false)),
        ChangeNotifierProvider<AmbulanceLocationProvider>.value(value: ambProv),
        ChangeNotifierProvider<EmergencyProvider>.value(value: emergProv),
        ChangeNotifierProvider<HospitalProvider>.value(value: hospProv),
        ChangeNotifierProvider<DisasterProvider>(create: (_) => DisasterProvider()),
      ],
      child: MaterialApp(
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/disaster-hub': (context) => const DisasterHubScreen(),
          '/patient/home': (context) => const PatientHomeScreen(),
        },
        home: child,
      ),
    );
  }

  group('Multi-Hospital, User Terminology, Shared SOS & Login Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FirestoreService.clearInMemoryCacheForTesting();
      EmergencyService.clearInMemoryEmergenciesForTesting();
    });

    test('1. User login remains fully functional', () async {
      final authProvider = AuthProvider();
      final success = await authProvider.login('patient.demo@g1care.com', 'password123');

      expect(success, isTrue);
      expect(authProvider.isPatient, isTrue);
      expect(authProvider.isDoctor, isFalse);
      expect(authProvider.patientUser, isNotNull);
      expect(authProvider.patientUser!.email, 'patient.demo@g1care.com');
    });

    test('2. Hospital registration creates an independent hospital account/profile', () async {
      final authProvider = AuthProvider();
      final hospitalProvider = HospitalProvider();

      final hospitalA = HospitalAccount(
        id: 'HOSP-A-001',
        hospitalName: 'Apollo Speciality Hospital Pune',
        registrationNumber: 'MAH-PUN-HOSP-001',
        hospitalType: 'Multi-specialty',
        address: 'Plot 12, Baner Road',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411045',
        officialPhone: '+91 20 6711 0000',
        officialEmail: 'emergency@apollo.demo',
        adminName: 'Dr. Anita Desai',
        adminPhone: '+91 98230 11111',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      final success = await authProvider.registerHospital(
        hospitalData: hospitalA,
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authProvider.isDoctor, isTrue);
      expect(authProvider.isHospital, isTrue);
      expect(authProvider.hospitalUser, isNotNull);
      expect(authProvider.hospitalUser!.hospitalName, 'Apollo Speciality Hospital Pune');

      await hospitalProvider.setCurrentHospital(authProvider.hospitalUser!);
      expect(hospitalProvider.currentHospital.hospitalName, 'Apollo Speciality Hospital Pune');
      expect(hospitalProvider.currentHospital.city, 'Pune');
    });

    test('3. Multiple hospitals can exist independently', () async {
      final firestoreService = FirestoreService();

      final hospitalA = HospitalAccount(
        id: 'HOSP-A-001',
        hospitalName: 'Apollo Speciality Hospital',
        registrationNumber: 'MAH-PUN-001',
        hospitalType: 'Multi-specialty',
        address: 'Baner Road',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411045',
        officialPhone: '+91 20 6711 0000',
        officialEmail: 'apollo@pune.demo',
        adminName: 'Dr. Anita Desai',
        adminPhone: '+91 98230 11111',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      final hospitalB = HospitalAccount(
        id: 'HOSP-B-002',
        hospitalName: 'Jehangir Trauma Center',
        registrationNumber: 'MAH-PUN-002',
        hospitalType: 'Trauma & Emergency Center',
        address: 'Sassoon Road',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411001',
        officialPhone: '+91 20 6681 2000',
        officialEmail: 'jehangir@pune.demo',
        adminName: 'Dr. Cyrus Batliwala',
        adminPhone: '+91 98230 22222',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      await firestoreService.saveHospitalProfile(hospitalA);
      await firestoreService.saveHospitalProfile(hospitalB);

      final retrievedA = await firestoreService.getHospitalById('HOSP-A-001');
      final retrievedB = await firestoreService.getHospitalById('HOSP-B-002');

      expect(retrievedA, isNotNull);
      expect(retrievedB, isNotNull);
      expect(retrievedA!.hospitalName, 'Apollo Speciality Hospital');
      expect(retrievedB!.hospitalName, 'Jehangir Trauma Center');
      expect(retrievedA.id, isNot(equals(retrievedB.id)));

      final allHospitals = await firestoreService.getAllHospitals();
      expect(allHospitals.any((h) => h.id == 'HOSP-A-001'), isTrue);
      expect(allHospitals.any((h) => h.id == 'HOSP-B-002'), isTrue);
    });

    test('4. Hospital A loads Hospital A profile & Hospital B loads Hospital B profile', () async {
      final firestoreService = FirestoreService();
      final hospitalProvider = HospitalProvider();

      final hospA = HospitalAccount(
        id: 'HOSP-A-001',
        hospitalName: 'Hospital Alpha',
        registrationNumber: 'REG-ALPHA-01',
        hospitalType: 'Private Hospital',
        address: 'North Sector',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411014',
        officialPhone: '+91 20 1111 2222',
        officialEmail: 'alpha@hospital.demo',
        adminName: 'Admin Alpha',
        adminPhone: '+91 99999 11111',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      final hospB = HospitalAccount(
        id: 'HOSP-B-002',
        hospitalName: 'Hospital Beta',
        registrationNumber: 'REG-BETA-02',
        hospitalType: 'Government Hospital',
        address: 'South Sector',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411038',
        officialPhone: '+91 20 3333 4444',
        officialEmail: 'beta@hospital.demo',
        adminName: 'Admin Beta',
        adminPhone: '+91 99999 22222',
        verificationStatus: 'Verified',
        createdAt: DateTime.now(),
      );

      await firestoreService.saveHospitalProfile(hospA);
      await firestoreService.saveHospitalProfile(hospB);

      // Hospital A loads its profile
      await hospitalProvider.loadHospitalById('HOSP-A-001');
      expect(hospitalProvider.currentHospital.hospitalName, 'Hospital Alpha');
      expect(hospitalProvider.currentHospital.registrationNumber, 'REG-ALPHA-01');

      // Hospital B loads its profile
      await hospitalProvider.loadHospitalById('HOSP-B-002');
      expect(hospitalProvider.currentHospital.hospitalName, 'Hospital Beta');
      expect(hospitalProvider.currentHospital.registrationNumber, 'REG-BETA-02');
    });

    test('5. Hospital A cannot accidentally display Hospital B profile (Dashboard Isolation)', () async {
      final hospitalProvider = HospitalProvider();

      final hospA = HospitalAccount(
        id: 'HOSP-A',
        hospitalName: 'Apollo Hospital',
        registrationNumber: 'REG-A',
        hospitalType: 'Multi-specialty',
        address: 'West Sector',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411007',
        officialPhone: '+91 20 1000 0001',
        officialEmail: 'admin@apollo.demo',
        adminName: 'Dr. A',
        adminPhone: '+91 90000 00001',
        createdAt: DateTime.now(),
      );

      final hospB = HospitalAccount(
        id: 'HOSP-B',
        hospitalName: 'Fortis Hospital',
        registrationNumber: 'REG-B',
        hospitalType: 'Multi-specialty',
        address: 'East Sector',
        city: 'Pune',
        state: 'Maharashtra',
        pinCode: '411014',
        officialPhone: '+91 20 2000 0002',
        officialEmail: 'admin@fortis.demo',
        adminName: 'Dr. B',
        adminPhone: '+91 90000 00002',
        createdAt: DateTime.now(),
      );

      await hospitalProvider.setCurrentHospital(hospA);
      expect(hospitalProvider.currentHospital.id, 'HOSP-A');
      expect(hospitalProvider.currentHospital.hospitalName, isNot(equals(hospB.hospitalName)));
      expect(hospitalProvider.currentHospital.adminName, 'Dr. A');

      await hospitalProvider.setCurrentHospital(hospB);
      expect(hospitalProvider.currentHospital.id, 'HOSP-B');
      expect(hospitalProvider.currentHospital.hospitalName, isNot(equals(hospA.hospitalName)));
      expect(hospitalProvider.currentHospital.adminName, 'Dr. B');
    });

    test('6. Shared SOS: A user SOS is globally visible to all hospitals in the network', () async {
      final emergencyService = EmergencyService();
      final emergencyProvider = EmergencyProvider(emergencyService: emergencyService);

      // User creates emergency SOS
      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'USER-12345',
        medicalId: 'G1-MED-12345',
        patientName: 'Kunal Sharma',
        bloodGroup: 'O+',
        emergencyPhone: '+91 98765 43210',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(
          heartRate: 145,
          spo2: 94,
          respiratoryRate: 22,
        ),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Shivajinagar, Pune',
      );

      expect(incident, isNotNull);
      expect(incident.patientName, 'Kunal Sharma');
      expect(incident.status, EmergencyStatus.active);

      // Hospital A inspects active emergencies network
      final activeForHospitalA = await emergencyService.getActiveEmergencies();
      expect(activeForHospitalA.any((e) => e.incidentId == incident.incidentId), isTrue);

      // Hospital A responds to emergency
      await emergencyProvider.respondToEmergency(
        incidentId: incident.incidentId,
        doctorId: 'DOC-HOSP-A-01',
        doctorName: 'Dr. Anita Desai',
        respondingHospitalId: 'HOSP-A-001',
        respondingHospitalName: 'Apollo Speciality Hospital',
      );

      // Hospital B inspects active emergencies network
      final activeForHospitalB = await emergencyService.getActiveEmergencies();
      final sharedIncident = activeForHospitalB.firstWhere((e) => e.incidentId == incident.incidentId);

      // Hospital B sees the same SOS and its updated response info
      expect(sharedIncident, isNotNull);
      expect(sharedIncident.status, EmergencyStatus.responded);
      expect(sharedIncident.respondingHospitalId, 'HOSP-A-001');
      expect(sharedIncident.respondingHospitalName, 'Apollo Speciality Hospital');
      expect(sharedIncident.respondedDoctorName, 'Dr. Anita Desai');
      expect(sharedIncident.patientName, 'Kunal Sharma');
    });

    test('7. Existing Disaster Hub mock data behavior remains intact across disaster types', () async {
      final service = MockActiveUserMonitoringService();

      service.refreshUsers(disasterType: DisasterType.heatwave);
      final heatwaveCount = service.activeUsers.length;

      service.refreshUsers(disasterType: DisasterType.flood);
      final floodCount = service.activeUsers.length;

      service.refreshUsers(disasterType: DisasterType.cyclone);
      final cycloneCount = service.activeUsers.length;

      service.refreshUsers(disasterType: DisasterType.earthquake);
      final earthquakeCount = service.activeUsers.length;

      service.refreshUsers(disasterType: DisasterType.airPollution);
      final pollutionCount = service.activeUsers.length;

      // Verify each disaster type has its unique active user population
      expect(heatwaveCount, 128);
      expect(floodCount, 86);
      expect(cycloneCount, 146);
      expect(earthquakeCount, 64);
      expect(pollutionCount, 218);

      // Verify user counts are distinct and not hardcoded to a single global value
      final counts = {heatwaveCount, floodCount, cycloneCount, earthquakeCount, pollutionCount};
      expect(counts.length, 5);

      service.dispose();
    });

    testWidgets('8. Role Selection Screen renders updated registration labels', (tester) async {
      await tester.pumpWidget(createTestApp(const RoleSelectionScreen()));
      await tester.pumpAndSettle();

      // Verify replaced labels
      expect(find.text('Register as user'), findsOneWidget);
      expect(find.text('Register to Hospital'), findsOneWidget);

      // Verify old labels are gone
      expect(find.text('I am a Patient'), findsNothing);
      expect(find.text('I am a Hospital'), findsNothing);
    });

    testWidgets('9. User Registration Screen renders updated user terminology', (tester) async {
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Verify User Registration & Create User Account
      expect(find.text('User Registration'), findsOneWidget);
      expect(find.text('Create User Account'), findsOneWidget);
      expect(find.text('Create Patient Account'), findsNothing);
    });

    testWidgets('10. PatientHomeScreen renders G1care branding with logo & User Profile & Secure QR', (tester) async {
      await tester.pumpWidget(createTestApp(const PatientHomeScreen()));
      await tester.pumpAndSettle();

      // Verify G1care header with logo
      expect(find.text('G1care'), findsOneWidget);
      expect(find.text('G1Care Patient'), findsNothing);

      // Verify User Profile & Secure QR
      expect(find.text('User Profile & Secure QR'), findsOneWidget);
      expect(find.text('Patient Profile & Secure QR'), findsNothing);
    });

    testWidgets('11. Login Screen renders User Login, Hospital Login, and Disaster Mode', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // 1. Verify Disaster Mode is prominently available
      expect(find.text('Disaster Mode'), findsOneWidget);
      expect(find.text('Public Disaster Hub • No login required'), findsOneWidget);

      // 2. Verify segmented tabs for User Login and Hospital Login
      expect(find.text('User Login'), findsOneWidget);
      expect(find.text('Hospital Login'), findsOneWidget);

      // 3. Verify quick demo buttons
      expect(find.text('User Demo'), findsOneWidget);
      expect(find.text('Hospital Demo'), findsOneWidget);

      // 4. In User Login tab (default active):
      expect(find.text('Login as User'), findsOneWidget);
      expect(find.text('Register as user'), findsOneWidget);

      // 5. Switch to Hospital Login tab
      await tester.tap(find.text('Hospital Login'));
      await tester.pumpAndSettle();

      expect(find.text('Login as Hospital'), findsOneWidget);
      expect(find.text('Register to Hospital'), findsOneWidget);

      // 6. Test tapping Disaster Mode directly opens Disaster Hub without login
      await tester.tap(find.text('Disaster Mode'));
      await tester.pumpAndSettle();

      expect(find.text('G1Care DISASTER HUB'), findsOneWidget);
      expect(find.text('PUBLIC ACCESS • NO LOGIN REQUIRED'), findsOneWidget);
    });
  });
}
