import 'dart:async';

/// Fall event payload structure for future wristband hardware accelerometer integration
class FallEvent {
  final bool isFallDetected;
  final double confidence; // 0.0 - 1.0 confidence score from on-device sensor model
  final DateTime timestamp;
  final String source; // e.g. 'Wristband 6-Axis IMU Sensor'

  const FallEvent({
    required this.isFallDetected,
    required this.confidence,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
        'isFallDetected': isFallDetected,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
      };
}

/// Abstract interface for Fall Detection service
abstract class IFallDetectionService {
  Stream<FallEvent> get fallStream;
  bool get isMonitoring;
  void startMonitoring();
  void stopMonitoring();
  void triggerMockFallForTesting({double confidence = 0.95});
}

/// Fall Detection Service Foundation
class FallDetectionService implements IFallDetectionService {
  final StreamController<FallEvent> _controller = StreamController<FallEvent>.broadcast();
  bool _isMonitoring = false;

  @override
  Stream<FallEvent> get fallStream => _controller.stream;

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  void startMonitoring() {
    _isMonitoring = true;
  }

  @override
  void stopMonitoring() {
    _isMonitoring = false;
  }

  /// Explicitly identified mock fall event for automated testing & verification only
  @override
  void triggerMockFallForTesting({double confidence = 0.95}) {
    if (!_isMonitoring) return;
    _controller.add(FallEvent(
      isFallDetected: true,
      confidence: confidence,
      timestamp: DateTime.now(),
      source: 'Mock Simulated Accelerometer (Testing Only)',
    ));
  }

  void dispose() {
    _controller.close();
  }
}
