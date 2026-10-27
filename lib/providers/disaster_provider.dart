import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/disaster/disaster_models.dart';
import '../services/disaster/disaster_data_provider.dart';
import '../services/disaster/edge_risk_inference_service.dart';
import '../services/disaster/fall_detection_service.dart';
import '../services/disaster/disaster_ai_service.dart';

class DisasterProvider extends ChangeNotifier {
  static const String _keyDisasterActive = 'g1care_disaster_mode_active';
  static const String _keyDisasterType = 'g1care_disaster_type';
  static const String _keyDisasterActivatedAt = 'g1care_disaster_activated_at';

  // Services
  final IHealthDataProvider _healthDataProvider;
  final IEnvironmentalDataProvider _environmentalDataProvider;
  final IDisasterDataProvider _disasterDataProvider;
  final IEdgeRiskInferenceService _riskEngine;
  final IFallDetectionService _fallDetectionService;
  final IDisasterAiService _aiService;
  final IActiveUserMonitoringService _activeUserService;

  // Active state
  bool _isActive = false;
  DateTime? _activatedAt;
  bool _isInsideAffectedArea = true;
  DisasterConnectivityState _connectivityState = DisasterConnectivityState.online;

  // Privacy Controls (Privacy-first: Health data stays on device unless explicitly shared)
  bool _isHealthDataSharingEnabled = false;
  bool _isLocationSharingEnabled = true;
  bool _isEmergencySharingEnabled = true;

  // Data snapshots
  late HealthSnapshot _health;
  late EnvironmentalSnapshot _environment;
  late DisasterEvent _disaster;
  final PersonalBaseline _baseline = PersonalBaseline.defaultBaseline();
  late EdgeRiskAssessment _assessment;

  // Active user monitoring
  List<DisasterMonitoredUser> _monitoredUsers = [];
  DisasterMonitoredUser? _selectedUser;

  // Subscriptions
  StreamSubscription<HealthSnapshot>? _healthSub;
  StreamSubscription<EnvironmentalSnapshot>? _envSub;
  StreamSubscription<DisasterEvent>? _disasterSub;
  StreamSubscription<FallEvent>? _fallSub;
  StreamSubscription<List<DisasterMonitoredUser>>? _userSub;

  DisasterProvider({
    IHealthDataProvider? healthDataProvider,
    IEnvironmentalDataProvider? environmentalDataProvider,
    IDisasterDataProvider? disasterDataProvider,
    IEdgeRiskInferenceService? riskEngine,
    IFallDetectionService? fallDetectionService,
    IDisasterAiService? aiService,
    IActiveUserMonitoringService? activeUserService,
  })  : _healthDataProvider = healthDataProvider ?? MockHealthDataProvider(),
        _environmentalDataProvider = environmentalDataProvider ?? MockEnvironmentalDataProvider(),
        _disasterDataProvider = disasterDataProvider ?? MockDisasterDataProvider(),
        _riskEngine = riskEngine ?? EdgeRiskRuleEngine(),
        _fallDetectionService = fallDetectionService ?? FallDetectionService(),
        _aiService = aiService ?? LocalDisasterAiService(),
        _activeUserService = activeUserService ?? MockActiveUserMonitoringService() {
    _health = _healthDataProvider.currentHealth;
    _environment = _environmentalDataProvider.currentEnvironment;
    _disaster = _disasterDataProvider.currentEvent;
    _monitoredUsers = _activeUserService.activeUsers;
    _evaluateEdgeRisk();
    _initPersistenceAndListeners();
  }

  // Getters
  bool get isActive => _isActive;
  DateTime? get activatedAt => _activatedAt;
  bool get isInsideAffectedArea => _isInsideAffectedArea;
  DisasterConnectivityState get connectivityState => _connectivityState;
  bool get isOnline => _connectivityState == DisasterConnectivityState.online;

  bool get isHealthDataSharingEnabled => _isHealthDataSharingEnabled;
  bool get isLocationSharingEnabled => _isLocationSharingEnabled;
  bool get isEmergencySharingEnabled => _isEmergencySharingEnabled;

  HealthSnapshot get health => _health;
  EnvironmentalSnapshot get environment => _environment;
  DisasterEvent get disaster => _disaster;
  PersonalBaseline get baseline => _baseline;
  EdgeRiskAssessment get assessment => _assessment;
  DisasterRiskLevel get riskLevel => _assessment.riskLevel;
  List<RiskFactor> get riskFactors => _assessment.riskFactors;
  List<WellnessIndicator> get wellnessIndicators => _assessment.wellnessIndicators;
  List<DisasterRecommendation> get recommendations => _assessment.recommendations;

