import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Disaster Types supported by G1Care SIH26
enum DisasterType {
  heatwave,
  flood,
  cyclone,
  earthquake,
  airPollution,
  other;

  String get displayName {
    switch (this) {
      case DisasterType.heatwave:
        return 'HEATWAVE';
      case DisasterType.flood:
        return 'FLOOD';
      case DisasterType.cyclone:
        return 'CYCLONE';
      case DisasterType.earthquake:
        return 'EARTHQUAKE';
      case DisasterType.airPollution:
        return 'SEVERE AIR POLLUTION';
      case DisasterType.other:
        return 'ENVIRONMENTAL EMERGENCY';
    }
  }

  IconData get icon {
    switch (this) {
      case DisasterType.heatwave:
        return Icons.wb_sunny_rounded;
      case DisasterType.flood:
        return Icons.water_rounded;
      case DisasterType.cyclone:
        return Icons.cyclone_rounded;
      case DisasterType.earthquake:
        return Icons.vibration_rounded;
      case DisasterType.airPollution:
        return Icons.masks_rounded;
      case DisasterType.other:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DisasterType.heatwave:
        return const Color(0xFFE65100);
      case DisasterType.flood:
        return const Color(0xFF0288D1);
      case DisasterType.cyclone:
        return const Color(0xFF7B1FA2);
      case DisasterType.earthquake:
        return const Color(0xFF6D4C41);
      case DisasterType.airPollution:
        return const Color(0xFF5D4037);
      case DisasterType.other:
        return AppColors.warningOrange;
    }
  }

  double get centerLatitude {
    switch (this) {
      case DisasterType.heatwave:
        return 18.5308;
      case DisasterType.flood:
        return 18.5204;
      case DisasterType.cyclone:
        return 18.5380;
      case DisasterType.earthquake:
        return 18.5170;
      case DisasterType.airPollution:
        return 18.5080;
      case DisasterType.other:
        return 18.5240;
    }
  }

  double get centerLongitude {
    switch (this) {
      case DisasterType.heatwave:
        return 73.8475;
      case DisasterType.flood:
        return 73.8567;
      case DisasterType.cyclone:
        return 73.8320;
      case DisasterType.earthquake:
        return 73.8560;
      case DisasterType.airPollution:
        return 73.8680;
      case DisasterType.other:
        return 73.8540;
    }
  }

  double get hazardRadiusMeters {
    switch (this) {
      case DisasterType.heatwave:
        return 1800;
      case DisasterType.flood:
        return 1400;
      case DisasterType.cyclone:
        return 2200;
      case DisasterType.earthquake:
        return 1200;
      case DisasterType.airPollution:
        return 2500;
      case DisasterType.other:
        return 1500;
    }
  }

  String get defaultAffectedArea {
    switch (this) {
      case DisasterType.heatwave:
        return 'Urban Concrete Core & Transit Corridors, Pune';
      case DisasterType.flood:
        return 'Mula-Mutha River Basin & Low-Lying Ghats, Pune';
      case DisasterType.cyclone:
        return 'West Ridge Corridor & Elevated Perimeter, Pune';
      case DisasterType.earthquake:
        return 'Old City Dense Heritage Sector & Peths, Pune';
      case DisasterType.airPollution:
        return 'Industrial Transit Ring & Swargate Corridor, Pune';
      case DisasterType.other:
        return 'Pune Metropolitan Region';
    }
  }
}

/// Disaster Severity rating from authorized disaster feeds
enum DisasterSeverity {
  low,
  moderate,
  high,
  severe;

  String get displayName {
    switch (this) {
      case DisasterSeverity.low:
        return 'Low';
      case DisasterSeverity.moderate:
        return 'Moderate';
      case DisasterSeverity.high:
        return 'High';
      case DisasterSeverity.severe:
        return 'Severe / Alert';
    }
  }
}

