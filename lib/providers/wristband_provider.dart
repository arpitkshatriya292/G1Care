import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/vital_reading.dart';
import '../services/health_evaluator.dart';

enum WristbandConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error;

  String get displayName {
    switch (this) {
      case WristbandConnectionState.disconnected:
        return 'Disconnected';
      case WristbandConnectionState.scanning:
        return 'Scanning for Devices...';
      case WristbandConnectionState.connecting:
        return 'Pairing Wristband...';
      case WristbandConnectionState.connected:
        return 'CONNECTED';
      case WristbandConnectionState.error:
        return 'Connection Error';
    }
  }
}

enum SimulationMode {
  normal,
  warning,
  critical,
}

abstract class IWristbandProvider extends ChangeNotifier {
  WristbandConnectionState get connectionState;
  bool get isConnected;
  VitalReading get currentVitals;
  HealthEvaluationResult get healthStatus;
  SimulationMode get simulationMode;
  bool get isDemoSimulation;
  String get deviceId;

  Future<void> connect();
  Future<void> disconnect();
  void setSimulationMode(SimulationMode mode);
  void simulateHighHeartRate();
  void simulateLowSpO2();
  void simulateAbnormalRespiratoryRate();
  void simulateFall();
  void resetToNormal();
}

class WristbandProvider extends ChangeNotifier implements IWristbandProvider {
  WristbandConnectionState _connectionState = WristbandConnectionState.disconnected;
  SimulationMode _simulationMode = SimulationMode.normal;
  final bool _isDemoSimulation = true;
  final String _deviceId = 'G1-WB-9942 (Digital BLE)';

  VitalReading _currentVitals = VitalReading.defaultNormal();
  HealthEvaluationResult _healthStatus = HealthStatusEvaluator.evaluate(VitalReading.defaultNormal());

  Timer? _telemetryTimer;
  Timer? _transitionTimer;
  final Random _random = Random();

  // Target targets for smooth interpolation
  int _targetHr = 76;
  int _targetSpo2 = 98;
  int _targetRr = 16;
  String _targetEcg = 'Normal Sinus';
  bool _targetFall = false;

  WristbandProvider({bool autoConnect = true}) {
    if (autoConnect) {
      connect();
    }
  }

  @override
  WristbandConnectionState get connectionState => _connectionState;

  @override
  bool get isConnected => _connectionState == WristbandConnectionState.connected;

  @override
  VitalReading get currentVitals => _currentVitals;

  @override
  HealthEvaluationResult get healthStatus => _healthStatus;

  @override
  SimulationMode get simulationMode => _simulationMode;

  @override
  bool get isDemoSimulation => _isDemoSimulation;

  @override
  String get deviceId => _deviceId;

  @override
  Future<void> connect() async {
    if (_connectionState == WristbandConnectionState.connected) return;

    _connectionState = WristbandConnectionState.connecting;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _connectionState = WristbandConnectionState.connected;
    _startTelemetryStream();
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    _stopTelemetryStream();
    _connectionState = WristbandConnectionState.disconnected;
    notifyListeners();
  }

