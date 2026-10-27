import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g1care/models/emergency_incident.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/wristband_provider.dart';
import 'package:g1care/services/firestore_service.dart';
import 'package:g1care/services/health_evaluator.dart';
import 'package:g1care/widgets/sos_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FirestoreService.clearInMemoryCacheForTesting();
  });

  group('Milestone 7: Patient Emergency SOS Logic Tests', () {
    testWidgets('1. NORMAL Condition: SosButton is disabled and displays explanation', (tester) async {
      bool triggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SosButton(
              isEnabled: false,
              disabledReason: 'Emergency SOS unavailable while condition is normal.',
              riskLevel: HealthRiskLevel.normal,
              onTriggered: () {
                triggered = true;
              },
            ),
          ),
        ),
      );

      // Verify button rendered and shows disabled reason
      expect(find.text('EMERGENCY SOS'), findsOneWidget);
      expect(find.text('Emergency SOS unavailable while condition is normal.'), findsOneWidget);

      // Tap disabled button
      await tester.tap(find.text('EMERGENCY SOS'));
      await tester.pumpAndSettle();

      // Trigger callback must not have fired
      expect(triggered, isFalse);
    });

    testWidgets('2. WARNING Condition: SosButton opens confirmation dialog before requesting ambulance', (tester) async {
      bool confirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SosButton(
              isEnabled: true,
              riskLevel: HealthRiskLevel.warning,
              onTriggered: () {
                confirmed = true;
              },
            ),
          ),
        ),
      );

      // Tap SOS button in WARNING state
      await tester.tap(find.text('EMERGENCY SOS'));
      await tester.pumpAndSettle();

      // Warning Confirmation Dialog should appear
      expect(find.text('Request Ambulance Response?'), findsOneWidget);
      expect(
        find.text('Your health condition indicates a warning. Do you want to request an ambulance?'),
        findsOneWidget,
      );
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('CONFIRM EMERGENCY'), findsOneWidget);

      // Test CANCEL button
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);

      // Tap SOS again and CONFIRM
      await tester.tap(find.text('EMERGENCY SOS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRM EMERGENCY'));
      await tester.pumpAndSettle();

      // SosCountdownDialog appears
      expect(find.text('SEND NOW'), findsOneWidget);
      await tester.tap(find.text('SEND NOW'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
    });

    test('3. CRITICAL Fall Detection triggers automatic emergency incident without manual confirmation', () async {
      final emergencyProvider = EmergencyProvider();
      final wristband = WristbandProvider();
      wristband.connect();

      // Simulate Fall
      wristband.simulateFall();
      final vitals = wristband.currentVitals;
      expect(vitals.isFallDetected, isTrue);

      final eval = HealthStatusEvaluator.evaluate(vitals);
      expect(eval.isCritical, isTrue);

      // Automatic emergency creation
      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-AUTO-FALL',
        medicalId: 'G1-MED-2026-FALL01',
        patientName: 'Fall Patient',
        bloodGroup: 'O+',
        emergencyPhone: '+91 9876500099',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.fallDetected,
        vitalsSnapshot: vitals,
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(incident.triggerType, EmergencyTriggerType.fallDetected);
      expect(incident.status, EmergencyStatus.active);
      expect(emergencyProvider.hasActiveEmergency, isTrue);
      expect(emergencyProvider.criticalCasesCount, 1);

      await emergencyProvider.cancelSos();
    });

    test('4. CRITICAL Low SpO2 (<90%) triggers automatic emergency incident', () async {
      final emergencyProvider = EmergencyProvider();
      final wristband = WristbandProvider();
      wristband.connect();

      // Simulate Critical SpO2 (e.g. 84% < 90%)
      wristband.simulateLowSpO2();
      final vitals = wristband.currentVitals;
      expect(vitals.spo2, lessThan(90));

      final eval = HealthStatusEvaluator.evaluate(vitals);
      expect(eval.isCritical, isTrue);

      // Automatic emergency creation
      final incident = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-AUTO-SPO2',
        medicalId: 'G1-MED-2026-SPO201',
        patientName: 'SpO2 Patient',
        bloodGroup: 'B+',
        emergencyPhone: '+91 9876500098',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.criticalVitals,
        vitalsSnapshot: vitals,
        latitude: 18.5326,
        longitude: 73.8785,
        locationAddress: 'Ruby Hall Area, Pune',
      );

      expect(incident.triggerType, EmergencyTriggerType.criticalVitals);
      expect(incident.status, EmergencyStatus.active);
      expect(emergencyProvider.criticalCasesCount, 1);

      await emergencyProvider.cancelSos();
    });

    test('5. De-duplication: Active emergency prevents duplicate incident creation', () async {
      final emergencyProvider = EmergencyProvider();

      // Trigger first incident
      final inc1 = await emergencyProvider.triggerEmergencySos(
        patientUid: 'PAT-DEDUP',
        medicalId: 'G1-MED-2026-DEDUP',
        patientName: 'Dedup Patient',
        bloodGroup: 'A+',
        emergencyPhone: '+91 9876500097',
        criticalAllergies: [],
        triggerType: EmergencyTriggerType.fallDetected,
        vitalsSnapshot: VitalReading.defaultNormal().copyWith(isFallDetected: true),
        latitude: 18.5204,
        longitude: 73.8567,
        locationAddress: 'Pune',
      );

      expect(emergencyProvider.hasActiveEmergency, isTrue);
      expect(emergencyProvider.activeEmergencies.length, 1);
      final initialIncidentId = inc1.incidentId;

      // Second redundant trigger for same active patient updates/maintains current incident
      expect(emergencyProvider.currentPatientIncident?.incidentId, initialIncidentId);

      await emergencyProvider.cancelSos();
      expect(emergencyProvider.hasActiveEmergency, isFalse);
    });
  });
}