/// Active disaster context received from authorized source
class DisasterEvent {
  final DisasterType type;
  final DisasterSeverity severity;
  final String affectedArea;
  final bool isInsideAffectedArea;
  final String source;
  final DateTime timestamp;
  final bool isActive;
  final String advisory;

  const DisasterEvent({
    required this.type,
    required this.severity,
    required this.affectedArea,
    required this.isInsideAffectedArea,
    required this.source,
    required this.timestamp,
    required this.isActive,
    required this.advisory,
  });

  factory DisasterEvent.mock({
    DisasterType type = DisasterType.flood,
    DisasterSeverity severity = DisasterSeverity.high,
    String? affectedArea,
    bool isInside = true,
  }) {
    String advisory;
    switch (type) {
      case DisasterType.heatwave:
        advisory = 'Severe heatwave conditions. Limit outdoor exposure between 11 AM - 4 PM. Stay hydrated.';
        break;
      case DisasterType.flood:
        advisory = 'Rising river water levels and localized waterlogging reported. Avoid low-lying riverbanks and underpasses.';
        break;
      case DisasterType.cyclone:
        advisory = 'High wind gusts and heavy precipitation expected. Secure shelters and avoid open grounds.';
        break;
      case DisasterType.earthquake:
        advisory = 'Earthquake tremors reported. Stay away from windows and damaged structures. Drop, cover, and hold on.';
        break;
      case DisasterType.airPollution:
        advisory = 'Hazardous PM2.5 concentrations. High respiratory vulnerability advisory in effect.';
        break;
      case DisasterType.other:
        advisory = 'Localized environmental warning. Monitor personal safety advisories.';
        break;
    }

    return DisasterEvent(
      type: type,
      severity: severity,
      affectedArea: affectedArea ?? type.defaultAffectedArea,
      isInsideAffectedArea: isInside,
      source: 'State Disaster Management Authority (SDMA) / IMD Feed',
      timestamp: DateTime.now(),
      isActive: true,
      advisory: advisory,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'severity': severity.name,
        'affectedArea': affectedArea,
        'isInsideAffectedArea': isInsideAffectedArea,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
        'isActive': isActive,
        'advisory': advisory,
      };

  factory DisasterEvent.fromMap(Map<String, dynamic> map) => DisasterEvent(
        type: DisasterType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => DisasterType.other,
        ),
        severity: DisasterSeverity.values.firstWhere(
          (e) => e.name == map['severity'],
          orElse: () => DisasterSeverity.moderate,
        ),
        affectedArea: map['affectedArea'] as String? ?? 'Regional Zone',
        isInsideAffectedArea: map['isInsideAffectedArea'] as bool? ?? true,
        source: map['source'] as String? ?? 'Disaster Management Authority',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        isActive: map['isActive'] as bool? ?? true,
        advisory: map['advisory'] as String? ?? 'Follow official safety guidelines.',
      );
}

/// Continuous Health Telemetry Snapshot
class HealthSnapshot {
  final int heartRate; // BPM
  final int spo2; // %
  final double bodyTemperature; // Celsius
  final int activitySteps; // recent steps / active movement score
  final double sleepDurationHours; // recent sleep in hours
  final String sleepQuality; // 'Good', 'Fair', 'Poor'
  final DateTime timestamp;

  const HealthSnapshot({
    required this.heartRate,
    required this.spo2,
    required this.bodyTemperature,
    required this.activitySteps,
    required this.sleepDurationHours,
    required this.sleepQuality,
    required this.timestamp,
  });

  factory HealthSnapshot.defaultNormal() => HealthSnapshot(
        heartRate: 74,
        spo2: 98,
        bodyTemperature: 36.8,
        activitySteps: 2400,
        sleepDurationHours: 7.5,
        sleepQuality: 'Good',
        timestamp: DateTime.now(),
      );

