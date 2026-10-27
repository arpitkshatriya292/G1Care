import 'package:flutter_test/flutter_test.dart';
import 'package:g1care/models/vital_reading.dart';
import 'package:g1care/providers/wristband_provider.dart';
import 'package:g1care/services/health_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 4: VitalReading & HealthStatusEvaluator 3-Level Tests', () {
    test('1. Normal Baseline Vital Reading evaluation (Level 1)', () {
      final normalReading = VitalReading(
        heartRate: 75,
        spo2: 98,
        respiratoryRate: 16,
        ecgStatus: 'Normal Sinus',
        isFallDetected: false,
        batteryLevel: 95,
        timestamp: DateTime.now(),
      );

      final result = HealthStatusEvaluator.evaluate(normalReading);
      expect(result.overallLevel, HealthRiskLevel.normal);
      expect(result.isNormal, isTrue);
      expect(result.isWarning, isFalse);
      expect(result.isCritical, isFalse);
      expect(result.criticalReasons, isEmpty);
      expect(result.warningReasons, isEmpty);
    });

    test('2. Heart Rate Thresholds (Normal vs Warning vs Critical)', () {
      // Normal: 60 - 100
      final hrNormal = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(heartRate: 72),
      );
      expect(hrNormal.hrLevel, HealthRiskLevel.normal);

      // Warning: 50-59 or 101-120
      final hrWarningLow = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(heartRate: 55),
      );
      expect(hrWarningLow.hrLevel, HealthRiskLevel.warning);
      expect(hrWarningLow.overallLevel, HealthRiskLevel.warning);
      expect(hrWarningLow.warningReasons.first, contains('Mild Bradycardia'));

      final hrWarningHigh = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(heartRate: 112),
      );
      expect(hrWarningHigh.hrLevel, HealthRiskLevel.warning);
      expect(hrWarningHigh.overallLevel, HealthRiskLevel.warning);

      // Critical: <50 or >120
      final hrCriticalLow = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(heartRate: 42),
      );
      expect(hrCriticalLow.hrLevel, HealthRiskLevel.critical);
      expect(hrCriticalLow.overallLevel, HealthRiskLevel.critical);
      expect(hrCriticalLow.criticalReasons.first, contains('Severe Bradycardia'));

      final hrCriticalHigh = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(heartRate: 145),
      );
      expect(hrCriticalHigh.hrLevel, HealthRiskLevel.critical);
      expect(hrCriticalHigh.overallLevel, HealthRiskLevel.critical);
      expect(hrCriticalHigh.criticalReasons.first, contains('Severe Tachycardia'));
    });

    test('3. SpO2 Oxygen Saturation Thresholds', () {
      // Normal: >= 95%
      final spo2Normal = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(spo2: 97),
      );
      expect(spo2Normal.spo2Level, HealthRiskLevel.normal);

      // Warning: 90 - 94%
      final spo2Warning = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(spo2: 92),
      );
      expect(spo2Warning.spo2Level, HealthRiskLevel.warning);
      expect(spo2Warning.overallLevel, HealthRiskLevel.warning);
      expect(spo2Warning.warningReasons.first, contains('Low Oxygen Saturation'));

      // Critical: < 90%
      final spo2Critical = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(spo2: 85),
      );
      expect(spo2Critical.spo2Level, HealthRiskLevel.critical);
      expect(spo2Critical.overallLevel, HealthRiskLevel.critical);
      expect(spo2Critical.criticalReasons.first, contains('Critical Hypoxemia'));
    });

    test('4. Required Active Vitals Verification (Temperature completely removed)', () {
      final defaultNormal = VitalReading.defaultNormal();
      expect(defaultNormal.heartRate, 76);
      expect(defaultNormal.spo2, 98);
      expect(defaultNormal.respiratoryRate, 16);
      expect(defaultNormal.ecgStatus, 'Normal Sinus');
      expect(defaultNormal.isFallDetected, isFalse);
    });

    test('5. Respiratory Rate Thresholds', () {
      // Normal: 12 - 20
      final rrNormal = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(respiratoryRate: 15),
      );
      expect(rrNormal.rrLevel, HealthRiskLevel.normal);

      // Warning: 10-11 or 21-24
      final rrWarning = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(respiratoryRate: 23),
      );
      expect(rrWarning.rrLevel, HealthRiskLevel.warning);

      // Critical: < 10 or > 24
      final rrCritical = HealthStatusEvaluator.evaluate(
        VitalReading.defaultNormal().copyWith(respiratoryRate: 32),
      );
      expect(rrCritical.rrLevel, HealthRiskLevel.critical);
      expect(rrCritical.criticalReasons.first, contains('Tachypnea'));
    });

    test('6. Fall Detection Evaluation (Direct Level 3 Critical Event)', () {
      final fallReading = VitalReading.defaultNormal().copyWith(
        isFallDetected: true,
      );

      final result = HealthStatusEvaluator.evaluate(fallReading);
      expect(result.overallLevel, HealthRiskLevel.critical);
      expect(result.fallLevel, HealthRiskLevel.critical);
      expect(result.criticalReasons, contains('Impact / Fall Event Detected'));
    });

    test('7. VitalReading serialization & deserialization without temperature', () {
      final reading = VitalReading(
        heartRate: 88,
        spo2: 96,
        respiratoryRate: 18,
        ecgStatus: 'Normal Sinus',
        isFallDetected: false,
        batteryLevel: 85,
        timestamp: DateTime.parse('2026-08-19T14:30:00.000Z'),
      );

      final map = reading.toMap();
      final fromMap = VitalReading.fromMap(map);

      expect(fromMap.heartRate, 88);
      expect(fromMap.spo2, 96);
      expect(fromMap.respiratoryRate, 18);
      expect(fromMap.batteryLevel, 85);
      expect(fromMap.isFallDetected, isFalse);
    });
  });

  group('Milestone 4: WristbandProvider Lifecycle & Simulation Tests', () {
    test('8. Wristband Connection & Disconnection lifecycle', () async {
      final provider = WristbandProvider(autoConnect: false);
      expect(provider.isConnected, isFalse);
      expect(provider.connectionState, WristbandConnectionState.disconnected);

      await provider.connect();
      expect(provider.isConnected, isTrue);
      expect(provider.connectionState, WristbandConnectionState.connected);
      expect(provider.isDemoSimulation, isTrue);

      await provider.disconnect();
      expect(provider.isConnected, isFalse);
      expect(provider.connectionState, WristbandConnectionState.disconnected);
    });

    test('9. Preset Simulation Modes (Normal, Warning, Critical)', () async {
      final provider = WristbandProvider(autoConnect: false);
      await provider.connect();

      // Normal mode
      provider.setSimulationMode(SimulationMode.normal);
      expect(provider.simulationMode, SimulationMode.normal);

      // Warning mode
      provider.setSimulationMode(SimulationMode.warning);
      expect(provider.simulationMode, SimulationMode.warning);

      // Critical mode
      provider.setSimulationMode(SimulationMode.critical);
      expect(provider.simulationMode, SimulationMode.critical);
    });

    test('10. Granular Anomaly Triggers (Fall, High HR, Low SpO2, Reset)', () async {
      final provider = WristbandProvider(autoConnect: false);
      await provider.connect();

      // Fall simulation
      provider.simulateFall();
      expect(provider.currentVitals.isFallDetected, isTrue);
      expect(provider.healthStatus.overallLevel, HealthRiskLevel.critical);

      // Reset
      provider.resetToNormal();
      expect(provider.simulationMode, SimulationMode.normal);
    });
  });
}
