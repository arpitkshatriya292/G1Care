import '../../models/disaster/disaster_models.dart';

class AiChatMessage {
  final String sender; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;
  final bool isDisclaimer;

  const AiChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isDisclaimer = false,
  });
}

abstract class IDisasterAiService {
  Future<String> askDisasterAssistant({
    required String query,
    required HealthSnapshot health,
    required EnvironmentalSnapshot environment,
    required DisasterEvent disaster,
    required DisasterRiskLevel riskLevel,
    required PersonalBaseline baseline,
  });
}

class LocalDisasterAiService implements IDisasterAiService {
  static const String disclaimer =
      '⚠️ G1Care AI provides supportive first-level safety guidance based on your live sensor readings and disaster context. It is NOT a substitute for professional medical care, emergency responders (NDRF/108), or official government disaster evacuation orders.';

  @override
  Future<String> askDisasterAssistant({
    required String query,
    required HealthSnapshot health,
    required EnvironmentalSnapshot environment,
    required DisasterEvent disaster,
    required DisasterRiskLevel riskLevel,
    required PersonalBaseline baseline,
  }) async {
    // Simulate brief processing latency
    await Future.delayed(const Duration(milliseconds: 400));

    final q = query.toLowerCase();

    // 1. Water / Hydration queries
    if (q.contains('water') || q.contains('drink') || q.contains('hydration') || q.contains('thirsty')) {
      if (disaster.type == DisasterType.flood) {
        return '💧 Water Safety Notice (Flood Context):\n'
            '• NEVER consume unboiled tap or standing flood water due to high water-borne contamination risk.\n'
            '• Drink only sealed bottled water, boiled water (minimum 1 min rolling boil), or municipal disaster relief supply.\n'
            '• Your current vitals show HR: ${health.heartRate} BPM, SpO2: ${health.spo2}%. Stay hydrated with safe sources only.';
      } else if (disaster.type == DisasterType.heatwave) {
        return '💧 Hydration Guidance (Heatwave Context):\n'
            '• Ambient temperature is ${environment.ambientTemperature.toStringAsFixed(1)}°C with ${environment.humidity.toStringAsFixed(0)}% humidity.\n'
            '• Sip 250-300 ml of cool water or oral rehydration salts (ORS) every 20-30 minutes.\n'
            '• Avoid caffeinated or sugary energy drinks as they accelerate fluid loss.';
      } else {
        return '💧 Hydration Advice:\n'
            '• Keep drinking clean potable water regularly. Your current body temperature is ${health.bodyTemperature.toStringAsFixed(1)}°C.';
      }
    }

    // 2. Outdoor / Safe to go outside queries
    if (q.contains('outside') || q.contains('go out') || q.contains('leave') || q.contains('walk') || q.contains('travel')) {
      if (disaster.type == DisasterType.airPollution) {
        return '🌫 Outdoor Exposure Risk:\n'
            '• Outside air quality is ${environment.aqi} AQI (${environment.aqiCategory}).\n'
            '• DO NOT engage in outdoor physical exercise or prolonged walking.\n'
            '• If you must step outside, wear an N95 or equivalent respirator. Your current SpO2 is ${health.spo2}%.';
      } else if (disaster.type == DisasterType.flood) {
        return '🌊 Flood Mobility Advisory:\n'
            '• Water depth and submerged hazards can be deceptive. Do not walk or drive through flowing water.\n'
            '• Check the "Safe Location" tab to find officially designated high-ground shelters and dry routes.';
      } else if (disaster.type == DisasterType.cyclone) {
        return '🌀 Cyclone Shelter Warning:\n'
            '• High wind gusts and flying debris pose severe risk. Stay indoors in a structurally reinforced room away from glass.';
      } else if (disaster.type == DisasterType.heatwave) {
        return '☀️ Heatwave Exposure Alert:\n'
            '• Ambient temperature is ${environment.ambientTemperature.toStringAsFixed(1)}°C.\n'
            '• Minimize direct solar exposure, especially during peak UV hours (11 AM to 4 PM).';
      }
    }

    // 3. Heart Rate / Vitals / Chest / Breathing queries
    if (q.contains('heart') || q.contains('pulse') || q.contains('breath') || q.contains('chest') || q.contains('spo2') || q.contains('dizzy')) {
      final hrDelta = health.heartRate - baseline.restingHeartRate;
      return '❤️ Vitals & Symptoms Assessment:\n'
          '• Current Heart Rate: ${health.heartRate} BPM (${hrDelta > 0 ? "+$hrDelta above" : "aligned with"} your baseline of ${baseline.restingHeartRate} BPM).\n'
          '• SpO2: ${health.spo2}% (Normal baseline: ${baseline.normalSpo2}%).\n'
          '• Body Temp: ${health.bodyTemperature.toStringAsFixed(1)}°C.\n'
          '• Rest in a shaded, well-ventilated location immediately. Loosen tight clothing.\n'
          '• If you experience severe chest pain, shortness of breath, or confusion, tap the red EMERGENCY SOS button immediately.';
    }

    // 4. Shelter / Safe Location queries
    if (q.contains('shelter') || q.contains('safe') || q.contains('where') || q.contains('hospital') || q.contains('camp')) {
      return '🗺 Shelter & Relief Navigation:\n'
          '• G1Care has mapped verified emergency shelters, relief camps, and emergency hospitals.\n'
          '• Please tap the "Safe Location" card on your Disaster Mode dashboard to inspect verified coordinates, distances, and road advisories.\n'
          '• Avoid unverified low-lying pathways.';
    }

    // Default context-aware supportive response
    return '🤖 G1Care Disaster Safety Assistant:\n'
        '• Active Disaster: ${disaster.type.displayName} (${disaster.severity.displayName} Severity)\n'
        '• Local Risk Level: ${riskLevel.displayName}\n'
        '• Current Vitals: HR ${health.heartRate} BPM, SpO2 ${health.spo2}%, Temp ${health.bodyTemperature.toStringAsFixed(1)}°C\n'
        '• Ambient Environment: ${environment.ambientTemperature.toStringAsFixed(1)}°C, ${environment.humidity.toStringAsFixed(0)}% Humidity, ${environment.aqi} AQI\n'
        '• Recommendation: Stay in a safe environment, follow designated disaster guidance, and use the Emergency SOS button if you require urgent rescue.';
  }
}