  HealthSnapshot copyWith({
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    int? activitySteps,
    double? sleepDurationHours,
    String? sleepQuality,
    DateTime? timestamp,
  }) {
    return HealthSnapshot(
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      activitySteps: activitySteps ?? this.activitySteps,
      sleepDurationHours: sleepDurationHours ?? this.sleepDurationHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'heartRate': heartRate,
        'spo2': spo2,
        'bodyTemperature': bodyTemperature,
        'activitySteps': activitySteps,
        'sleepDurationHours': sleepDurationHours,
        'sleepQuality': sleepQuality,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HealthSnapshot.fromMap(Map<String, dynamic> map) => HealthSnapshot(
        heartRate: (map['heartRate'] as num?)?.toInt() ?? 74,
        spo2: (map['spo2'] as num?)?.toInt() ?? 98,
        bodyTemperature: (map['bodyTemperature'] as num?)?.toDouble() ?? 36.8,
        activitySteps: (map['activitySteps'] as num?)?.toInt() ?? 2400,
        sleepDurationHours: (map['sleepDurationHours'] as num?)?.toDouble() ?? 7.5,
        sleepQuality: map['sleepQuality'] as String? ?? 'Good',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Environmental Conditions Telemetry
class EnvironmentalSnapshot {
  final double ambientTemperature; // Celsius
  final double humidity; // %
  final int aqi; // Air Quality Index
  final String aqiCategory; // 'Good', 'Moderate', 'Unhealthy', 'Hazardous'
  final DateTime timestamp;

  const EnvironmentalSnapshot({
    required this.ambientTemperature,
    required this.humidity,
    required this.aqi,
    required this.aqiCategory,
    required this.timestamp,
  });

  factory EnvironmentalSnapshot.defaultNormal() => EnvironmentalSnapshot(
        ambientTemperature: 28.5,
        humidity: 55.0,
        aqi: 68,
        aqiCategory: 'Moderate',
        timestamp: DateTime.now(),
      );

  EnvironmentalSnapshot copyWith({
    double? ambientTemperature,
    double? humidity,
    int? aqi,
    String? aqiCategory,
    DateTime? timestamp,
  }) {
    return EnvironmentalSnapshot(
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      humidity: humidity ?? this.humidity,
      aqi: aqi ?? this.aqi,
      aqiCategory: aqiCategory ?? this.aqiCategory,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'ambientTemperature': ambientTemperature,
        'humidity': humidity,
        'aqi': aqi,
        'aqiCategory': aqiCategory,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EnvironmentalSnapshot.fromMap(Map<String, dynamic> map) => EnvironmentalSnapshot(
        ambientTemperature: (map['ambientTemperature'] as num?)?.toDouble() ?? 28.5,
        humidity: (map['humidity'] as num?)?.toDouble() ?? 55.0,
        aqi: (map['aqi'] as num?)?.toInt() ?? 68,
        aqiCategory: map['aqiCategory'] as String? ?? 'Moderate',
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Personal Baseline learned/maintained for patient
class PersonalBaseline {
  final int restingHeartRate; // e.g. 70 BPM
  final int normalSpo2; // e.g. 98%
  final double normalBodyTemp; // e.g. 36.6 °C
  final int dailyActivityTarget; // e.g. 5000 steps
  final double targetSleepHours; // e.g. 7.5 hrs

  const PersonalBaseline({
    required this.restingHeartRate,
    required this.normalSpo2,
    required this.normalBodyTemp,
    required this.dailyActivityTarget,
    required this.targetSleepHours,
  });

  factory PersonalBaseline.defaultBaseline() => const PersonalBaseline(
        restingHeartRate: 72,
        normalSpo2: 98,
        normalBodyTemp: 36.7,
        dailyActivityTarget: 5000,
        targetSleepHours: 7.5,
      );

  Map<String, dynamic> toMap() => {
        'restingHeartRate': restingHeartRate,
        'normalSpo2': normalSpo2,
        'normalBodyTemp': normalBodyTemp,
        'dailyActivityTarget': dailyActivityTarget,
        'targetSleepHours': targetSleepHours,
      };

  factory PersonalBaseline.fromMap(Map<String, dynamic> map) => PersonalBaseline(
        restingHeartRate: (map['restingHeartRate'] as num?)?.toInt() ?? 72,
        normalSpo2: (map['normalSpo2'] as num?)?.toInt() ?? 98,
        normalBodyTemp: (map['normalBodyTemp'] as num?)?.toDouble() ?? 36.7,
        dailyActivityTarget: (map['dailyActivityTarget'] as num?)?.toInt() ?? 5000,
        targetSleepHours: (map['targetSleepHours'] as num?)?.toDouble() ?? 7.5,
      );
}

/// EXACTLY THREE Disaster Mode Risk Levels (Prompt mandate: NO 4th risk level)
enum DisasterRiskLevel {
  low,
  moderate,
  high;

  String get displayName {
    switch (this) {
      case DisasterRiskLevel.low:
        return 'LOW';
      case DisasterRiskLevel.moderate:
        return 'MODERATE';
      case DisasterRiskLevel.high:
        return 'HIGH';
    }
  }

  Color get color {
    switch (this) {
      case DisasterRiskLevel.low:
        return AppColors.successGreen;
      case DisasterRiskLevel.moderate:
        return AppColors.warningOrange;
      case DisasterRiskLevel.high:
        return AppColors.emergencyRed;
    }
  }

  Color get bgColor {
    switch (this) {
      case DisasterRiskLevel.low:
        return AppColors.successGreenBg;
      case DisasterRiskLevel.moderate:
        return AppColors.warningOrangeBg;
      case DisasterRiskLevel.high:
        return AppColors.emergencyRedBg;
    }
  }

  IconData get icon {
    switch (this) {
      case DisasterRiskLevel.low:
        return Icons.shield_rounded;
      case DisasterRiskLevel.moderate:
        return Icons.warning_amber_rounded;
      case DisasterRiskLevel.high:
        return Icons.error_outline_rounded;
    }
  }
}

/// Explainable Risk Factor for "WHY AM I AT RISK?"
class RiskFactor {
  final String title;
  final String explanation;
  final bool isElevated;

  const RiskFactor({
    required this.title,
    required this.explanation,
    this.isElevated = true,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'explanation': explanation,
        'isElevated': isElevated,
      };

  factory RiskFactor.fromMap(Map<String, dynamic> map) => RiskFactor(
        title: map['title'] as String? ?? '',
        explanation: map['explanation'] as String? ?? '',
        isElevated: map['isElevated'] as bool? ?? true,
      );
}

/// Wellness Indicator (Heat, Dehydration, Respiratory, Fatigue, Vital signs)
class WellnessIndicator {
  final String category; // 'Heat Stress', 'Dehydration Risk Indicator', 'Respiratory Distress Indicator', 'Fatigue Risk', 'Vital Signs'
  final String status; // 'Normal', 'Mild', 'Elevated', 'High'
  final String details;
  final IconData icon;
  final Color color;

  const WellnessIndicator({
    required this.category,
    required this.status,
    required this.details,
    required this.icon,
    required this.color,
  });
}

/// Actionable personalized recommendation
class DisasterRecommendation {
  final String actionText;
  final String category; // 'Hydration', 'Environment', 'Mobility', 'Medical'
  final IconData icon;

  const DisasterRecommendation({
    required this.actionText,
    required this.category,
    required this.icon,
  });
}

/// Safe Location & Shelter Point for Map
class SafeLocation {
  final String id;
  final String name;
  final String type; // 'Emergency Shelter', 'Hospital', 'Safe Zone', 'Relief Camp'
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String capacity;
  final bool isOpen;
  final String routeNote;

  const SafeLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.capacity,
    required this.isOpen,
    required this.routeNote,
  });
}

/// Connectivity status for Disaster Mode
enum DisasterConnectivityState {
  online,
  offline,
  syncing;

  String get displayName {
    switch (this) {
      case DisasterConnectivityState.online:
        return 'ONLINE';
      case DisasterConnectivityState.offline:
        return 'OFFLINE';
      case DisasterConnectivityState.syncing:
        return 'SYNCING';
    }
  }

  Color get color {
    switch (this) {
      case DisasterConnectivityState.online:
        return AppColors.successGreen;
      case DisasterConnectivityState.offline:
        return AppColors.textSecondary;
      case DisasterConnectivityState.syncing:
        return AppColors.warningOrange;
    }
  }
}

/// Visual Health/Risk State for Active Monitored Users (Section 7 & 8)
enum UserHealthRiskState {
  stable,
  moderate,
  high,
  critical,
  offline;

  String get displayName {
    switch (this) {
      case UserHealthRiskState.stable:
        return 'Safe';
      case UserHealthRiskState.moderate:
        return 'Moderate';
      case UserHealthRiskState.high:
        return 'High Risk';
      case UserHealthRiskState.critical:
        return 'Critical';
      case UserHealthRiskState.offline:
        return 'Offline';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserHealthRiskState.stable:
        return 'SAFE';
      case UserHealthRiskState.moderate:
        return 'MODERATE';
      case UserHealthRiskState.high:
        return 'HIGH RISK';
      case UserHealthRiskState.critical:
        return 'CRITICAL';
      case UserHealthRiskState.offline:
        return 'OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case UserHealthRiskState.stable:
        return AppColors.successGreen; // Green
      case UserHealthRiskState.moderate:
        return const Color(0xFFFBC02D); // Yellow / Amber
      case UserHealthRiskState.high:
        return const Color(0xFFFF6D00); // Deep Orange
      case UserHealthRiskState.critical:
        return AppColors.emergencyRed; // Red
      case UserHealthRiskState.offline:
        return const Color(0xFF757575); // Gray
    }
  }

  Color get bgColor {
    switch (this) {
      case UserHealthRiskState.stable:
        return const Color(0xFFE8F5E9);
      case UserHealthRiskState.moderate:
        return const Color(0xFFFFFDE7);
      case UserHealthRiskState.high:
        return const Color(0xFFFFF3E0);
      case UserHealthRiskState.critical:
        return const Color(0xFFFFEBEE);
      case UserHealthRiskState.offline:
        return const Color(0xFFF5F5F5);
    }
  }

  IconData get icon {
    switch (this) {
      case UserHealthRiskState.stable:
        return Icons.check_circle_rounded;
      case UserHealthRiskState.moderate:
        return Icons.warning_amber_rounded;
      case UserHealthRiskState.high:
        return Icons.error_outline_rounded;
      case UserHealthRiskState.critical:
        return Icons.emergency_rounded;
      case UserHealthRiskState.offline:
        return Icons.cloud_off_rounded;
    }
  }
}

/// Active Monitored G1Care User for Disaster Map
class DisasterMonitoredUser {
  final String userId; // Anonymous demo ID, e.g. 'G1-U101 (User A)'
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isActive;
  final String healthState; // e.g., 'Normal / Stable', 'Elevated Heat Stress', 'Severe Cardiac Strain'
  final UserHealthRiskState riskState;
  final bool isWearableConnected;
  final int? heartRate;
  final int? spo2;
  final double? bodyTemperature;
  final String lastUpdatedText; // 'Just now', '2m ago', '15m ago', '45m ago'
  final DateTime lastUpdated;
  final String locationStatus; // 'Hazard Area', 'Safe Perimeter', 'Shelter Zone'

  const DisasterMonitoredUser({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.isActive,
    required this.healthState,
    required this.riskState,
    this.isWearableConnected = true,
    this.heartRate,
    this.spo2,
    this.bodyTemperature,
    required this.lastUpdatedText,
    required this.lastUpdated,
    required this.locationStatus,
  });

  DisasterMonitoredUser copyWith({
    String? userId,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isActive,
    String? healthState,
    UserHealthRiskState? riskState,
    bool? isWearableConnected,
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    String? lastUpdatedText,
    DateTime? lastUpdated,
    String? locationStatus,
  }) {
    return DisasterMonitoredUser(
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isActive: isActive ?? this.isActive,
      healthState: healthState ?? this.healthState,
      riskState: riskState ?? this.riskState,
      isWearableConnected: isWearableConnected ?? this.isWearableConnected,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      bodyTemperature: bodyTemperature ?? this.bodyTemperature,
      lastUpdatedText: lastUpdatedText ?? this.lastUpdatedText,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      locationStatus: locationStatus ?? this.locationStatus,
    );
  }
}

/// Disaster Safety Guidance for Public Disaster Hub
class DisasterSafetyRule {
  final String title;
  final String description;
  final IconData icon;

  const DisasterSafetyRule({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class DisasterSafetyGuidance {
  final DisasterType type;
  final String overview;
  final List<DisasterSafetyRule> keyRules;
  final List<String> emergencyContacts;

  const DisasterSafetyGuidance({
    required this.type,
    required this.overview,
    required this.keyRules,
    required this.emergencyContacts,
  });

  static DisasterSafetyGuidance forType(DisasterType type) {
    switch (type) {
      case DisasterType.heatwave:
        return const DisasterSafetyGuidance(
          type: DisasterType.heatwave,
          overview: 'Protect against extreme heat stress, heatstroke, and dehydration.',
          keyRules: [
            DisasterSafetyRule(
              title: 'Hydrate Regularly',
              description: 'Drink water, ORS, or lemon water frequently even if not feeling thirsty. Avoid alcohol and sugary drinks.',
              icon: Icons.water_drop_rounded,
            ),
            DisasterSafetyRule(
              title: 'Relocate to Cooler Spaces',
              description: 'Stay in shaded, well-ventilated, or cooled indoor environments during peak thermal hours (11 AM - 4 PM).',
              icon: Icons.ac_unit_rounded,
            ),
            DisasterSafetyRule(
              title: 'Avoid Strenuous Activity',
              description: 'Postpone intense outdoor labor or physical exercise to early morning or late evening.',
              icon: Icons.directions_run_rounded,
            ),
            DisasterSafetyRule(
              title: 'Monitor Vulnerable Individuals',
              description: 'Check elderly relatives, children, and people with cardiovascular or respiratory conditions.',
              icon: Icons.family_restroom_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'Ambulance: 108', 'Heatstroke Helpline: 1075'],
        );

      case DisasterType.flood:
        return const DisasterSafetyGuidance(
          type: DisasterType.flood,
          overview: 'Stay safe during severe water inundation, flash flooding, and river surges.',
          keyRules: [
            DisasterSafetyRule(
              title: 'Avoid Floodwaters',
              description: 'Do not walk, swim, or drive through moving water. Even 6 inches of rapid water can knock you down.',
              icon: Icons.waves_rounded,
            ),
            DisasterSafetyRule(
              title: 'Move to High Ground',
              description: 'Evacuate low-lying riverbanks, underpasses, and basement structures immediately when alert sounds.',
              icon: Icons.terrain_rounded,
            ),
            DisasterSafetyRule(
              title: 'Disconnect Electrical Mains',
              description: 'Turn off power and gas at main switches before water enters living spaces to avoid electrocution.',
              icon: Icons.bolt_rounded,
            ),
            DisasterSafetyRule(
              title: 'Follow Official Evacuation Corridors',
              description: 'Use designated relief shelter paths identified on the G1Care Disaster Map.',
              icon: Icons.navigation_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'NDRF Helpline: 1078', 'Flood Emergency: 1070'],
        );

      case DisasterType.cyclone:
        return const DisasterSafetyGuidance(
          type: DisasterType.cyclone,
          overview: 'Mitigate hazard from severe gale-force winds, flying debris, and torrential rain.',
          keyRules: [
            DisasterSafetyRule(
              title: 'Stay Indoors',
              description: 'Remain inside sturdy permanent structures. Keep away from glass doors, windows, and weak roofs.',
              icon: Icons.roofing_rounded,
            ),
            DisasterSafetyRule(
              title: 'Follow Official Warnings',
              description: 'Track IMD/NDRF broadcast updates and do not venture out until official clearance is given.',
              icon: Icons.radio_rounded,
            ),
            DisasterSafetyRule(
              title: 'Avoid Exposed Areas',
              description: 'Steer clear of power lines, metal poles, towering trees, and loose advertising hoardings.',
              icon: Icons.warning_amber_rounded,
            ),
            DisasterSafetyRule(
              title: 'Emergency Go-Bag Ready',
              description: 'Keep water, non-perishable food, flashlights, powerbanks, and essential medicines within reach.',
              icon: Icons.backpack_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'Disaster Cell: 1077', 'NDRF: 1078'],
        );

      case DisasterType.earthquake:
        return const DisasterSafetyGuidance(
          type: DisasterType.earthquake,
          overview: 'Essential protection during seismic tremors and structural aftershocks.',
          keyRules: [
            DisasterSafetyRule(
              title: 'Drop, Cover, and Hold On',
              description: 'Drop to knees, take cover under a sturdy desk or table, and protect head and neck with arms.',
              icon: Icons.vibration_rounded,
            ),
            DisasterSafetyRule(
              title: 'Stay Clear of Damaged Facades',
              description: 'Move away from glass, exterior walls, masonry, and hanging architectural fixtures.',
              icon: Icons.domain_disabled_rounded,
            ),
            DisasterSafetyRule(
              title: 'Do Not Use Elevators',
              description: 'Use fire exit staircases after shaking stops. Never take elevators during or after a tremor.',
              icon: Icons.stairs_rounded,
            ),
            DisasterSafetyRule(
              title: 'Assemble at Open Grounds',
              description: 'After tremors subside, calmly proceed to wide open grounds away from utility cables and high-rises.',
              icon: Icons.nature_people_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'NDRF Helpline: 1078', 'State Emergency: 1070'],
        );

      case DisasterType.airPollution:
        return const DisasterSafetyGuidance(
          type: DisasterType.airPollution,
          overview: 'Defend respiratory health against hazardous particulate matter (PM2.5 / PM10).',
          keyRules: [
            DisasterSafetyRule(
              title: 'Minimize Outdoor Exposure',
              description: 'Avoid jogging, sports, and unnecessary outdoor exposure, especially in early morning and late night.',
              icon: Icons.no_transfer_rounded,
            ),
            DisasterSafetyRule(
              title: 'Wear Certified N95/N99 Masks',
              description: 'Use proper fitting particulate filtering masks when venturing outside into hazardous AQI zones.',
              icon: Icons.masks_rounded,
            ),
            DisasterSafetyRule(
              title: 'Purify Indoor Air',
              description: 'Keep windows and doors closed. Operate HEPA air purifiers if available and avoid burning biomass.',
              icon: Icons.air_rounded,
            ),
            DisasterSafetyRule(
              title: 'Protect Respiratory Patients',
              description: 'Individuals with asthma, COPD, or cardiac history must keep rescue inhalers and medicines handy.',
              icon: Icons.medication_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'Medical Helpline: 104', 'Ambulance: 108'],
        );

      case DisasterType.other:
        return const DisasterSafetyGuidance(
          type: DisasterType.other,
          overview: 'Follow local civil defense advisories and practice proactive personal safety.',
          keyRules: [
            DisasterSafetyRule(
              title: 'Follow Official Advisories',
              description: 'Monitor authorized government feeds and local disaster coordination instructions.',
              icon: Icons.info_outline_rounded,
            ),
            DisasterSafetyRule(
              title: 'Maintain Standby Communication',
              description: 'Ensure family members have established check-in points and charged communication devices.',
              icon: Icons.cell_tower_rounded,
            ),
          ],
          emergencyContacts: ['National Emergency: 112', 'Ambulance: 108'],
        );
    }
  }
}
