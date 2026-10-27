import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:g1care/models/emergency_contact.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/medical_profile.dart';
import 'package:g1care/models/medicine_item.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/hospital_provider.dart';
import 'package:g1care/providers/medical_profile_provider.dart';
import 'package:g1care/screens/patient/edit_medical_profile_screen.dart';
import 'package:g1care/screens/hospital/hospital_edit_patient_medical_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/services/emergency_service.dart';
import 'package:g1care/services/firestore_service.dart';
import 'package:g1care/widgets/g1care_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
    EmergencyService.clearInMemoryEmergenciesForTesting();
  });

  group('Milestone 8: Data Ownership & Permissions Separation', () {
    test('Patient copyWithPatientDetails updates ONLY personal and ICE fields', () {
      final initial = MedicalProfile(
        uid: 'user-123',
        medicalId: 'G1-MED-998877',
        fullName: 'Original Name',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        phone: '+919876543210',
        address: '123 MG Road',
        emergencyContact: '+919876543211',
        emergencyContactInfo: const EmergencyContactInfo(
          name: 'Original ICE',
          phone: '+919876543211',
          relationship: 'Spouse',
        ),
        bloodGroup: 'B+',
        allergies: ['Penicillin'],
        medicines: const [
          MedicineItem(name: 'Metformin', dosage: '500mg', frequency: 'Daily'),
        ],
        medicalConditions: ['Type 2 Diabetes'],
        previousSurgeries: ['Appendectomy 2018'],
        previousIllnesses: ['Dengue 2020'],
        emergencyNotes: 'Critical DNR',
        primaryDoctor: 'Dr. A. Sharma',
        lastUpdatedBy: 'hospital',
        updatedAt: DateTime.now(),
      );

      final patientEdited = initial.copyWithPatientDetails(
        fullName: 'New Legal Name',
        dateOfBirth: '1992-05-15',
        gender: 'Female',
        phone: '+919999999999',
        address: '456 Residency Road, Pune',
        emergencyContactInfo: const EmergencyContactInfo(
          name: 'New Contact Name',
          phone: '+918888888888',
          relationship: 'Mother',
        ),
      );

      // Verify patient personal info was updated
      expect(patientEdited.fullName, 'New Legal Name');
      expect(patientEdited.dateOfBirth, '1992-05-15');
      expect(patientEdited.gender, 'Female');
      expect(patientEdited.phone, '+919999999999');
      expect(patientEdited.address, '456 Residency Road, Pune');
      expect(patientEdited.emergencyContactInfo.name, 'New Contact Name');
      expect(patientEdited.emergencyContactInfo.phone, '+918888888888');
      expect(patientEdited.emergencyContactInfo.relationship, 'Mother');
      expect(patientEdited.emergencyContact, '+918888888888');
      expect(patientEdited.lastUpdatedBy, 'patient');

      // Verify hospital clinical data was strictly preserved and NOT overwritten
      expect(patientEdited.bloodGroup, 'B+');
      expect(patientEdited.allergies, ['Penicillin']);
      expect(patientEdited.medicines.length, 1);
      expect(patientEdited.medicines.first.name, 'Metformin');
      expect(patientEdited.medicalConditions, ['Type 2 Diabetes']);
      expect(patientEdited.previousSurgeries, ['Appendectomy 2018']);
      expect(patientEdited.previousIllnesses, ['Dengue 2020']);
      expect(patientEdited.emergencyNotes, 'Critical DNR');
      expect(patientEdited.primaryDoctor, 'Dr. A. Sharma');
    });

    test('Hospital copyWithHospitalMedicalData updates clinical fields and preserves patient fields', () {
      final initial = MedicalProfile(
        uid: 'user-123',
        medicalId: 'G1-MED-998877',
        fullName: 'John Doe',
        dateOfBirth: '1990-01-01',
        gender: 'Male',
        phone: '+919876543210',
        address: '123 MG Road',
        emergencyContact: '+919876543211',
        emergencyContactInfo: const EmergencyContactInfo(
          name: 'Jane Doe',
          phone: '+919876543211',
          relationship: 'Spouse',
        ),
        bloodGroup: 'Unknown',
        allergies: [],
        medicines: [],
        medicalConditions: [],
        previousSurgeries: [],
        previousIllnesses: [],
        emergencyNotes: '',
        primaryDoctor: '',
        updatedAt: DateTime.now(),
      );

      final hospitalUpdated = initial.copyWithHospitalMedicalData(
        bloodGroup: 'O+',
        allergies: ['Peanuts', 'Sulfa Drugs'],
        medicines: const [
          MedicineItem(name: 'Aspirin', dosage: '75mg', frequency: 'Daily'),
          MedicineItem(name: 'Atorvastatin', dosage: '10mg', frequency: 'Nightly'),
        ],
        medicalConditions: ['Hypertension', 'Dyslipidemia'],
        previousSurgeries: ['Stent 2022'],
        previousIllnesses: ['COVID-19 2021'],
        emergencyNotes: 'High risk of bleeding. Keep calm.',
        primaryDoctor: 'Dr. Rajesh Rao (Ruby Hall Clinic)',
        hospitalTag: 'Ruby Hall Clinic',
      );

      // Verify hospital clinical fields were updated
      expect(hospitalUpdated.bloodGroup, 'O+');
      expect(hospitalUpdated.allergies, ['Peanuts', 'Sulfa Drugs']);
      expect(hospitalUpdated.medicines.length, 2);
      expect(hospitalUpdated.medicines[0].name, 'Aspirin');
      expect(hospitalUpdated.medicines[1].name, 'Atorvastatin');
      expect(hospitalUpdated.medicalConditions, ['Hypertension', 'Dyslipidemia']);
      expect(hospitalUpdated.previousSurgeries, ['Stent 2022']);
      expect(hospitalUpdated.previousIllnesses, ['COVID-19 2021']);
      expect(hospitalUpdated.emergencyNotes, 'High risk of bleeding. Keep calm.');
      expect(hospitalUpdated.primaryDoctor, 'Dr. Rajesh Rao (Ruby Hall Clinic)');
      expect(hospitalUpdated.lastUpdatedBy, 'hospital (Ruby Hall Clinic)');

      // Verify patient personal info was preserved
      expect(hospitalUpdated.fullName, 'John Doe');
      expect(hospitalUpdated.dateOfBirth, '1990-01-01');
      expect(hospitalUpdated.gender, 'Male');
      expect(hospitalUpdated.phone, '+919876543210');
      expect(hospitalUpdated.address, '123 MG Road');
      expect(hospitalUpdated.emergencyContactInfo.name, 'Jane Doe');
    });
  });

  group('Milestone 8: Real-Time Stream Synchronization', () {
    test('FirestoreService real-time stream delivers immediate profile updates to listeners', () async {
      final firestoreService = FirestoreService();
      final testUid = 'realtime-user-999';

      final initialProfile = MedicalProfile(
        uid: testUid,
        medicalId: 'G1-MED-LIVE01',
        fullName: 'Live Test Patient',
        dateOfBirth: '1995-01-01',
        gender: 'Male',
        phone: '+919876543210',
        address: 'MG Road, Pune',
        emergencyContact: '+919876543210',
        emergencyContactInfo: const EmergencyContactInfo(name: 'Contact', phone: '+919876543210', relationship: 'Friend'),
        bloodGroup: 'AB+',
        allergies: ['Dust'],
        medicines: [],
        medicalConditions: [],
        previousSurgeries: [],
        previousIllnesses: [],
        emergencyNotes: '',
        primaryDoctor: '',
        updatedAt: DateTime.now(),
      );

      await firestoreService.saveMedicalProfile(initialProfile);

      final emissions = <MedicalProfile>[];
      final subscription = firestoreService.streamMedicalProfile(testUid).listen((profile) {
        if (profile != null) {
          emissions.add(profile);
        }
      });

      // Update patient personal data
      final updatedPatient = initialProfile.copyWithPatientDetails(
        fullName: 'Live Test Patient (Updated)',
      );
      await firestoreService.updatePatientPersonalAndIceData(testUid, updatedPatient);

      // Hospital updates medical data
      final hospitalUpdated = updatedPatient.copyWithHospitalMedicalData(
        bloodGroup: 'AB-',
        allergies: ['Dust', 'Latex'],
        hospitalTag: 'City Hospital',
      );
      await firestoreService.updateHospitalManagedMedicalData(testUid, hospitalUpdated, hospitalName: 'City Hospital');

      // Wait a microsecond for broadcast stream delivery
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.last.fullName, 'Live Test Patient (Updated)');
      expect(emissions.last.bloodGroup, 'AB-');
      expect(emissions.last.allergies, contains('Latex'));
      expect(emissions.last.lastUpdatedBy, 'hospital (City Hospital)');

      await subscription.cancel();
    });
  });

  group('Milestone 8: Emergency Lifecycle & Debouncing', () {
    test('EmergencyStatus includes treated and discharged with correct active status', () {
      expect(EmergencyStatus.active.isActiveOrPending, isTrue);
      expect(EmergencyStatus.responded.isActiveOrPending, isTrue);
      expect(EmergencyStatus.treated.isActiveOrPending, isTrue);
      expect(EmergencyStatus.discharged.isActiveOrPending, isFalse);
      expect(EmergencyStatus.resolved.isActiveOrPending, isFalse);

      expect(EmergencyStatus.discharged.isResolvedOrDischarged, isTrue);
      expect(EmergencyStatus.resolved.isResolvedOrDischarged, isTrue);
      expect(EmergencyStatus.active.isResolvedOrDischarged, isFalse);
      expect(EmergencyStatus.treated.isResolvedOrDischarged, isFalse);
    });

    test('EmergencyProvider triggerEmergencySos debounces and prevents duplicate incidents', () async {
      final emergencyProvider = EmergencyProvider();
      const patientUid = 'patient-sos-debounce-01';

      final firstIncident = await emergencyProvider.triggerEmergencySos(
        patientUid: patientUid,
        medicalId: 'G1-MED-SOS01',
        patientName: 'Emergency Patient',
        bloodGroup: 'O+',
        emergencyPhone: '+919876543210',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(heartRate: 145, spo2: 88),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'FC Road, Pune',
      );

      expect(firstIncident.status, EmergencyStatus.active);
      expect(emergencyProvider.activeEmergencies.length, 1);

      // Trigger SOS again while already active
      final duplicateAttempt = await emergencyProvider.triggerEmergencySos(
        patientUid: patientUid,
        medicalId: 'G1-MED-SOS01',
        patientName: 'Emergency Patient',
        bloodGroup: 'O+',
        emergencyPhone: '+919876543210',
        criticalAllergies: ['Penicillin'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(heartRate: 150, spo2: 87),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'FC Road, Pune',
      );

      // Must reuse existing active incident rather than creating duplicate
      expect(duplicateAttempt.incidentId, firstIncident.incidentId);
      expect(emergencyProvider.activeEmergencies.length, 1);

      // Treat emergency
      await emergencyProvider.treatEmergency(firstIncident.incidentId);
      expect(emergencyProvider.currentPatientIncident?.status, EmergencyStatus.treated);

      // Discharge emergency removes from active network
      await emergencyProvider.dischargeEmergency(firstIncident.incidentId);
      expect(emergencyProvider.activeEmergencies.any((e) => e.incidentId == firstIncident.incidentId), isFalse);
      expect(emergencyProvider.currentPatientIncident, isNull);
      emergencyProvider.dispose();
    });
  });

  group('Milestone 8: UI Permission Restrictions & Layout Verification', () {
    testWidgets('EditMedicalProfileScreen renders editable Sections 1 & 2 and read-only Section 3+ with badges', (tester) async {
      final profileProvider = MedicalProfileProvider();
      final testProfile = MedicalProfile(
        uid: 'user-widget-test',
        medicalId: 'G1-MED-WIDGET01',
        fullName: 'Rahul Sharma',
        dateOfBirth: '1988-03-21',
        gender: 'Male',
        phone: '+919876543210',
        address: 'Koregaon Park, Pune',
        emergencyContact: '+919876543211',
        emergencyContactInfo: const EmergencyContactInfo(
          name: 'Priya Sharma',
          phone: '+919876543211',
          relationship: 'Spouse',
        ),
        bloodGroup: 'B+',
        allergies: ['Penicillin', 'Sulfa'],
        medicines: const [
          MedicineItem(name: 'Metformin', dosage: '500mg', frequency: 'Daily'),
        ],
        medicalConditions: ['Type 2 Diabetes'],
        previousSurgeries: ['Appendectomy 2015'],
        previousIllnesses: ['Dengue 2019'],
        primaryDoctor: 'Dr. Kulkarni',
        emergencyNotes: 'Keep patient hydrated.',
        updatedAt: DateTime.now(),
      );

      profileProvider.setProfileForTesting(testProfile);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileProvider),
          ],
          child: const MaterialApp(
            home: EditMedicalProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Section 1 & 2 Editable tags
      expect(find.text('1. Personal Details'), findsOneWidget);
      expect(find.text('2. In Case of Emergency (ICE) Contact'), findsOneWidget);
      expect(find.text('EDITABLE'), findsNWidgets(2));

      // Check Hospital Managed badges
      expect(find.text('HOSPITAL MANAGED'), findsWidgets);
      expect(find.text('HOSPITAL-MANAGED MEDICAL DATA (READ-ONLY)'), findsOneWidget);

      // Check that patient can see their hospital data displayed
      expect(find.text('B+'), findsOneWidget);
      expect(find.text('Penicillin'), findsOneWidget);
      expect(find.text('Sulfa'), findsOneWidget);
      expect(find.text('Type 2 Diabetes'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);
      expect(find.text('Dr. Kulkarni'), findsOneWidget);

      // Verify no add buttons or dropdowns for clinical data exist for patient
      expect(find.text('+ Add Drug'), findsNothing);
      expect(find.text('Add Medication'), findsNothing);
    });

    testWidgets('HospitalEditPatientMedicalScreen allows authorized staff to edit medical data', (tester) async {
      final firestoreService = FirestoreService();
      final hospitalProvider = HospitalProvider();
      final profileProvider = MedicalProfileProvider();

      final initialProfile = MedicalProfile(
        uid: 'patient-hosp-edit-test',
        medicalId: 'G1-MED-HOSP01',
        fullName: 'Sunita Patil',
        dateOfBirth: '1985-05-10',
        gender: 'Female',
        phone: '+919876543210',
        address: 'Aundh, Pune',
        emergencyContact: '+919876543210',
        emergencyContactInfo: const EmergencyContactInfo(name: 'ICE Contact', phone: '+919876543210', relationship: 'Parent'),
        bloodGroup: 'A+',
        allergies: [],
        medicines: [],
        medicalConditions: [],
        previousSurgeries: [],
        previousIllnesses: [],
        emergencyNotes: '',
        primaryDoctor: '',
        updatedAt: DateTime.now(),
      );
      await firestoreService.saveMedicalProfile(initialProfile);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: hospitalProvider),
            ChangeNotifierProvider.value(value: profileProvider),
          ],
          child: const MaterialApp(
            home: HospitalEditPatientMedicalScreen(
              medicalId: 'G1-MED-HOSP01',
              patientUid: 'patient-hosp-edit-test',
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify hospital editor loaded
      expect(find.text('Update Patient Medical Record'), findsOneWidget);
      expect(find.text('Critical Emergency Data'), findsOneWidget);
      expect(find.text('Current Prescriptions'), findsOneWidget);
      expect(find.text('Add Drug'), findsOneWidget);
      expect(find.text('SAVE & SYNC PATIENT MEDICAL DATA'), findsOneWidget);
    });
  });

  group('Milestone 8: Exact SOS Test Scenarios (A - E)', () {
    test('TEST A & E: Patient activates SOS -> persists across cold app restart -> state is restored', () async {
      final emergencyService = EmergencyService();
      const testPatientUid = 'patient-test-a-uid';
      const testMedicalId = 'G1-MED-TESTA';

      // 1. Patient activates SOS
      final session1 = EmergencyProvider();
      final incident = await session1.triggerEmergencySos(
        patientUid: testPatientUid,
        medicalId: testMedicalId,
        patientName: 'Kshat TestA',
        bloodGroup: 'O+',
        emergencyPhone: '+919876543210',
        criticalAllergies: ['Latex'],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(heartRate: 155, spo2: 85),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune City Center',
      );

      expect(session1.hasActiveEmergency, isTrue);
      expect(session1.currentPatientIncident?.incidentId, incident.incidentId);
      expect(session1.currentPatientIncident?.status.isActiveOrPending, isTrue);

      // Verify stored in Firestore / EmergencyService
      final activeInDb = await emergencyService.findActiveEmergencyForPatient(testPatientUid);
      expect(activeInDb, isNotNull);
      expect(activeInDb!.incidentId, incident.incidentId);

      // 2. Simulate complete app termination
      session1.dispose();

      // 3. Cold App Startup: fresh provider restores active emergency
      final session2 = EmergencyProvider();
      expect(session2.hasActiveEmergency, isFalse);

      await session2.syncPatientEmergencyState(testPatientUid);

      // State MUST be restored as CRITICAL / active
      expect(session2.hasActiveEmergency, isTrue);
      expect(session2.currentPatientIncident, isNotNull);
      expect(session2.currentPatientIncident!.incidentId, incident.incidentId);
      expect(session2.currentPatientIncident!.status.isActiveOrPending, isTrue);
      expect(session2.currentPatientIncident!.vitalsSnapshot.heartRate, 155);

      session2.dispose();
    });

    test('TEST B: Patient activates SOS -> closes app -> hospital resolves/discharges SOS -> status becomes resolved', () async {
      final emergencyService = EmergencyService();
      const testPatientUid = 'patient-test-b-uid';
      const testMedicalId = 'G1-MED-TESTB';

      final session1 = EmergencyProvider();
      final incident = await session1.triggerEmergencySos(
        patientUid: testPatientUid,
        medicalId: testMedicalId,
        patientName: 'Kshat TestB',
        bloodGroup: 'A+',
        emergencyPhone: '+919876543210',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'FC Road, Pune',
      );

      expect(session1.hasActiveEmergency, isTrue);

      // App is closed
      session1.dispose();

      // Hospital resolves/discharges incident
      final hospitalSession = EmergencyProvider();
      await hospitalSession.dischargeEmergency(incident.incidentId);
      hospitalSession.dispose();

      // Patient reopens app
      final session2 = EmergencyProvider();
      await session2.syncPatientEmergencyState(testPatientUid);

      // SOS is resolved, patient status is normal
      expect(session2.hasActiveEmergency, isFalse);
      expect(session2.currentPatientIncident, isNull);

      final activeInDb = await emergencyService.findActiveEmergencyForPatient(testPatientUid);
      expect(activeInDb, isNull);

      session2.dispose();
    });

    test('TEST C: Patient activates SOS -> patient manually cancels SOS -> emergency is cancelled', () async {
      final emergencyService = EmergencyService();
      const testPatientUid = 'patient-test-c-uid';
      const testMedicalId = 'G1-MED-TESTC';

      final session = EmergencyProvider();
      final incident = await session.triggerEmergencySos(
        patientUid: testPatientUid,
        medicalId: testMedicalId,
        patientName: 'Kshat TestC',
        bloodGroup: 'B+',
        emergencyPhone: '+919876543210',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Camp, Pune',
      );

      expect(session.hasActiveEmergency, isTrue);
      expect(incident.incidentId.isNotEmpty, isTrue);

      // Patient manually cancels SOS
      await session.cancelSos();

      expect(session.hasActiveEmergency, isFalse);
      expect(session.currentPatientIncident, isNull);

      final activeInDb = await emergencyService.findActiveEmergencyForPatient(testPatientUid);
      expect(activeInDb, isNull);

      session.dispose();
    });

    test('TEST D: Patient activates SOS -> hospital marks patient reached/arrived/treated -> state updates', () async {
      const testPatientUid = 'patient-test-d-uid';
      const testMedicalId = 'G1-MED-TESTD';

      final session = EmergencyProvider();
      final incident = await session.triggerEmergencySos(
        patientUid: testPatientUid,
        medicalId: testMedicalId,
        patientName: 'Kshat TestD',
        bloodGroup: 'AB+',
        emergencyPhone: '+919876543210',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.manualSos,
        vitalsSnapshot: VitalReading.defaultNormal(),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Kothrud, Pune',
      );

      expect(session.hasActiveEmergency, isTrue);

      // Hospital marks treated
      await session.treatEmergency(incident.incidentId);
      expect(session.currentPatientIncident?.status, EmergencyStatus.treated);

      // Hospital discharges case
      await session.dischargeEmergency(incident.incidentId);
      expect(session.hasActiveEmergency, isFalse);
      expect(session.currentPatientIncident, isNull);

      session.dispose();
    });
  });

  group('Milestone 8: Visual Branding & Splash Screen', () {
    testWidgets('G1CareLogo widget renders vector emblem and typography correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: G1CareLogo(
                size: 80,
                showText: true,
                showTagline: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(G1CareLogo), findsOneWidget);
      expect(find.text('Smart Health & Disaster Response System'), findsOneWidget);
    });
  });
}


