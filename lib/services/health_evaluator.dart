import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/vital_reading.dart';

class VitalThresholdConfig {
  // Heart Rate (BPM)
  static const int hrNormalMin = 60;
  static const int hrNormalMax = 100;
  static const int hrWarningLowMin = 50;
  static const int hrWarningHighMax = 120;

  // SpO2 (%)
  static const int spo2NormalMin = 95;
  static const int spo2WarningMin = 90;

  // Respiratory Rate (/min)
  static const int rrNormalMin = 12;
  static const int rrNormalMax = 20;
  static const int rrWarningLowMin = 10;
  static const int rrWarningHighMax = 24;
}

class HealthEvaluationResult {
  final HealthRiskLevel overallLevel;
  final List<String> criticalReasons;
  final List<String> warningReasons;
  final HealthRiskLevel hrLevel;
  final HealthRiskLevel spo2Level;
  final HealthRiskLevel rrLevel;
  final HealthRiskLevel fallLevel;

  const HealthEvaluationResult({
    required this.overallLevel,
    required this.criticalReasons,
    required this.warningReasons,
    required this.hrLevel,
    required this.spo2Level,
    required this.rrLevel,
    required this.fallLevel,
  });

  bool get isCritical => overallLevel == HealthRiskLevel.critical;
  bool get isWarning => overallLevel == HealthRiskLevel.warning;
  bool get isNormal => overallLevel == HealthRiskLevel.normal;

  String get summaryText {
    if (criticalReasons.isNotEmpty) {
      return criticalReasons.join(' • ');
    } else if (warningReasons.isNotEmpty) {
      return warningReasons.join(' • ');
    } else {
      return 'All health vitals are within normal stable limits.';
    }
  }

  Color get statusColor {
    switch (overallLevel) {
      case HealthRiskLevel.normal:
        return AppColors.successGreen;
      case HealthRiskLevel.warning:
        return AppColors.warningOrange;
      case HealthRiskLevel.critical:
        return AppColors.emergencyRed;
    }
  }

  Color get statusBgColor {
    switch (overallLevel) {
      case HealthRiskLevel.normal:
        return AppColors.successGreenBg;
      case HealthRiskLevel.warning:
        return AppColors.warningOrangeBg;
      case HealthRiskLevel.critical:
        return AppColors.emergencyRedBg;
    }
  }

  IconData get statusIcon {
    switch (overallLevel) {
      case HealthRiskLevel.normal:
        return Icons.check_circle_rounded;
      case HealthRiskLevel.warning:
        return Icons.warning_rounded;
      case HealthRiskLevel.critical:
        return Icons.emergency_rounded;
    }
  }
}

class HealthStatusEvaluator {
  /// Evaluates a single VitalReading and returns structured risk analysis
  static HealthEvaluationResult evaluate(VitalReading reading) {
    final criticalReasons = <String>[];
    final warningReasons = <String>[];

    // 1. Heart Rate Evaluation
    HealthRiskLevel hrLevel = HealthRiskLevel.normal;
    if (reading.heartRate < VitalThresholdConfig.hrWarningLowMin ||
        reading.heartRate > VitalThresholdConfig.hrWarningHighMax) {
      hrLevel = HealthRiskLevel.critical;
      criticalReasons.add(
        reading.heartRate < VitalThresholdConfig.hrWarningLowMin
            ? 'Severe Bradycardia (${reading.heartRate} BPM < 50)'
            : 'Severe Tachycardia (${reading.heartRate} BPM > 120)',
      );
    } else if (reading.heartRate < VitalThresholdConfig.hrNormalMin ||
        reading.heartRate > VitalThresholdConfig.hrNormalMax) {
      hrLevel = HealthRiskLevel.warning;
      warningReasons.add(
        reading.heartRate < VitalThresholdConfig.hrNormalMin
            ? 'Mild Bradycardia (${reading.heartRate} BPM)'
            : 'Elevated Heart Rate (${reading.heartRate} BPM)',
      );
    }

    // 2. SpO2 Evaluation
    HealthRiskLevel spo2Level = HealthRiskLevel.normal;
    if (reading.spo2 < VitalThresholdConfig.spo2WarningMin) {
      spo2Level = HealthRiskLevel.critical;
      criticalReasons.add('Critical Hypoxemia (SpO2 ${reading.spo2}% < 90%)');
    } else if (reading.spo2 < VitalThresholdConfig.spo2NormalMin) {
      spo2Level = HealthRiskLevel.warning;
      warningReasons.add('Low Oxygen Saturation (SpO2 ${reading.spo2}%)');
    }

    // 3. Respiratory Rate Evaluation
    HealthRiskLevel rrLevel = HealthRiskLevel.normal;
    if (reading.respiratoryRate < VitalThresholdConfig.rrWarningLowMin ||
        reading.respiratoryRate > VitalThresholdConfig.rrWarningHighMax) {
      rrLevel = HealthRiskLevel.critical;
      criticalReasons.add(
        reading.respiratoryRate < VitalThresholdConfig.rrWarningLowMin
            ? 'Severe Bradypnea (${reading.respiratoryRate}/min < 10)'
            : 'Severe Tachypnea (${reading.respiratoryRate}/min > 24)',
      );
    } else if (reading.respiratoryRate < VitalThresholdConfig.rrNormalMin ||
        reading.respiratoryRate > VitalThresholdConfig.rrNormalMax) {
      rrLevel = HealthRiskLevel.warning;
      warningReasons.add('Abnormal Resp. Rate (${reading.respiratoryRate}/min)');
    }

    // 4. Fall Detection Evaluation
    HealthRiskLevel fallLevel = HealthRiskLevel.normal;
    if (reading.isFallDetected) {
      fallLevel = HealthRiskLevel.critical;
      criticalReasons.add('Impact / Fall Event Detected');
    }

    // Determine overall level (highest priority)
    HealthRiskLevel overall = HealthRiskLevel.normal;
    if (criticalReasons.isNotEmpty) {
      overall = HealthRiskLevel.critical;
    } else if (warningReasons.isNotEmpty) {
      overall = HealthRiskLevel.warning;
    }

    return HealthEvaluationResult(
      overallLevel: overall,
      criticalReasons: criticalReasons,
      warningReasons: warningReasons,
      hrLevel: hrLevel,
      spo2Level: spo2Level,
      rrLevel: rrLevel,
      fallLevel: fallLevel,
    );
  }
}
