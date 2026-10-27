import 'dart:async';
import 'dart:math' as math;
import '../../models/disaster/disaster_models.dart';

/// Clean interface for Health Data stream (supports simulated mock now, real BLE wristband later)
abstract class IHealthDataProvider {
  HealthSnapshot get currentHealth;
  Stream<HealthSnapshot> get healthStream;
  void updateVitals({
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    int? activitySteps,
    double? sleepDurationHours,
    String? sleepQuality,
  });
}

/// Clean interface for Environmental Data stream (supports simulated mock now, hardware environmental sensors later)
abstract class IEnvironmentalDataProvider {
  EnvironmentalSnapshot get currentEnvironment;
  Stream<EnvironmentalSnapshot> get environmentStream;
  void updateConditions({
    double? ambientTemperature,
    double? humidity,
    int? aqi,
    String? aqiCategory,
  });
}

/// Clean interface for Disaster context data (supports simulated scenarios now, NDRF/SDMA/IMD API feeds later)
abstract class IDisasterDataProvider {
  DisasterEvent get currentEvent;
  Stream<DisasterEvent> get eventStream;
  void setScenario(DisasterType type, {DisasterSeverity? severity, bool? isInside});
}

/// Mock/Simulated implementation of HealthDataProvider with clean interface separation
class MockHealthDataProvider implements IHealthDataProvider {
  HealthSnapshot _current = HealthSnapshot.defaultNormal();
  final StreamController<HealthSnapshot> _controller = StreamController<HealthSnapshot>.broadcast();

  @override
  HealthSnapshot get currentHealth => _current;

  @override
  Stream<HealthSnapshot> get healthStream => _controller.stream;

