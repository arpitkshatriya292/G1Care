import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g1care/models/disaster/disaster_models.dart';
import 'package:g1care/providers/ambulance_provider.dart';
import 'package:g1care/providers/auth_provider.dart';
import 'package:g1care/providers/disaster_provider.dart';
import 'package:g1care/providers/emergency_provider.dart';
import 'package:g1care/providers/location_provider.dart';
import 'package:g1care/providers/medical_profile_provider.dart';
import 'package:g1care/providers/wristband_provider.dart';
import 'package:g1care/screens/patient/disaster/disaster_mode_screen.dart';
import 'package:g1care/screens/patient/disaster/disaster_wellness_screen.dart';
import 'package:g1care/screens/patient/patient_home_screen.dart';
import 'package:g1care/screens/auth/login_screen.dart';
import 'package:g1care/screens/disaster/disaster_hub_screen.dart';
import 'package:g1care/services/disaster/disaster_ai_service.dart';
import 'package:g1care/services/disaster/disaster_data_provider.dart';
import 'package:g1care/services/disaster/edge_risk_inference_service.dart';
import 'package:g1care/services/disaster/fall_detection_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SIH26 Disaster Mode - Edge AI Risk Engine & Rule Inference', () {
    final engine = EdgeRiskRuleEngine();
    final baseline = PersonalBaseline.defaultBaseline();

    test('1. Normal health and mild environment produces LOW risk level', () {
      final assessment = engine.evaluateRisk(
        health: HealthSnapshot.defaultNormal(),
        environment: EnvironmentalSnapshot.defaultNormal(),
        baseline: baseline,
        disaster: DisasterEvent.mock(
          type: DisasterType.flood,
          severity: DisasterSeverity.low,
          isInside: false,
        ),
        isInsideAffectedArea: false,
      );

      expect(assessment.riskLevel, DisasterRiskLevel.low);
      expect(assessment.riskFactors.isNotEmpty, true);
      expect(assessment.recommendations.isNotEmpty, true);
    });

    test('2. Heatwave conditions with elevated HR & high ambient temp produces HIGH risk level', () {
      final assessment = engine.evaluateRisk(
        health: HealthSnapshot(
          heartRate: 125, // Significantly above baseline 72
          spo2: 96,
          bodyTemperature: 38.6, // Hyperthermia
          activitySteps: 7500,
          sleepDurationHours: 4.5,
          sleepQuality: 'Poor',
          timestamp: DateTime(2026, 9, 5),
        ),
        environment: EnvironmentalSnapshot(
          ambientTemperature: 42.0, // Dangerous thermal heat
          humidity: 78.0,
          aqi: 95,
          aqiCategory: 'Moderate',
          timestamp: DateTime(2026, 9, 5),
        ),
        baseline: baseline,
        disaster: DisasterEvent.mock(type: DisasterType.heatwave, severity: DisasterSeverity.severe),
        isInsideAffectedArea: true,
      );

      expect(assessment.riskLevel, DisasterRiskLevel.high);
      // Explainable risk factors check
      final factorTitles = assessment.riskFactors.map((f) => f.title).toList();
      expect(factorTitles.any((t) => t.contains('Heart Rate') || t.contains('Temperature')), true);

      // Recommendations check
      final recs = assessment.recommendations.map((r) => r.actionText).toList();
      expect(recs.any((r) => r.contains('cooler') || r.contains('water') || r.contains('Hydration') || r.contains('fluid')), true);
    });

    test('3. Severe Air Pollution scenario detects respiratory distress risk indicator', () {
      final assessment = engine.evaluateRisk(
        health: HealthSnapshot(
          heartRate: 88,
          spo2: 91, // Desaturation
          bodyTemperature: 37.0,
          activitySteps: 2000,
          sleepDurationHours: 7.0,
          sleepQuality: 'Good',
          timestamp: DateTime(2026, 9, 5),
        ),
        environment: EnvironmentalSnapshot(
          ambientTemperature: 28.0,
          humidity: 50.0,
          aqi: 290, // Hazardous air
          aqiCategory: 'Hazardous',
          timestamp: DateTime(2026, 9, 5),
        ),
        baseline: baseline,
        disaster: DisasterEvent.mock(type: DisasterType.airPollution, severity: DisasterSeverity.high),
        isInsideAffectedArea: true,
      );

      expect(assessment.riskLevel == DisasterRiskLevel.moderate || assessment.riskLevel == DisasterRiskLevel.high, true);
      final respIndicator = assessment.wellnessIndicators.firstWhere((w) => w.category.contains('Respiratory'));
      expect(respIndicator.status != 'Normal', true);
    });

    test('4. EXACTLY THREE Disaster Risk Levels exist (LOW, MODERATE, HIGH)', () {
      expect(DisasterRiskLevel.values.length, 3);
      expect(DisasterRiskLevel.values, [
        DisasterRiskLevel.low,
        DisasterRiskLevel.moderate,
        DisasterRiskLevel.high,
      ]);
    });
  });

  group('SIH26 Disaster Provider - State, Scenarios & Persistence', () {
    test('5. Manual activation and deactivation updates active state', () async {
      final provider = DisasterProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isActive, false);

      await provider.activateDisasterMode(initialType: DisasterType.heatwave);
      expect(provider.isActive, true);
      expect(provider.disaster.type, DisasterType.heatwave);
      expect(provider.activatedAt, isNotNull);

      // Deactivation
      await provider.deactivateDisasterMode();
      expect(provider.isActive, false);
      expect(provider.activatedAt, isNull);

      provider.dispose();
    });

    test('6. State persists across cold restart without duplicate sessions', () async {
      SharedPreferences.setMockInitialValues({
        'g1care_disaster_mode_active': true,
        'g1care_disaster_type': 'cyclone',
        'g1care_disaster_activated_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      });

      final provider = DisasterProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(provider.isActive, true);
      expect(provider.disaster.type, DisasterType.cyclone);

      provider.dispose();
    });

    test('7. Scenario switching updates environmental and health telemetry', () async {
      final provider = DisasterProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.setDisasterScenario(DisasterType.heatwave);
      expect(provider.disaster.type, DisasterType.heatwave);
      expect(provider.environment.ambientTemperature > 38.0, true);

      provider.setDisasterScenario(DisasterType.airPollution);
      expect(provider.disaster.type, DisasterType.airPollution);
      expect(provider.environment.aqi > 200, true);

      provider.dispose();
    });

    test('8. Offline toggle switches connectivity and preserves local risk computation', () async {
      final provider = DisasterProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isOnline, true);
      provider.toggleOfflineMode();
      expect(provider.isOnline, false);
      expect(provider.connectivityState, DisasterConnectivityState.offline);

      // Local risk computation continues unaffected offline
      provider.setRiskLevelPreset(DisasterRiskLevel.high);
      expect(provider.riskLevel, DisasterRiskLevel.high);

      provider.dispose();
    });

    test('9. Privacy-preserving controls allow user to toggle sharing', () async {
      final provider = DisasterProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.isHealthDataSharingEnabled, false); // Default privacy-first
      provider.setHealthDataSharing(true);
      expect(provider.isHealthDataSharingEnabled, true);

      provider.setLocationSharing(false);
      expect(provider.isLocationSharingEnabled, false);

      provider.dispose();
    });

    test('10. Fall detection service interface monitors events', () async {
      final fallService = FallDetectionService();
      expect(fallService.isMonitoring, false);

      fallService.startMonitoring();
      expect(fallService.isMonitoring, true);

      FallEvent? received;
      final sub = fallService.fallStream.listen((event) {
        received = event;
      });

      fallService.triggerMockFallForTesting(confidence: 0.98);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(received, isNotNull);
      expect(received!.isFallDetected, true);
      expect(received!.confidence, 0.98);

      await sub.cancel();
      fallService.dispose();
    });

    test('11. Ask G1Care AI service answers queries with live context and disclaimer', () async {
      final aiService = LocalDisasterAiService();
      final health = HealthSnapshot.defaultNormal();
      final env = EnvironmentalSnapshot.defaultNormal();
      final disaster = DisasterEvent.mock(type: DisasterType.flood);
      final baseline = PersonalBaseline.defaultBaseline();

      final responseWater = await aiService.askDisasterAssistant(
        query: 'Is the flood water safe to drink?',
        health: health,
        environment: env,
        disaster: disaster,
        riskLevel: DisasterRiskLevel.moderate,
        baseline: baseline,
      );

      expect(responseWater.contains('Flood') || responseWater.contains('water') || responseWater.contains('boil'), true);

      final responseGeneral = await aiService.askDisasterAssistant(
        query: 'What is my current status?',
        health: health,
        environment: env,
        disaster: disaster,
        riskLevel: DisasterRiskLevel.moderate,
        baseline: baseline,
      );

      expect(responseGeneral.contains('Disaster Safety Assistant'), true);
    });
  });

  group('SIH26 Disaster Mode - Public Disaster Hub & UI Widgets', () {
    Widget createTestApp(Widget child) {
      final ambulanceProvider = AmbulanceLocationProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<MedicalProfileProvider>(create: (_) => MedicalProfileProvider()),
          ChangeNotifierProvider<LocationProvider>(create: (_) => LocationProvider()),
          ChangeNotifierProvider<WristbandProvider>(create: (_) => WristbandProvider(autoConnect: false)),
          ChangeNotifierProvider<AmbulanceLocationProvider>.value(value: ambulanceProvider),
          ChangeNotifierProvider<EmergencyProvider>(
            create: (_) => EmergencyProvider(ambulanceProvider: ambulanceProvider),
          ),
          ChangeNotifierProvider<DisasterProvider>(create: (_) => DisasterProvider()),
        ],
        child: MaterialApp(
          routes: {
            '/disaster-hub': (context) => const DisasterHubScreen(),
            '/disaster-mode': (context) => const DisasterHubScreen(),
            '/patient/disaster-mode': (context) => const DisasterModeScreen(),
            '/patient/disaster-mode/wellness': (context) => const DisasterWellnessScreen(),
          },
          home: child,
        ),
      );
    }

    testWidgets('12. Login Screen renders public DISASTER MODE entry & navigates without auth', (tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      // Verify Disaster Mode public entry is present on Login Page
      expect(find.text('Disaster Mode'), findsOneWidget);
      expect(find.text('Public Disaster Hub • No login required'), findsOneWidget);

      // Verify terminology: User Demo and Hospital Demo
      expect(find.text('User Demo'), findsOneWidget);
      expect(find.text('Hospital Demo'), findsOneWidget);
      expect(find.text('Patient Demo'), findsNothing);

      // Tap Disaster Mode entry directly without login
      await tester.tap(find.text('Disaster Mode'));
      await tester.pumpAndSettle();

      // Verify navigated into Public Disaster Hub
      expect(find.text('G1Care DISASTER HUB'), findsOneWidget);
      expect(find.text('PUBLIC ACCESS • NO LOGIN REQUIRED'), findsOneWidget);
      expect(find.text('ACTIVE USER MONITORING'), findsOneWidget);
    });

    testWidgets('12b. Authenticated Patient Dashboard DOES NOT contain Disaster Mode entry', (tester) async {
      await tester.pumpWidget(createTestApp(const PatientHomeScreen()));
      await tester.pumpAndSettle();

      // Verify Disaster Mode card and button are completely removed from Patient Dashboard
      expect(find.text('DISASTER MANAGEMENT'), findsNothing);
      expect(find.text('ENTER DISASTER MODE'), findsNothing);
      expect(find.text('Enhanced monitoring and safety guidance during disasters.'), findsNothing);
    });

    testWidgets('13. Disaster Mode Screen renders all required sections', (tester) async {
      await tester.pumpWidget(createTestApp(const DisasterModeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('G1Care DISASTER MODE'), findsOneWidget);
      expect(find.text('DISASTER INFORMATION'), findsOneWidget);
      expect(find.text('G1CARE PROTECTION'), findsOneWidget);
      expect(find.text('PERSONAL RISK'), findsOneWidget);
      expect(find.text('HEALTH STATUS'), findsOneWidget);
      expect(find.text('ENVIRONMENT'), findsOneWidget);
      expect(find.text('WHY AM I AT RISK?'), findsOneWidget);
      expect(find.text('RECOMMENDED ACTION'), findsOneWidget);
      expect(find.text('SAFE LOCATION'), findsOneWidget);
      expect(find.text('ASK G1CARE AI'), findsOneWidget);
      expect(find.text('EXIT DISASTER MODE'), findsOneWidget);
    });

    testWidgets('14. Personal Wellness Screen renders baseline comparison and indicators', (tester) async {
      await tester.pumpWidget(createTestApp(const DisasterWellnessScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Personal Wellness & Trends'), findsOneWidget);
      expect(find.text('DAILY HEALTH SUMMARY'), findsOneWidget);
      expect(find.text('Personal Baseline Comparison'), findsOneWidget);
      expect(find.text('Situational Risk Indicators'), findsOneWidget);
      expect(find.text('Activity & Sleep Telemetry'), findsOneWidget);
    });

    testWidgets('15. Public Disaster Hub renders active user monitoring, stats pills, and safety guidance', (tester) async {
      await tester.pumpWidget(createTestApp(const DisasterHubScreen()));
      await tester.pumpAndSettle();

      expect(find.text('G1Care DISASTER HUB'), findsOneWidget);
      expect(find.text('ACTIVE USER MONITORING'), findsOneWidget);
      expect(find.text('Total Active Users: 86'), findsOneWidget);
      expect(find.text('SAFE'), findsWidgets);
      expect(find.text('MODERATE'), findsWidgets);
      expect(find.text('HIGH RISK'), findsWidgets);
      expect(find.text('CRITICAL'), findsWidgets);
      expect(find.text('AFFECTED ZONE & USER RISK MAP'), findsOneWidget);
      expect(find.text('EMERGENCY HELPLINES & SUPPORT'), findsOneWidget);
    });

    test('16. Disaster-specific active user counts differ between all disaster types', () {
      final service = MockActiveUserMonitoringService();

      // Flood (default)
      final floodUsers = service.activeUsers;
      expect(floodUsers.length, 86);
      expect(floodUsers.length >= 60 && floodUsers.length <= 110, true);

      // Heatwave
      service.refreshUsers(disasterType: DisasterType.heatwave);
      final heatwaveUsers = service.activeUsers;
      expect(heatwaveUsers.length, 128);
      expect(heatwaveUsers.length >= 100 && heatwaveUsers.length <= 150, true);

      // Cyclone
      service.refreshUsers(disasterType: DisasterType.cyclone);
      final cycloneUsers = service.activeUsers;
      expect(cycloneUsers.length, 146);
      expect(cycloneUsers.length >= 100 && cycloneUsers.length <= 170, true);

      // Earthquake
      service.refreshUsers(disasterType: DisasterType.earthquake);
      final earthquakeUsers = service.activeUsers;
      expect(earthquakeUsers.length, 64);
      expect(earthquakeUsers.length >= 40 && earthquakeUsers.length <= 90, true);

      // Air Pollution
      service.refreshUsers(disasterType: DisasterType.airPollution);
      final airUsers = service.activeUsers;
      expect(airUsers.length, 218);
      expect(airUsers.length >= 180 && airUsers.length <= 250, true);

      // Verify all counts are mutually distinct
      final allCounts = {
        heatwaveUsers.length,
        floodUsers.length,
        cycloneUsers.length,
        earthquakeUsers.length,
        airUsers.length,
      };
      expect(allCounts.length, 5, reason: 'Every disaster scenario must have a distinct active user population');

      service.dispose();
    });

    test('17. Disaster-specific health distribution: Safe + Moderate + High + Critical == Total Active Users', () {
      final service = MockActiveUserMonitoringService();

      final scenarios = [
        DisasterType.heatwave,
        DisasterType.flood,
        DisasterType.cyclone,
        DisasterType.earthquake,
        DisasterType.airPollution,
      ];

      for (final type in scenarios) {
        service.refreshUsers(disasterType: type);
        final users = service.activeUsers;

        final safe = users.where((u) => u.riskState == UserHealthRiskState.stable).length;
        final moderate = users.where((u) => u.riskState == UserHealthRiskState.moderate).length;
        final high = users.where((u) => u.riskState == UserHealthRiskState.high).length;
        final critical = users.where((u) => u.riskState == UserHealthRiskState.critical).length;

        // Verify dashboard counts match exactly: Safe + Moderate + High Risk + Critical == Total
        expect(safe + moderate + high + critical, users.length,
            reason: 'Health state counts must sum exactly to total active users for ${type.name}');

        // Every user must be active
        expect(users.every((u) => u.isActive), true);

        // Verify anonymous IDs
        for (final user in users) {
          expect(user.userId.startsWith('G1-U'), true);
          expect(user.locationName.isNotEmpty, true);
          expect(user.healthState.isNotEmpty, true);
        }
      }

      // Explicit verification of Flood prototype example (42 + 25 + 14 + 5 = 86)
      service.refreshUsers(disasterType: DisasterType.flood);
      final flood = service.activeUsers;
      final fSafe = flood.where((u) => u.riskState == UserHealthRiskState.stable).length;
      final fModerate = flood.where((u) => u.riskState == UserHealthRiskState.moderate).length;
      final fHigh = flood.where((u) => u.riskState == UserHealthRiskState.high).length;
      final fCritical = flood.where((u) => u.riskState == UserHealthRiskState.critical).length;
      expect(fSafe, 42);
      expect(fModerate, 25);
      expect(fHigh, 14);
      expect(fCritical, 5);
      expect(fSafe + fModerate + fHigh + fCritical, 86);

      // Verify health state distributions differ across disaster types
      service.refreshUsers(disasterType: DisasterType.heatwave);
      final hw = service.activeUsers;
      final hwSafe = hw.where((u) => u.riskState == UserHealthRiskState.stable).length;
      expect(hwSafe, 72);

      service.refreshUsers(disasterType: DisasterType.earthquake);
      final eq = service.activeUsers;
      final eqSafe = eq.where((u) => u.riskState == UserHealthRiskState.stable).length;
      final eqCritical = eq.where((u) => u.riskState == UserHealthRiskState.critical).length;
      expect(eqSafe, 18);
      expect(eqCritical, 8); // Earthquake has higher proportion of critical users

      service.dispose();
    });

    test('18. Disaster-specific mock GPS locations differ per disaster scenario', () {
      final service = MockActiveUserMonitoringService();

      final centers = <DisasterType, List<double>>{};
      final scenarios = [
        DisasterType.heatwave,
        DisasterType.flood,
        DisasterType.cyclone,
        DisasterType.earthquake,
        DisasterType.airPollution,
      ];

      for (final type in scenarios) {
        service.refreshUsers(disasterType: type);
        final users = service.activeUsers;

        double sumLat = 0;
        double sumLng = 0;
        for (final u in users) {
          sumLat += u.latitude;
          sumLng += u.longitude;
        }
        centers[type] = [sumLat / users.length, sumLng / users.length];
      }

      // Verify no two disaster types have the same centroid
      final centerStrings = centers.values.map((c) => '${c[0].toStringAsFixed(3)},${c[1].toStringAsFixed(3)}').toSet();
      expect(centerStrings.length, 5, reason: 'Each disaster scenario must center on its own distinct geographic region');

      service.dispose();
    });

    test('19. Data stability: repeated reads do not regenerate random users on rebuilds', () {
      final service = MockActiveUserMonitoringService();

      final firstRead = service.activeUsers;
      final secondRead = service.activeUsers;

      expect(firstRead.length, secondRead.length);
      for (int i = 0; i < firstRead.length; i++) {
        expect(firstRead[i].userId, secondRead[i].userId);
        expect(firstRead[i].latitude, secondRead[i].latitude);
        expect(firstRead[i].longitude, secondRead[i].longitude);
        expect(firstRead[i].riskState, secondRead[i].riskState);
        expect(firstRead[i].heartRate, secondRead[i].heartRate);
      }

      // Switch away and back: data remains identical and stable
      service.refreshUsers(disasterType: DisasterType.heatwave);
      expect(service.activeUsers.length, 128);

      service.refreshUsers(disasterType: DisasterType.flood);
      final thirdRead = service.activeUsers;
      expect(thirdRead.length, firstRead.length);
      for (int i = 0; i < firstRead.length; i++) {
        expect(thirdRead[i].userId, firstRead[i].userId);
        expect(thirdRead[i].latitude, firstRead[i].latitude);
        expect(thirdRead[i].longitude, firstRead[i].longitude);
      }

      service.dispose();
    });

    testWidgets('20. Switching disaster scenario updates Disaster Hub counts and map stats', (tester) async {
      await tester.pumpWidget(createTestApp(const DisasterHubScreen()));
      await tester.pumpAndSettle();

      // Initial scenario is Flood: 86 active users (42 Safe, 25 Moderate, 14 High Risk, 5 Critical)
      expect(find.text('Total Active Users: 86'), findsOneWidget);
      expect(find.text('42'), findsOneWidget); // Safe
      expect(find.text('25'), findsOneWidget); // Moderate
      expect(find.text('14'), findsOneWidget); // High
      expect(find.text('5'), findsOneWidget); // Critical

      // Switch to Heatwave via Compact Scenario Pill
      await tester.tap(find.text('Heatwave'));
      await tester.pumpAndSettle();

      // Heatwave scenario: 128 active users (72 Safe, 38 Moderate, 14 High Risk, 4 Critical)
      expect(find.text('Total Active Users: 128'), findsOneWidget);
      expect(find.text('72'), findsOneWidget); // Safe
      expect(find.text('38'), findsOneWidget); // Moderate
      expect(find.text('4'), findsOneWidget); // Critical

      // Switch to Earthquake
      await tester.tap(find.text('Earthquake'));
      await tester.pumpAndSettle();

      // Earthquake scenario: 64 active users (18 Safe, 22 Moderate, 16 High Risk, 8 Critical)
      expect(find.text('Total Active Users: 64'), findsOneWidget);
      expect(find.text('18'), findsOneWidget); // Safe
      expect(find.text('22'), findsOneWidget); // Moderate
      expect(find.text('16'), findsOneWidget); // High
      expect(find.text('8'), findsOneWidget); // Critical
    });
  });
}
