enum HealthRiskLevel {
  normal,
  warning,
  critical;

  String get displayName {
    switch (this) {
      case HealthRiskLevel.normal:
        return 'LEVEL 1: NORMAL';
      case HealthRiskLevel.warning:
        return 'LEVEL 2: WARNING';
      case HealthRiskLevel.critical:
        return 'LEVEL 3: CRITICAL';
    }
  }

  String get shortLabel {
    switch (this) {
      case HealthRiskLevel.normal:
        return 'NORMAL';
      case HealthRiskLevel.warning:
        return 'WARNING';
      case HealthRiskLevel.critical:
        return 'CRITICAL';
    }
  }
}

class VitalReading {
  final int heartRate; // BPM
  final int spo2; // %
  final int respiratoryRate; // breaths per min
  final String ecgStatus; // 'Normal Sinus', 'Arrhythmia', 'Elevated ST', etc.
  final bool isFallDetected;
  final int batteryLevel; // %
  final DateTime timestamp;

  const VitalReading({
    required this.heartRate,
    required this.spo2,
    required this.respiratoryRate,
    required this.ecgStatus,
    required this.isFallDetected,
    required this.batteryLevel,
    required this.timestamp,
  });

  /// Default baseline normal reading
  factory VitalReading.defaultNormal() {
    return VitalReading(
      heartRate: 76,
      spo2: 98,
      respiratoryRate: 16,
      ecgStatus: 'Normal Sinus',
      isFallDetected: false,
      batteryLevel: 92,
      timestamp: DateTime.now(),
    );
  }

  VitalReading copyWith({
    int? heartRate,
    int? spo2,
    int? respiratoryRate,
    String? ecgStatus,
    bool? isFallDetected,
    int? batteryLevel,
    DateTime? timestamp,
  }) {
    return VitalReading(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      ecgStatus: ecgStatus ?? this.ecgStatus,
      isFallDetected: isFallDetected ?? this.isFallDetected,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heartRate': heartRate,
      'spo2': spo2,
      'respiratoryRate': respiratoryRate,
      'ecgStatus': ecgStatus,
      'isFallDetected': isFallDetected,
      'batteryLevel': batteryLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory VitalReading.fromMap(Map<String, dynamic> map) {
    return VitalReading(
      heartRate: (map['heartRate'] as num?)?.toInt() ?? 76,
      spo2: (map['spo2'] as num?)?.toInt() ?? 98,
      respiratoryRate: (map['respiratoryRate'] as num?)?.toInt() ?? 16,
      ecgStatus: map['ecgStatus'] as String? ?? 'Normal Sinus',
      isFallDetected: map['isFallDetected'] as bool? ?? false,
      batteryLevel: (map['batteryLevel'] as num?)?.toInt() ?? 90,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'VitalReading(HR: $heartRate BPM, SpO2: $spo2%, RR: $respiratoryRate/min, ECG: $ecgStatus, Fall: $isFallDetected, Bat: $batteryLevel%)';
  }
}