  @override
  void updateVitals({
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    int? activitySteps,
    double? sleepDurationHours,
    String? sleepQuality,
  }) {
    _current = _current.copyWith(
      heartRate: heartRate,
      spo2: spo2,
      bodyTemperature: bodyTemperature,
      activitySteps: activitySteps,
      sleepDurationHours: sleepDurationHours,
      sleepQuality: sleepQuality,
      timestamp: DateTime.now(),
    );
    _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock/Simulated implementation of EnvironmentalDataProvider
class MockEnvironmentalDataProvider implements IEnvironmentalDataProvider {
  EnvironmentalSnapshot _current = EnvironmentalSnapshot.defaultNormal();
  final StreamController<EnvironmentalSnapshot> _controller = StreamController<EnvironmentalSnapshot>.broadcast();

  @override
  EnvironmentalSnapshot get currentEnvironment => _current;

  @override
  Stream<EnvironmentalSnapshot> get environmentStream => _controller.stream;

  @override
  void updateConditions({
    double? ambientTemperature,
    double? humidity,
    int? aqi,
    String? aqiCategory,
  }) {
    _current = _current.copyWith(
      ambientTemperature: ambientTemperature,
      humidity: humidity,
      aqi: aqi,
      aqiCategory: aqiCategory,
      timestamp: DateTime.now(),
    );
    _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}

/// Mock/Simulated implementation of DisasterDataProvider
class MockDisasterDataProvider implements IDisasterDataProvider {
  DisasterEvent _current = DisasterEvent.mock(type: DisasterType.flood);
  final StreamController<DisasterEvent> _controller = StreamController<DisasterEvent>.broadcast();

  @override
  DisasterEvent get currentEvent => _current;

  @override
  Stream<DisasterEvent> get eventStream => _controller.stream;

  @override
  void setScenario(DisasterType type, {DisasterSeverity? severity, bool? isInside}) {
    _current = DisasterEvent.mock(
      type: type,
      severity: severity ?? DisasterSeverity.high,
      isInside: isInside ?? true,
    );
    _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}

/// Clean interface for Active User Monitoring stream
/// (Supports simulated mock dataset now; easily swappable with Firebase/Firestore + GPS + BLE wristband backend later)
abstract class IActiveUserMonitoringService {
  List<DisasterMonitoredUser> get activeUsers;
  Stream<List<DisasterMonitoredUser>> get usersStream;
  void refreshUsers({DisasterType? disasterType});
  void dispose();
}

/// Mock/Simulated implementation of ActiveUserMonitoringService (Section 6, 7, 8, 9)
class MockActiveUserMonitoringService implements IActiveUserMonitoringService {
  final StreamController<List<DisasterMonitoredUser>> _controller =
      StreamController<List<DisasterMonitoredUser>>.broadcast();
  late final Map<DisasterType, List<DisasterMonitoredUser>> _scenarios;
  DisasterType _currentType = DisasterType.flood;

  MockActiveUserMonitoringService({DisasterType initialType = DisasterType.flood}) {
    _currentType = initialType;
    _scenarios = _buildAllScenarios();
  }

  @override
  List<DisasterMonitoredUser> get activeUsers =>
      List.unmodifiable(_scenarios[_currentType] ?? _scenarios[DisasterType.flood]!);

  @override
  Stream<List<DisasterMonitoredUser>> get usersStream => _controller.stream;

  @override
  void refreshUsers({DisasterType? disasterType}) {
    if (disasterType != null) {
      _currentType = disasterType;
    }
    _controller.add(activeUsers);
  }

  Map<DisasterType, List<DisasterMonitoredUser>> _buildAllScenarios() {
    return {
      // 1. Heatwave: 128 active users (Mostly Safe/Moderate, some High Risk, few Critical)
      DisasterType.heatwave: _generateScenario(
        type: DisasterType.heatwave,
        safeCount: 72,
        moderateCount: 38,
        highCount: 14,
        criticalCount: 4,
        centerLat: 18.5308,
        centerLng: 73.8475,
        radiusDegrees: 0.016, // ~1.8km
        seed: 101,
        landmarks: const [
          'Shivajinagar Junction, Pune',
          'JM Road Commercial Hub, Pune',
          'FC Road Sector 3, Pune',
          'Deccan Gymkhana Terminal, Pune',
          'Model Colony North, Pune',
          'Agriculture College Grounds, Pune',
          'Ghole Road Municipal Hub, Pune',
          'Narveer Tanaji Wadi, Pune',
        ],
        safeStatus: const [
          'Normal vitals / Hydrated in shaded area',
          'Stable telemetry / Indoor cooling center',
          'Vital signs stable / Routine hydration log',
          'Resting in air-conditioned zone / Safe',
        ],
        moderateStatus: const [
          'Mild thermal fatigue / Hydration advisory',
          'Elevated pulse / Sun exposure detected',
          'Mild heat cramps / Rest recommended',
          'Thermal discomfort / Relocating to shelter',
        ],
        highStatus: const [
          'Severe heat exhaustion / Core temp 38.6°C',
          'Dehydration tachycardia / Alert triggered',
          'Prolonged sun exposure / Severe fatigue',
          'Cardiac strain / Immediate cooling needed',
        ],
        criticalStatus: const [
          'Critical hyperthermia alert (Temp 39.5°C)',
          'Severe heat stroke / Emergency cooling dispatch',
          'Severe dehydration & altered sensorium',
          'Critical thermal collapse / Triage alert',
        ],
      ),

      // 2. Flood: 86 active users (More Moderate/High Risk, increased Critical users)
      // Matches the exact prototype requirement example (42 + 25 + 14 + 5 = 86)
      DisasterType.flood: _generateScenario(
        type: DisasterType.flood,
        safeCount: 42,
        moderateCount: 25,
        highCount: 14,
        criticalCount: 5,
        centerLat: 18.5204,
        centerLng: 73.8567,
        radiusDegrees: 0.014, // ~1.5km
        seed: 202,
        landmarks: const [
          'Mula-Mutha Riverbank Ghats, Pune',
          'Sangam Bridge Low Crossing, Pune',
          'Bund Garden Riverside Walk, Pune',
          'Dengle Bridge Underpass, Pune',
          'Yerwada River Approach, Pune',
          'Kasba Peth Riverside Enclosure, Pune',
          'Shaniwar Wada North Basin, Pune',
          'Raja Dinkar Kelkar Ghat Area, Pune',
        ],
        safeStatus: const [
          'Safe on 2nd floor / Stable vitals',
          'Secure at high-ground relief shelter',
          'Normal vitals / Dry elevation verified',
          'Evacuated to designated municipal school',
        ],
        moderateStatus: const [
          'Immersion fatigue / Mild shivering',
          'Moving toward high-ground relief camp',
          'Mild water exposure / Heart rate 98',
          'Stuck at ground floor step / Safe for now',
        ],
        highStatus: const [
          'Water entering home / Elevated cardiac stress',
          'Rapidly rising water level / Tachycardia 122 BPM',
          'Trapped near flooded road / Awaiting boat rescue',
          'Desaturating SpO2 91% / Cold wet exposure',
        ],
        criticalStatus: const [
          'Critical trapped underpass alert (Water rising)',
          'Severe hypothermia & exhaustion / Emergency beacon',
          'Immediate boat evacuation requested / Pulse 142',
          'Inundated corridor entrapment alert',
        ],
      ),

      // 3. Cyclone: 146 active users (Moderate/High Risk dominant, some Critical users)
      DisasterType.cyclone: _generateScenario(
        type: DisasterType.cyclone,
        safeCount: 54,
        moderateCount: 52,
        highCount: 30,
        criticalCount: 10,
        centerLat: 18.5380,
        centerLng: 73.8320,
        radiusDegrees: 0.020, // ~2.2km
        seed: 303,
        landmarks: const [
          'Vetal Hill Exposed Ridge, Pune',
          'Pashan Elevated Perimeter, Pune',
          'Aundh Outer Ring, Pune',
          'Senapati Bapat High Ground, Pune',
          'Chatushrungi Foothills, Pune',
          'Range Hills Wind Corridor, Pune',
          'Gokhale Nagar Ridge, Pune',
          'Bavdhan Approach Ridge, Pune',
        ],
        safeStatus: const [
          'Sheltered indoors / Reinforced masonry room',
          'Normal vitals / Storm shutters secured',
          'Safe in community cyclone shelter hall',
          'Stable telemetry / Power backup operating',
        ],
        moderateStatus: const [
          'High anxiety / Gust noise stress',
          'Minor glass laceration / Bandaged in shelter',
          'Elevated pulse / In temporary shelter',
          'Power grid failure / Monitoring vitals',
        ],
        highStatus: const [
          'Roofing damage / Elevated cardiac strain',
          'Flying debris hazard / Tachycardia 126 BPM',
          'Structural wall vibration / Urgent alert',
          'Partial roof loss / Relocating under storm',
        ],
        criticalStatus: const [
          'Critical structural collapse alert',
          'Severe blunt force trauma / Urgent ER dispatch',
          'Emergency triage / Trapped under fallen roof',
          'Critical polytrauma alert / High priority',
        ],
      ),

      // 4. Earthquake: 64 active users (Higher High Risk/Critical proportion, fewer Safe users)
      DisasterType.earthquake: _generateScenario(
        type: DisasterType.earthquake,
        safeCount: 18,
        moderateCount: 22,
        highCount: 16,
        criticalCount: 8,
        centerLat: 18.5170,
        centerLng: 73.8560,
        radiusDegrees: 0.011, // ~1.2km
        seed: 404,
        landmarks: const [
          'Kasba Peth Dense Heritage Sector, Pune',
          'Budhwar Peth Old Construction, Pune',
          'Raviwar Peth Narrow Alley, Pune',
          'Mandai Open Grounds, Pune',
          'Shaniwar Peth Core, Pune',
          'Nana Peth Assembly Zone, Pune',
          'Somwar Peth Old Chawl, Pune',
          'Bhavani Peth Community Ground, Pune',
        ],
        safeStatus: const [
          'Evacuated to open park / Normal vitals',
          'Designated assembly ground / Uninjured',
          'Safe in open parking plaza / Calm vitals',
          'Clear of tall buildings / Stable status',
        ],
        moderateStatus: const [
          'Mild sprain / Rapid pulse from running',
          'Superficial debris scratches / Alert',
          'Post-tremor shock / Elevated heart rate',
          'Dust inhalation / Mild throat irritation',
        ],
        highStatus: const [
          'Stairwell blocked / Cardiac stress 128 BPM',
          'Partial masonry collapse / Awaiting search team',
          'Trapped on 2nd floor balcony / Pulse 124',
          'Fallen wall obstruction / Elevated vitals',
        ],
        criticalStatus: const [
          'Critical structural entrapment alert',
          'Crush injury syndrome / Tachycardia 144 BPM',
          'Trapped under rubble / SOS beacon broadcasting',
          'Severe compression injury / Urgent triage team',
        ],
      ),

      // 5. Air Pollution: 218 active users (Mostly Safe/Moderate, some High Risk, limited Critical users)
      DisasterType.airPollution: _generateScenario(
        type: DisasterType.airPollution,
        safeCount: 130,
        moderateCount: 62,
        highCount: 22,
        criticalCount: 4,
        centerLat: 18.5080,
        centerLng: 73.8680,
        radiusDegrees: 0.023, // ~2.5km
        seed: 505,
        landmarks: const [
          'Swargate Heavy Transit Junction, Pune',
          'Shankarsheth Industrial Corridor, Pune',
          'Timber Market Smog Sector, Pune',
          'Hadapsar Approach Industrial Road, Pune',
          'Gultekdi Market Yard, Pune',
          'Camp Cantonment Perimeter, Pune',
          'Bhavani Peth Commercial Ring, Pune',
          'Katraj Tunnel Approach Road, Pune',
        ],
        safeStatus: const [
          'Indoors with HEPA purifier / Normal vitals',
          'Wearing N95 respirator / SpO2 98%',
          'Resting indoors / Normal respiratory telemetry',
          'Sealed environment / Stable telemetry',
        ],
        moderateStatus: const [
          'Mild cough & eye irritation (AQI 290)',
          'Throat burning / Mild pulse elevation',
          'Mild bronchospasm / Inhaler logged',
          'Industrial smog exposure / Heart rate 98',
        ],
        highStatus: const [
          'Acute wheezing & chest tightness',
          'Desaturating SpO2 91% / Asthmatic history',
          'Severe smog reaction / Tachycardia 118 BPM',
          'Persistent coughing fit / Low oxygenation',
        ],
        criticalStatus: const [
          'Critical hypoxia alert (SpO2 86% / Severe asthma)',
          'Acute respiratory failure alert',
          'Severe cyanosis / Urgent oxygen cylinder needed',
          'Critical respiratory distress ambulance dispatched',
        ],
      ),

      // 6. Fallback / Other
      DisasterType.other: _generateScenario(
        type: DisasterType.other,
        safeCount: 48,
        moderateCount: 20,
        highCount: 9,
        criticalCount: 3,
        centerLat: 18.5240,
        centerLng: 73.8540,
        radiusDegrees: 0.015,
        seed: 606,
        landmarks: const [
          'Shivajinagar District, Pune',
          'Deccan Gymkhana Sector, Pune',
          'Camp Cantonment, Pune',
          'Swargate Perimeter, Pune',
        ],
        safeStatus: const ['Stable telemetry / Normal', 'Secure indoors / Stable vitals'],
        moderateStatus: const ['Mild environmental stress', 'Elevated pulse rate'],
        highStatus: const ['High risk factor alert', 'Cardiac strain alert'],
        criticalStatus: const ['Critical vital anomaly alert', 'Emergency SOS dispatch'],
      ),
    };
  }

  List<DisasterMonitoredUser> _generateScenario({
    required DisasterType type,
    required int safeCount,
    required int moderateCount,
    required int highCount,
    required int criticalCount,
    required double centerLat,
    required double centerLng,
    required double radiusDegrees,
    required int seed,
    required List<String> landmarks,
    required List<String> safeStatus,
    required List<String> moderateStatus,
    required List<String> highStatus,
    required List<String> criticalStatus,
  }) {
    final rand = math.Random(seed);
    final now = DateTime.now();
    final List<DisasterMonitoredUser> users = [];
    int userIndex = 1;

    void addGroup({
      required int count,
      required UserHealthRiskState riskState,
      required List<String> statusPool,
      required int minHr,
      required int maxHr,
      required int minSpo2,
      required int maxSpo2,
      required double minTemp,
      required double maxTemp,
      required String locStatus,
      required double minRadiusFraction,
      required double maxRadiusFraction,
    }) {
      for (int i = 0; i < count; i++) {
        // Uniform circular distribution with radial weighting
        final theta = rand.nextDouble() * 2 * math.pi;
        final rFraction =
            minRadiusFraction + math.sqrt(rand.nextDouble()) * (maxRadiusFraction - minRadiusFraction);
        final r = rFraction * radiusDegrees;
        final lat = centerLat + r * math.sin(theta);
        // Adjust longitude for latitude compression
        final cosLat = math.cos(centerLat * math.pi / 180.0);
        final lng = centerLng + (r * math.cos(theta) / (cosLat > 0.001 ? cosLat : 1.0));

        final landmark = landmarks[rand.nextInt(landmarks.length)];
        final status = statusPool[rand.nextInt(statusPool.length)];

        final hr = minHr + rand.nextInt(maxHr - minHr + 1);
        final spo2 = minSpo2 + rand.nextInt(maxSpo2 - minSpo2 + 1);
        final temp = double.parse((minTemp + rand.nextDouble() * (maxTemp - minTemp)).toStringAsFixed(1));

        final minutesAgo = rand.nextInt(12);
        final updatedText = minutesAgo == 0 ? 'Just now' : '${minutesAgo}m ago';

        users.add(
          DisasterMonitoredUser(
            userId: 'G1-U${(100 + userIndex)}',
            latitude: double.parse(lat.toStringAsFixed(6)),
            longitude: double.parse(lng.toStringAsFixed(6)),
            locationName: landmark,
            isActive: true,
            healthState: status,
            riskState: riskState,
            isWearableConnected: true,
            heartRate: hr,
            spo2: spo2,
            bodyTemperature: temp,
            lastUpdatedText: updatedText,
            lastUpdated: now.subtract(Duration(minutes: minutesAgo)),
            locationStatus: locStatus,
          ),
        );
        userIndex++;
      }
    }

    // Critical: concentrated towards center hazard zone
    addGroup(
      count: criticalCount,
      riskState: UserHealthRiskState.critical,
      statusPool: criticalStatus,
      minHr: 135,
      maxHr: 156,
      minSpo2: 84,
      maxSpo2: 89,
      minTemp: 39.1,
      maxTemp: 40.2,
      locStatus: 'High Hazard Core',
      minRadiusFraction: 0.05,
      maxRadiusFraction: 0.55,
    );

    // High Risk: mid-inner radius
    addGroup(
      count: highCount,
      riskState: UserHealthRiskState.high,
      statusPool: highStatus,
      minHr: 115,
      maxHr: 134,
      minSpo2: 90,
      maxSpo2: 93,
      minTemp: 38.2,
      maxTemp: 39.0,
      locStatus: 'Impact Perimeter',
      minRadiusFraction: 0.15,
      maxRadiusFraction: 0.75,
    );

    // Moderate: mid-outer radius
    addGroup(
      count: moderateCount,
      riskState: UserHealthRiskState.moderate,
      statusPool: moderateStatus,
      minHr: 90,
      maxHr: 112,
      minSpo2: 94,
      maxSpo2: 96,
      minTemp: 37.3,
      maxTemp: 38.0,
      locStatus: 'Alert Sector',
      minRadiusFraction: 0.25,
      maxRadiusFraction: 0.90,
    );

    // Safe: throughout outer and safe shelters
    addGroup(
      count: safeCount,
      riskState: UserHealthRiskState.stable,
      statusPool: safeStatus,
      minHr: 65,
      maxHr: 82,
      minSpo2: 97,
      maxSpo2: 99,
      minTemp: 36.4,
      maxTemp: 37.0,
      locStatus: 'Safe Perimeter',
      minRadiusFraction: 0.35,
      maxRadiusFraction: 1.0,
    );

    return users;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
