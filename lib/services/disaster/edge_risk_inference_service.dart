import 'package:flutter/material.dart';
import '../../models/disaster/disaster_models.dart';

/// Result produced by Edge Risk Analysis
class EdgeRiskAssessment {
  final DisasterRiskLevel riskLevel; // LOW, MODERATE, HIGH (EXACTLY 3)
  final List<RiskFactor> riskFactors; // Explainable bullet points
  final List<WellnessIndicator> wellnessIndicators; // Heat stress, dehydration risk indicator, etc.
  final List<DisasterRecommendation> recommendations; // Actionable guidance
  final DateTime evaluatedAt;

  const EdgeRiskAssessment({
    required this.riskLevel,
    required this.riskFactors,
    required this.wellnessIndicators,
    required this.recommendations,
    required this.evaluatedAt,
  });
}

/// Abstract interface for Edge Risk Inference
/// (Supports rule engine now, on-device Edge AI ML model later)
abstract class IEdgeRiskInferenceService {
  EdgeRiskAssessment evaluateRisk({
    required HealthSnapshot health,
    required EnvironmentalSnapshot environment,
    required PersonalBaseline baseline,
    required DisasterEvent disaster,
    required bool isInsideAffectedArea,
  });
}

/// Rule-based Edge Risk Engine running 100% LOCALLY on the patient device
/// Respects user privacy: raw sensitive metrics are processed locally without cloud upload.
class EdgeRiskRuleEngine implements IEdgeRiskInferenceService {
  @override
  EdgeRiskAssessment evaluateRisk({
    required HealthSnapshot health,
    required EnvironmentalSnapshot environment,
    required PersonalBaseline baseline,
    required DisasterEvent disaster,
    required bool isInsideAffectedArea,
  }) {
    final factors = <RiskFactor>[];
    int riskScore = 0; // 0-3: LOW, 4-7: MODERATE, >=8: HIGH

    // 1. DISASTER CONTEXT EVALUATION
    if (isInsideAffectedArea) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'Patient Inside Impact Zone',
        explanation: 'Your current GPS location is inside the ${disaster.affectedArea} hazard area.',
      ));
    }

    if (disaster.severity == DisasterSeverity.severe || disaster.severity == DisasterSeverity.high) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'High Disaster Severity',
        explanation: 'Official authority reported ${disaster.severity.displayName} severity for this ${disaster.type.displayName}.',
      ));
    }

    // 2. PHYSIOLOGICAL VITALS VS PERSONAL BASELINE EVALUATION
    final hrDelta = health.heartRate - baseline.restingHeartRate;
    if (health.heartRate > 120 || hrDelta > 35) {
      riskScore += 3;
      factors.add(RiskFactor(
        title: 'Heart Rate Markedly Above Baseline',
        explanation: 'Heart rate (${health.heartRate} BPM) is +$hrDelta BPM above your personal resting baseline (${baseline.restingHeartRate} BPM).',
      ));
    } else if (health.heartRate > 100 || hrDelta > 18) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'Elevated Heart Rate',
        explanation: 'Heart rate (${health.heartRate} BPM) is elevated compared to baseline resting pace.',
      ));
    }

    if (health.spo2 < 92) {
      riskScore += 3;
      factors.add(RiskFactor(
        title: 'Significant SpO2 Decline',
        explanation: 'Oxygen saturation (${health.spo2}%) is below safe thresholds (< 92%).',
      ));
    } else if (health.spo2 < 95) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'Mild SpO2 Desaturation',
        explanation: 'Oxygen saturation (${health.spo2}%) is lower than normal baseline (${baseline.normalSpo2}%).',
      ));
    }

    if (health.bodyTemperature >= 38.5) {
      riskScore += 3;
      factors.add(RiskFactor(
        title: 'High Body Temperature / Hyperthermia',
        explanation: 'Body temperature (${health.bodyTemperature.toStringAsFixed(1)}°C) indicates hyperthermic stress.',
      ));
    } else if (health.bodyTemperature >= 37.8) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'Elevated Body Temperature',
        explanation: 'Body temperature (${health.bodyTemperature.toStringAsFixed(1)}°C) is above your normal baseline (${baseline.normalBodyTemp.toStringAsFixed(1)}°C).',
      ));
    }

    // 3. ENVIRONMENTAL STRESS EVALUATION
    if (environment.ambientTemperature >= 40.0) {
      riskScore += 3;
      factors.add(RiskFactor(
        title: 'Extreme Ambient Temperature',
        explanation: 'Ambient heat of ${environment.ambientTemperature.toStringAsFixed(1)}°C presents dangerous thermal load.',
      ));
    } else if (environment.ambientTemperature >= 36.0) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'High Ambient Temperature',
        explanation: 'Environmental heat (${environment.ambientTemperature.toStringAsFixed(1)}°C) exceeds comfort and safety thresholds.',
      ));
    }

    if (environment.humidity >= 75.0 && environment.ambientTemperature >= 32.0) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'High Humidity & Heat Index',
        explanation: 'Relative humidity (${environment.humidity.toStringAsFixed(0)}%) impedes natural sweat evaporation cooling.',
      ));
    }

    if (environment.aqi >= 250) {
      riskScore += 3;
      factors.add(RiskFactor(
        title: 'Hazardous Air Quality',
        explanation: 'AQI index of ${environment.aqi} (${environment.aqiCategory}) causes severe respiratory strain.',
      ));
    } else if (environment.aqi >= 150) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'Poor Air Quality',
        explanation: 'AQI index of ${environment.aqi} poses elevated risk for respiratory irritation.',
      ));
    }

    // 4. ACTIVITY & SLEEP FATIGUE EVALUATION
    if (health.activitySteps > 8000 && environment.ambientTemperature >= 35.0) {
      riskScore += 2;
      factors.add(RiskFactor(
        title: 'High Exertion in Heat',
        explanation: 'High step count (${health.activitySteps} steps) during extreme thermal conditions.',
      ));
    }

    if (health.sleepDurationHours < 5.0) {
      riskScore += 1;
      factors.add(RiskFactor(
        title: 'Sleep Deficit / Fatigue',
        explanation: 'Recent sleep duration (${health.sleepDurationHours.toStringAsFixed(1)} hrs) is below target (${baseline.targetSleepHours.toStringAsFixed(1)} hrs), compounding physiological vulnerability.',
      ));
    }

    // If factors is empty (all metrics normal), add positive factor
    if (factors.isEmpty) {
      factors.add(const RiskFactor(
        title: 'Stable Health & Environment',
        explanation: 'Vitals, environmental metrics, and activity levels are aligned with baseline safety thresholds.',
        isElevated: false,
      ));
    }

    // 5. DETERMINE EXACTLY THREE RISK LEVELS
    DisasterRiskLevel level;
    if (riskScore >= 7) {
      level = DisasterRiskLevel.high;
    } else if (riskScore >= 3) {
      level = DisasterRiskLevel.moderate;
    } else {
      level = DisasterRiskLevel.low;
    }

    // 6. COMPUTE WELLNESS INDICATORS (Non-diagnostic Risk Indicators)
    final wellness = _computeWellnessIndicators(health, environment, baseline, disaster);

    // 7. COMPUTE DISASTER-SPECIFIC RECOMMENDATIONS
    final recommendations = _computeRecommendations(
      level: level,
      disaster: disaster,
      health: health,
      environment: environment,
      isInside: isInsideAffectedArea,
    );

    return EdgeRiskAssessment(
      riskLevel: level,
      riskFactors: factors,
      wellnessIndicators: wellness,
      recommendations: recommendations,
      evaluatedAt: DateTime.now(),
    );
  }

  List<WellnessIndicator> _computeWellnessIndicators(
    HealthSnapshot health,
    EnvironmentalSnapshot environment,
    PersonalBaseline baseline,
    DisasterEvent disaster,
  ) {
    final list = <WellnessIndicator>[];

    // Heat stress indicator
    final isHeatStressed = environment.ambientTemperature > 36 || health.bodyTemperature > 37.5;
    list.add(WellnessIndicator(
      category: 'Heat Stress Indicator',
      status: isHeatStressed ? (health.bodyTemperature > 38.0 ? 'High' : 'Elevated') : 'Normal',
      details: isHeatStressed
          ? 'Thermal load is elevated. Body temp is ${health.bodyTemperature.toStringAsFixed(1)}°C in ${environment.ambientTemperature.toStringAsFixed(1)}°C ambient heat.'
          : 'Thermal regulation is within normal physiological limits.',
      icon: Icons.thermostat_rounded,
      color: isHeatStressed ? Colors.orange : Colors.green,
    ));

    // Dehydration risk indicator (estimated transparently from heat + humidity + HR + steps)
    final isDehydrationRisk = (environment.ambientTemperature > 34 && health.activitySteps > 4000) ||
        (health.heartRate > baseline.restingHeartRate + 15 && environment.ambientTemperature > 32);
    list.add(WellnessIndicator(
      category: 'Dehydration Risk Indicator',
      status: isDehydrationRisk ? 'Elevated Risk' : 'Low Risk',
      details: isDehydrationRisk
          ? 'Physiological and environmental telemetry suggest high fluid loss potential. Maintain active hydration.'
          : 'Estimated hydration balance appears stable based on activity and ambient conditions.',
      icon: Icons.water_drop_outlined,
      color: isDehydrationRisk ? Colors.amber.shade800 : Colors.blue,
    ));

    // Respiratory distress/risk indicator
    final isRespiratoryRisk = environment.aqi > 150 || health.spo2 < 95;
    list.add(WellnessIndicator(
      category: 'Respiratory Distress Indicator',
      status: isRespiratoryRisk ? (health.spo2 < 92 ? 'High' : 'Moderate') : 'Normal',
      details: isRespiratoryRisk
          ? 'Air quality (${environment.aqi} AQI) or SpO2 (${health.spo2}%) indicates respiratory strain. Limit heavy exertion.'
          : 'Oxygen saturation (${health.spo2}%) and ambient air quality are acceptable.',
      icon: Icons.air_rounded,
      color: isRespiratoryRisk ? Colors.deepOrange : Colors.teal,
    ));

    // Fatigue risk indicator
    final isFatigue = health.sleepDurationHours < 5.5 || health.sleepQuality == 'Poor';
    list.add(WellnessIndicator(
      category: 'Fatigue Risk Indicator',
      status: isFatigue ? 'Elevated' : 'Normal',
      details: isFatigue
          ? 'Recent sleep of ${health.sleepDurationHours.toStringAsFixed(1)} hrs may impair alertness during emergencies.'
          : 'Adequate rest recorded (${health.sleepDurationHours.toStringAsFixed(1)} hrs).',
      icon: Icons.bedtime_outlined,
      color: isFatigue ? Colors.purple : Colors.indigo,
    ));

    // Abnormal vital signs indicator
    final isAbnormalVitals = health.heartRate > 105 || health.spo2 < 94 || health.bodyTemperature > 38.0;
    list.add(WellnessIndicator(
      category: 'Vital Signs Status',
      status: isAbnormalVitals ? 'Attention Needed' : 'Stable',
      details: isAbnormalVitals
          ? 'One or more biometric readings deviate from your standard personal baseline.'
          : 'All core vitals remain congruent with personal baseline.',
      icon: Icons.favorite_rounded,
      color: isAbnormalVitals ? Colors.red : Colors.green,
    ));

    return list;
  }

  List<DisasterRecommendation> _computeRecommendations({
    required DisasterRiskLevel level,
    required DisasterEvent disaster,
    required HealthSnapshot health,
    required EnvironmentalSnapshot environment,
    required bool isInside,
  }) {
    final list = <DisasterRecommendation>[];

    switch (disaster.type) {
      case DisasterType.heatwave:
        list.add(const DisasterRecommendation(
          actionText: 'Move to a cooler environment and significantly reduce physical exertion.',
          category: 'Environment',
          icon: Icons.ac_unit_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Drink safe clean water or oral rehydration fluids at regular intervals.',
          category: 'Hydration',
          icon: Icons.water_drop_rounded,
        ));
        if (health.bodyTemperature > 37.8) {
          list.add(const DisasterRecommendation(
            actionText: 'Apply cool damp cloths to neck and forehead to aid thermal dissipation.',
            category: 'Cooling',
            icon: Icons.thermostat_rounded,
          ));
        }
        break;

      case DisasterType.flood:
        list.add(const DisasterRecommendation(
          actionText: 'Avoid walking or driving through flood waters; move toward elevated safe ground.',
          category: 'Mobility',
          icon: Icons.directions_walk_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Consult the Safe Location section to locate verified flood relief shelters nearby.',
          category: 'Navigation',
          icon: Icons.map_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Keep electrical switches off in flooded areas and maintain device battery.',
          category: 'Safety',
          icon: Icons.flash_off_rounded,
        ));
        break;

      case DisasterType.cyclone:
        list.add(const DisasterRecommendation(
          actionText: 'Remain inside reinforced shelter away from glass windows and loose tin roofs.',
          category: 'Shelter',
          icon: Icons.roofing_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Follow official radio/civil defense broadcasts; avoid unnecessary travel.',
          category: 'Information',
          icon: Icons.campaign_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Keep emergency supplies, medications, and medical QR ID accessible.',
          category: 'Preparedness',
          icon: Icons.medical_services_rounded,
        ));
        break;

      case DisasterType.airPollution:
        list.add(const DisasterRecommendation(
          actionText: 'Reduce outdoor physical exposure; stay indoors with windows shut and filtered air.',
          category: 'Environment',
          icon: Icons.home_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Wear a well-fitted particulate respirator (N95/FFP2) if outdoor transit is required.',
          category: 'Protection',
          icon: Icons.masks_rounded,
        ));
        if (health.spo2 < 95) {
          list.add(const DisasterRecommendation(
            actionText: 'Rest in an upright seated position and monitor breathing effort closely.',
            category: 'Medical',
            icon: Icons.airline_seat_recline_normal_rounded,
          ));
        }
        break;

      case DisasterType.earthquake:
        list.add(const DisasterRecommendation(
          actionText: 'Drop, Cover, and Hold On. Protect your head and neck beneath sturdy furniture.',
          category: 'Immediate Action',
          icon: Icons.vibration_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'Stay clear of exterior walls, glass facades, and loose architectural fixtures.',
          category: 'Shelter',
          icon: Icons.domain_disabled_rounded,
        ));
        list.add(const DisasterRecommendation(
          actionText: 'After shaking ceases, evacuate calmly via stairwells to open designated safe zones.',
          category: 'Evacuation',
          icon: Icons.nature_people_rounded,
        ));
        break;

      case DisasterType.other:
        list.add(const DisasterRecommendation(
          actionText: 'Maintain proximity to verified safe shelters and monitor official advisories.',
          category: 'Safety',
          icon: Icons.shield_rounded,
        ));
        break;
    }

    if (level == DisasterRiskLevel.high) {
      list.insert(
        0,
        const DisasterRecommendation(
          actionText: 'High composite risk detected: Rest immediately, seek assistance, or use Emergency SOS if in distress.',
          category: 'Urgent',
          icon: Icons.priority_high_rounded,
        ),
      );
    }

    return list;
  }
}