  void _startTelemetryStream() {
    _telemetryTimer?.cancel();
    // Update every 2 seconds with realistic slight natural fluctuation
    _telemetryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _applyNaturalFluctuation();
    });
  }

  void _stopTelemetryStream() {
    _telemetryTimer?.cancel();
    _transitionTimer?.cancel();
  }

  void _applyNaturalFluctuation() {
    if (!isConnected) return;

    // Small natural jitter around target values
    int newHr = _currentVitals.heartRate;
    int newSpo2 = _currentVitals.spo2;
    int newRr = _currentVitals.respiratoryRate;

    // Gradual approach towards target
    if (newHr < _targetHr) {
      newHr += min(2, _targetHr - newHr);
    } else if (newHr > _targetHr) {
      newHr -= min(2, newHr - _targetHr);
    } else {
      newHr += _random.nextInt(3) - 1; // -1, 0, +1
    }

    if (newSpo2 < _targetSpo2) {
      newSpo2 += min(1, _targetSpo2 - newSpo2);
    } else if (newSpo2 > _targetSpo2) {
      newSpo2 -= min(1, newSpo2 - _targetSpo2);
    }

    if (newRr < _targetRr) {
      newRr += min(1, _targetRr - newRr);
    } else if (newRr > _targetRr) {
      newRr -= min(1, newRr - _targetRr);
    }

    _currentVitals = _currentVitals.copyWith(
      heartRate: newHr.clamp(30, 220),
      spo2: newSpo2.clamp(70, 100),
      respiratoryRate: newRr.clamp(6, 45),
      ecgStatus: _targetEcg,
      isFallDetected: _targetFall,
      timestamp: DateTime.now(),
    );

    _healthStatus = HealthStatusEvaluator.evaluate(_currentVitals);
    notifyListeners();
  }

  void _smoothTransitionToTargets({
    required int hr,
    required int spo2,
    required int rr,
    required String ecg,
    required bool fall,
    int steps = 5,
  }) {
    _transitionTimer?.cancel();
    _targetHr = hr;
    _targetSpo2 = spo2;
    _targetRr = rr;
    _targetEcg = ecg;
    _targetFall = fall;

    int currentStep = 0;
    _transitionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      currentStep++;
      _applyNaturalFluctuation();
      if (currentStep >= steps) {
        timer.cancel();
      }
    });
  }

  @override
  void setSimulationMode(SimulationMode mode) {
    _simulationMode = mode;
    switch (mode) {
      case SimulationMode.normal:
        resetToNormal();
        break;
      case SimulationMode.warning:
        _smoothTransitionToTargets(
          hr: 110,
          spo2: 92,
          rr: 22,
          ecg: 'Borderline Tachycardia',
          fall: false,
        );
        break;
      case SimulationMode.critical:
        _smoothTransitionToTargets(
          hr: 135,
          spo2: 86,
          rr: 28,
          ecg: 'Ventricular Arrhythmia',
          fall: false,
        );
        break;
    }
  }

  @override
  void simulateHighHeartRate() {
    _simulationMode = SimulationMode.critical;
    _targetHr = 138;
    _currentVitals = _currentVitals.copyWith(
      heartRate: 138,
      ecgStatus: 'Supraventricular Tachycardia',
      timestamp: DateTime.now(),
    );
    _healthStatus = HealthStatusEvaluator.evaluate(_currentVitals);
    notifyListeners();
  }

  @override
  void simulateLowSpO2() {
    _simulationMode = SimulationMode.critical;
    _targetSpo2 = 84;
    _currentVitals = _currentVitals.copyWith(
      spo2: 84,
      heartRate: _currentVitals.heartRate + 15,
      timestamp: DateTime.now(),
    );
    _healthStatus = HealthStatusEvaluator.evaluate(_currentVitals);
    notifyListeners();
  }

  @override
  void simulateAbnormalRespiratoryRate() {
    _simulationMode = SimulationMode.critical;
    _targetRr = 30;
    _currentVitals = _currentVitals.copyWith(
      respiratoryRate: 30,
      timestamp: DateTime.now(),
    );
    _healthStatus = HealthStatusEvaluator.evaluate(_currentVitals);
    notifyListeners();
  }

  @override
  void simulateFall() {
    _simulationMode = SimulationMode.critical;
    _targetFall = true;
    _currentVitals = _currentVitals.copyWith(
      isFallDetected: true,
      heartRate: 115,
      timestamp: DateTime.now(),
    );
    _healthStatus = HealthStatusEvaluator.evaluate(_currentVitals);
    notifyListeners();
  }

  @override
  void resetToNormal() {
    _simulationMode = SimulationMode.normal;
    _smoothTransitionToTargets(
      hr: 76,
      spo2: 98,
      rr: 16,
      ecg: 'Normal Sinus',
      fall: false,
    );
  }

  @override
  void dispose() {
    _stopTelemetryStream();
    super.dispose();
  }
}