  IFallDetectionService get fallDetectionService => _fallDetectionService;
  IDisasterAiService get aiService => _aiService;
  IActiveUserMonitoringService get activeUserService => _activeUserService;

  // Active user getters
  List<DisasterMonitoredUser> get monitoredUsers => _monitoredUsers;
  int get totalActiveUsersCount => _monitoredUsers.where((u) => u.isActive).length;
  int get totalMonitoredUsersCount => _monitoredUsers.length;
  int get safeUsersCount => _monitoredUsers.where((u) => u.riskState == UserHealthRiskState.stable).length;
  int get stableUsersCount => safeUsersCount;
  int get moderateUsersCount => _monitoredUsers.where((u) => u.riskState == UserHealthRiskState.moderate).length;
  int get highRiskUsersCount => _monitoredUsers.where((u) => u.riskState == UserHealthRiskState.high).length;
  int get criticalUsersCount => _monitoredUsers.where((u) => u.riskState == UserHealthRiskState.critical).length;
  int get offlineUsersCount => _monitoredUsers.where((u) => u.riskState == UserHealthRiskState.offline).length;
  DisasterMonitoredUser? get selectedUser => _selectedUser;

  void selectMonitoredUser(DisasterMonitoredUser? user) {
    _selectedUser = user;
    notifyListeners();
  }

  // Persistence & Initialization
  Future<void> _initPersistenceAndListeners() async {
    // Restore persisted state across cold restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool(_keyDisasterActive) ?? false;
      if (active) {
        _isActive = true;
        final typeStr = prefs.getString(_keyDisasterType);
        if (typeStr != null) {
          final type = DisasterType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => DisasterType.flood,
          );
          _disasterDataProvider.setScenario(type);
          _disaster = _disasterDataProvider.currentEvent;
        }
        final activatedAtStr = prefs.getString(_keyDisasterActivatedAt);
        if (activatedAtStr != null) {
          _activatedAt = DateTime.tryParse(activatedAtStr) ?? DateTime.now();
        } else {
          _activatedAt = DateTime.now();
        }
        _fallDetectionService.startMonitoring();
      }
    } catch (e) {
      debugPrint('Notice loading persisted Disaster Mode state: $e');
    }

    // Subscribe to continuous streams
    _healthSub = _healthDataProvider.healthStream.listen((h) {
      _health = h;
      _evaluateEdgeRisk();
      notifyListeners();
    });

    _envSub = _environmentalDataProvider.environmentStream.listen((env) {
      _environment = env;
      _evaluateEdgeRisk();
      notifyListeners();
    });

    _disasterSub = _disasterDataProvider.eventStream.listen((d) {
      _disaster = d;
      _evaluateEdgeRisk();
      notifyListeners();
    });

    _userSub = _activeUserService.usersStream.listen((users) {
      _monitoredUsers = users;
      notifyListeners();
    });

    _evaluateEdgeRisk();
    notifyListeners();
  }

  /// Manually activate Disaster Mode (Prompt requirement: Manual activation only)
  Future<void> activateDisasterMode({DisasterType? initialType}) async {
    if (_isActive) return; // Prevent duplicate sessions

    _isActive = true;
    _activatedAt = DateTime.now();
    if (initialType != null) {
      _disasterDataProvider.setScenario(initialType);
      _disaster = _disasterDataProvider.currentEvent;
    }

    _fallDetectionService.startMonitoring();
    _evaluateEdgeRisk();

    // Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDisasterActive, true);
      await prefs.setString(_keyDisasterType, _disaster.type.name);
      await prefs.setString(_keyDisasterActivatedAt, _activatedAt!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving Disaster Mode state: $e');
    }

    notifyListeners();
  }

  /// Manually deactivate Disaster Mode
  Future<void> deactivateDisasterMode() async {
    if (!_isActive) return;

    _isActive = false;
    _activatedAt = null;
    _fallDetectionService.stopMonitoring();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDisasterActive, false);
      await prefs.remove(_keyDisasterType);
      await prefs.remove(_keyDisasterActivatedAt);
    } catch (e) {
      debugPrint('Error clearing Disaster Mode state: $e');
    }

    notifyListeners();
  }

  /// Edge Risk Evaluation: 100% on-device local computation
  void _evaluateEdgeRisk() {
    _assessment = _riskEngine.evaluateRisk(
      health: _health,
      environment: _environment,
      baseline: _baseline,
      disaster: _disaster,
      isInsideAffectedArea: _isInsideAffectedArea,
    );
  }

  /// Scenario Switcher for Prototype Scenarios: HEATWAVE, FLOOD, CYCLONE, AIR POLLUTION
  void setDisasterScenario(DisasterType type) {
    _disasterDataProvider.setScenario(type);
    _disaster = _disasterDataProvider.currentEvent;

    // Set contextual initial values for the scenario
    switch (type) {
      case DisasterType.heatwave:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 41.5,
          humidity: 68.0,
          aqi: 95,
          aqiCategory: 'Moderate',
        );
        _healthDataProvider.updateVitals(
          heartRate: 98,
          spo2: 97,
          bodyTemperature: 38.1,
          activitySteps: 4500,
        );
        break;

      case DisasterType.flood:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 27.0,
          humidity: 88.0,
          aqi: 55,
          aqiCategory: 'Good',
        );
        _healthDataProvider.updateVitals(
          heartRate: 88,
          spo2: 97,
          bodyTemperature: 36.9,
          activitySteps: 3200,
        );
        break;

      case DisasterType.cyclone:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 25.5,
          humidity: 92.0,
          aqi: 40,
          aqiCategory: 'Good',
        );
        _healthDataProvider.updateVitals(
          heartRate: 86,
          spo2: 98,
          bodyTemperature: 36.7,
          activitySteps: 1800,
        );
        break;

      case DisasterType.airPollution:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 28.0,
          humidity: 50.0,
          aqi: 285,
          aqiCategory: 'Hazardous',
        );
        _healthDataProvider.updateVitals(
          heartRate: 92,
          spo2: 93,
          bodyTemperature: 36.8,
          activitySteps: 2100,
        );
        break;

      case DisasterType.earthquake:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 27.5,
          humidity: 52.0,
          aqi: 80,
          aqiCategory: 'Moderate',
        );
        _healthDataProvider.updateVitals(
          heartRate: 102,
          spo2: 97,
          bodyTemperature: 37.0,
          activitySteps: 1600,
        );
        break;

      case DisasterType.other:
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 30.0,
          humidity: 60.0,
          aqi: 75,
          aqiCategory: 'Moderate',
        );
        break;
    }

    _environment = _environmentalDataProvider.currentEnvironment;
    _health = _healthDataProvider.currentHealth;
    _evaluateEdgeRisk();
    _activeUserService.refreshUsers(disasterType: type);
    _monitoredUsers = _activeUserService.activeUsers;
    _selectedUser = null;

    if (_isActive) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_keyDisasterType, _disaster.type.name);
      });
    }

    notifyListeners();
  }

  /// Preset Risk Levels for Testing (LOW / MODERATE / HIGH)
  void setRiskLevelPreset(DisasterRiskLevel targetLevel) {
    switch (targetLevel) {
      case DisasterRiskLevel.low:
        _isInsideAffectedArea = false;
        _healthDataProvider.updateVitals(
          heartRate: 72,
          spo2: 98,
          bodyTemperature: 36.6,
          activitySteps: 2200,
          sleepDurationHours: 7.8,
          sleepQuality: 'Good',
        );
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 29.0,
          humidity: 55.0,
          aqi: 60,
          aqiCategory: 'Moderate',
        );
        break;

      case DisasterRiskLevel.moderate:
        _isInsideAffectedArea = true;
        _healthDataProvider.updateVitals(
          heartRate: 98,
          spo2: 95,
          bodyTemperature: 37.7,
          activitySteps: 4800,
          sleepDurationHours: 6.0,
          sleepQuality: 'Fair',
        );
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 37.0,
          humidity: 70.0,
          aqi: 165,
          aqiCategory: 'Unhealthy',
        );
        break;

      case DisasterRiskLevel.high:
        _isInsideAffectedArea = true;
        _healthDataProvider.updateVitals(
          heartRate: 128,
          spo2: 90,
          bodyTemperature: 38.9,
          activitySteps: 8500,
          sleepDurationHours: 4.2,
          sleepQuality: 'Poor',
        );
        _environmentalDataProvider.updateConditions(
          ambientTemperature: 42.5,
          humidity: 78.0,
          aqi: 310,
          aqiCategory: 'Hazardous',
        );
        break;
    }

    _environment = _environmentalDataProvider.currentEnvironment;
    _health = _healthDataProvider.currentHealth;
    _evaluateEdgeRisk();
    notifyListeners();
  }

  /// Update vitals manually from UI or mock stream
  void updateVitals({
    int? heartRate,
    int? spo2,
    double? bodyTemperature,
    int? activitySteps,
    double? sleepDurationHours,
    String? sleepQuality,
  }) {
    _healthDataProvider.updateVitals(
      heartRate: heartRate,
      spo2: spo2,
      bodyTemperature: bodyTemperature,
      activitySteps: activitySteps,
      sleepDurationHours: sleepDurationHours,
      sleepQuality: sleepQuality,
    );
    _health = _healthDataProvider.currentHealth;
    _evaluateEdgeRisk();
    notifyListeners();
  }

  /// Update environmental data
  void updateEnvironmental({
    double? ambientTemperature,
    double? humidity,
    int? aqi,
    String? aqiCategory,
  }) {
    _environmentalDataProvider.updateConditions(
      ambientTemperature: ambientTemperature,
      humidity: humidity,
      aqi: aqi,
      aqiCategory: aqiCategory,
    );
    _environment = _environmentalDataProvider.currentEnvironment;
    _evaluateEdgeRisk();
    notifyListeners();
  }

  /// Toggle connectivity state for offline testing
  void setConnectivityState(DisasterConnectivityState state) {
    _connectivityState = state;
    notifyListeners();
  }

  /// Simulate offline mode toggle
  void toggleOfflineMode() {
    if (_connectivityState == DisasterConnectivityState.online) {
      _connectivityState = DisasterConnectivityState.offline;
    } else {
      _connectivityState = DisasterConnectivityState.syncing;
      notifyListeners();
      // Simulate rapid sync completion without duplicating events
      Future.delayed(const Duration(milliseconds: 600), () {
        _connectivityState = DisasterConnectivityState.online;
        notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  /// Privacy toggles
  void setHealthDataSharing(bool enabled) {
    _isHealthDataSharingEnabled = enabled;
    notifyListeners();
  }

  void setLocationSharing(bool enabled) {
    _isLocationSharingEnabled = enabled;
    notifyListeners();
  }

  void setEmergencySharing(bool enabled) {
    _isEmergencySharingEnabled = enabled;
    notifyListeners();
  }

  /// Controlled safe shelters and relief locations around Pune / Shivajinagar
  List<SafeLocation> get safeLocations => const [
        SafeLocation(
          id: 'SHELTER-01',
          name: 'Shivajinagar Municipal Community Relief Shelter',
          type: 'Emergency Shelter',
          latitude: 18.5308,
          longitude: 73.8475,
          distanceKm: 1.4,
          capacity: '350 Beds (Operational)',
          isOpen: true,
          routeNote: 'Elevated terrain. Recommended safe approach via JM Road.',
        ),
        SafeLocation(
          id: 'HOSP-01',
          name: 'Sancheti Emergency Trauma & Specialty Hospital',
          type: 'Hospital',
          latitude: 18.5298,
          longitude: 73.8540,
          distanceKm: 1.1,
          capacity: 'Emergency ER Open 24/7',
          isOpen: true,
          routeNote: 'Direct connectivity. Verified clear route.',
        ),
        SafeLocation(
          id: 'SHELTER-02',
          name: 'Deccan Gymkhana Relief Camp & Distribution Center',
          type: 'Safe Zone',
          latitude: 18.5170,
          longitude: 73.8415,
          distanceKm: 2.3,
          capacity: 'Food & Clean Water Supply Active',
          isOpen: true,
          routeNote: 'Disaster-aware advisory: Avoid low-lying river bridge.',
        ),
        SafeLocation(
          id: 'HOSP-02',
          name: 'KEM Hospital & Research Centre',
          type: 'Hospital',
          latitude: 18.5240,
          longitude: 73.8690,
          distanceKm: 2.8,
          capacity: 'High-Capacity Critical Care Center',
          isOpen: true,
          routeNote: 'Main arterial roads clear. Medical triage on standby.',
        ),
      ];

  @override
  void dispose() {
    _healthSub?.cancel();
    _envSub?.cancel();
    _disasterSub?.cancel();
    _fallSub?.cancel();
    _userSub?.cancel();
    _activeUserService.dispose();
    super.dispose();
  }
}
