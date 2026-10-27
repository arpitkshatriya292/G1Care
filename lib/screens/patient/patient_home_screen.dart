import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/emergency_incident.dart';
import '../../models/vital_reading.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/medical_profile_provider.dart';
import '../../providers/wristband_provider.dart';
import '../../services/health_evaluator.dart';
import '../../services/notification_service.dart';
import '../../widgets/vital_card.dart';
import '../../widgets/sos_button.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  bool _isAutoTriggering = false;
  DateTime? _lastAutoTriggerTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);

      if (authProvider.patientUser != null) {
        profileProvider.loadProfile(
          authProvider.patientUser!.uid,
          name: authProvider.patientUser!.name,
          phone: authProvider.patientUser!.phone,
        );
        emergencyProvider.syncPatientEmergencyState(authProvider.patientUser!.uid);
      }
      locationProvider.refreshLocation();
      NotificationService().consumePendingNavigation();
    });
  }

  void _checkAutomaticEmergency(
    VitalReading vitals,
    HealthEvaluationResult healthStatus,
    bool isConnected,
    bool hasActiveEmergency,
  ) {
    if (!isConnected || hasActiveEmergency || _isAutoTriggering) return;

    final isFall = vitals.isFallDetected;
    final isCriticalSpO2 = vitals.spo2 < 90; // Configured safety threshold: <90%

    if (isFall || (healthStatus.overallLevel == HealthRiskLevel.critical && isCriticalSpO2)) {
      final now = DateTime.now();
      if (_lastAutoTriggerTime != null && now.difference(_lastAutoTriggerTime!).inSeconds < 10) {
        return; // debounce / de-duplicate repeated calls for same event
      }

      final trigger = isFall ? EmergencyTriggerType.fallDetected : EmergencyTriggerType.criticalVitals;
      final reason = isFall ? 'Fall detected' : 'Critical SpO2 detected (${vitals.spo2}% < 90%)';

      _isAutoTriggering = true;
      _lastAutoTriggerTime = now;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _triggerAutomaticEmergencyAlert(trigger, reason);
        }
      });
    }
  }

  Future<void> _triggerAutomaticEmergencyAlert(EmergencyTriggerType trigger, String reason) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
    final wristbandProvider = Provider.of<WristbandProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);

    if (emergencyProvider.hasActiveEmergency) {
      _isAutoTriggering = false;
      return;
    }

    final profile = profileProvider.profile;
    final patientUser = authProvider.patientUser;
    final vitals = wristbandProvider.currentVitals;
    final location = locationProvider.currentLocation;

    await emergencyProvider.triggerEmergencySos(
      patientUid: patientUser?.uid ?? 'USER-001',
      medicalId: profile?.medicalId ?? 'G1-MED-DEMO',
      patientName: profile?.fullName ?? patientUser?.name ?? 'User',
      bloodGroup: profile?.bloodGroup ?? 'Unknown',
      emergencyPhone: profile?.emergencyContactInfo.phone ?? patientUser?.phone ?? '',
      criticalAllergies: profile?.allergies ?? [],
      triggerType: trigger,
      vitalsSnapshot: vitals,
      latitude: location.latitude,
      longitude: location.longitude,
      locationAddress: location.address,
      isSimulatedLocation: location.isSimulated,
    );

    _isAutoTriggering = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emergency, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CRITICAL CONDITION DETECTED ($reason): Emergency response automatically activated.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.emergencyRed,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pushNamed(context, '/patient/emergency-map');
    }
  }

  Future<void> _triggerSosAlert() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
    final wristbandProvider = Provider.of<WristbandProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);

    final profile = profileProvider.profile;
    final patientUser = authProvider.patientUser;
    final vitals = wristbandProvider.currentVitals;
    final location = locationProvider.currentLocation;

    final trigger = vitals.isFallDetected
        ? EmergencyTriggerType.fallDetected
        : EmergencyTriggerType.manualSos;

    await emergencyProvider.triggerEmergencySos(
      patientUid: patientUser?.uid ?? 'USER-001',
      medicalId: profile?.medicalId ?? 'G1-MED-DEMO',
      patientName: profile?.fullName ?? patientUser?.name ?? 'User',
      bloodGroup: profile?.bloodGroup ?? 'Unknown',
      emergencyPhone: profile?.emergencyContactInfo.phone ?? patientUser?.phone ?? '',
      criticalAllergies: profile?.allergies ?? [],
      triggerType: trigger,
      vitalsSnapshot: vitals,
      latitude: location.latitude,
      longitude: location.longitude,
      locationAddress: location.address,
      isSimulatedLocation: location.isSimulated,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.emergency, color: Colors.white),
              SizedBox(width: 10),
              Text('EMERGENCY: SOS Alert & GPS Transmitted to Hospital Network!'),
            ],
          ),
          backgroundColor: AppColors.emergencyRed,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate immediately to the Emergency Tracking Map
      Navigator.pushNamed(context, '/patient/emergency-map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<MedicalProfileProvider>(context);
    final wristbandProvider = Provider.of<WristbandProvider>(context);
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    final patientName = authProvider.patientUser?.name ?? 'User';
    final profile = profileProvider.profile;
    final isConnected = wristbandProvider.isConnected;
    final vitals = wristbandProvider.currentVitals;
    final rawHealthStatus = wristbandProvider.healthStatus;
    final hasActiveEmergency = emergencyProvider.hasActiveEmergency;
    final healthStatus = hasActiveEmergency
        ? HealthEvaluationResult(
            overallLevel: HealthRiskLevel.critical,
            criticalReasons: [
              'ACTIVE EMERGENCY: Response unit dispatched (${emergencyProvider.currentPatientIncident?.assignedHospitalName ?? "Emergency Center"}).',
            ],
            warningReasons: const [],
            hrLevel: rawHealthStatus.hrLevel == HealthRiskLevel.normal ? HealthRiskLevel.critical : rawHealthStatus.hrLevel,
            spo2Level: rawHealthStatus.spo2Level == HealthRiskLevel.normal ? HealthRiskLevel.critical : rawHealthStatus.spo2Level,
            rrLevel: rawHealthStatus.rrLevel,
            fallLevel: rawHealthStatus.fallLevel,
          )
        : rawHealthStatus;

    // Check if automatic critical emergency trigger condition is met
    _checkAutomaticEmergency(vitals, rawHealthStatus, isConnected, hasActiveEmergency);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 26,
              width: 26,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 8),
            const Text('G1care'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'My Medical ID / QR',
            onPressed: () {
              Navigator.pushNamed(context, '/patient/medical-id');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Text(
              'Hello, $patientName',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Emergency Medical Identification & Response',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // ACTIVE EMERGENCY ALERT BANNER (If SOS is Active)
            if (hasActiveEmergency) ...[
              Card(
                color: AppColors.emergencyRedBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.emergencyRed, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, color: AppColors.emergencyRed, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ACTIVE EMERGENCY IN PROGRESS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emergencyRed,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${emergencyProvider.currentPatientIncident?.status.displayName}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/patient/emergency-map');
                        },
                        child: const Text('TRACK MAP'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Privacy-Preserving Patient Profile Card (No exposed blood group or phone on dashboard)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'User Profile & Secure QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, color: Colors.white70, size: 12),
                              SizedBox(width: 4),
                              Text('Protected', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile?.fullName.isNotEmpty == true ? profile!.fullName : patientName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Medical ID: ${profile?.medicalId.isNotEmpty == true ? profile!.medicalId : "G1-MED-PENDING"}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sensitive records stored in Profile view',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, '/patient/medical-profile'),
                          child: const Row(
                            children: [
                              Text('Open Profile', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Smart Wristband Status Card (Interactive)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pushNamed(context, '/patient/wristband');
              },
              child: Card(
                color: isConnected ? AppColors.successGreenBg : AppColors.primaryLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        isConnected ? Icons.watch_sharp : Icons.watch_off_outlined,
                        size: 32,
                        color: isConnected ? AppColors.successGreen : AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Smart Wristband • Tap for Controls',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isConnected
                                  ? 'Connected (${wristbandProvider.deviceId})'
                                  : 'Disconnected (Demo Mode)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isConnected ? AppColors.successGreen : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          if (isConnected) {
                            wristbandProvider.disconnect();
                          } else {
                            wristbandProvider.connect();
                          }
                        },
                        child: Text(isConnected ? 'Disconnect' : 'Connect'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency SOS Button (with Condition-Based Safety Rules)
            SosButton(
              isEnabled: healthStatus.overallLevel != HealthRiskLevel.normal,
              disabledReason: 'Emergency SOS unavailable while condition is normal.',
              riskLevel: healthStatus.overallLevel,
              onTriggered: _triggerSosAlert,
              onCancelled: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Emergency SOS cancelled. You're marked safe."),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 3-LEVEL HEALTH RISK STATUS BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: healthStatus.statusBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: healthStatus.statusColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(healthStatus.statusIcon, color: healthStatus.statusColor, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          healthStatus.overallLevel.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: healthStatus.statusColor,
                          ),
                        ),
                        Text(
                          healthStatus.summaryText,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Live Health Vitals Telemetry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Live Vital Cards (Heart Rate, SpO2, Resp Rate, ECG, Fall)
            VitalCard(
              title: 'Heart Rate',
              value: isConnected ? '${vitals.heartRate}' : '--',
              unit: 'BPM',
              icon: Icons.favorite_rounded,
              accentColor: healthStatus.hrLevel == HealthRiskLevel.critical
                  ? AppColors.emergencyRed
                  : (healthStatus.hrLevel == HealthRiskLevel.warning
                      ? AppColors.warningOrange
                      : AppColors.primary),
              subtitle: isConnected
                  ? (healthStatus.hrLevel == HealthRiskLevel.normal
                      ? 'Normal Resting Pace'
                      : (vitals.heartRate > 100 ? 'Elevated Tachycardia' : 'Bradycardia Warning'))
                  : 'Wristband Disconnected',
            ),
            VitalCard(
              title: 'SpO2 Oxygen Saturation',
              value: isConnected ? '${vitals.spo2}' : '--',
              unit: '%',
              icon: Icons.water_drop_rounded,
              accentColor: healthStatus.spo2Level == HealthRiskLevel.critical
                  ? AppColors.emergencyRed
                  : (healthStatus.spo2Level == HealthRiskLevel.warning
                      ? AppColors.warningOrange
                      : AppColors.secondary),
              subtitle: isConnected
                  ? (vitals.spo2 >= 95 ? 'Optimal Level' : 'Hypoxemia Alert')
                  : 'Wristband Disconnected',
            ),
            VitalCard(
              title: 'Respiratory Rate',
              value: isConnected ? '${vitals.respiratoryRate}' : '--',
              unit: 'breaths/min',
              icon: Icons.air_rounded,
              accentColor: healthStatus.rrLevel == HealthRiskLevel.critical
                  ? AppColors.emergencyRed
                  : (healthStatus.rrLevel == HealthRiskLevel.warning
                      ? AppColors.warningOrange
                      : AppColors.secondary),
              subtitle: isConnected
                  ? (vitals.respiratoryRate > 20
                      ? 'Tachypnea (Rapid)'
                      : 'Normal Respiratory Effort (12–20)')
                  : 'Wristband Disconnected',
            ),
            VitalCard(
              title: 'ECG Rhythm Status',
              value: isConnected ? vitals.ecgStatus : '--',
              unit: '',
              icon: Icons.monitor_heart_rounded,
              accentColor: vitals.ecgStatus == 'Normal Sinus'
                  ? AppColors.successGreen
                  : AppColors.emergencyRed,
              subtitle: isConnected
                  ? (vitals.ecgStatus == 'Normal Sinus' ? 'Sinus Rhythm' : 'Arrhythmia Detected')
                  : 'Monitoring Offline',
            ),
            VitalCard(
              title: 'Fall Detection & Motion',
              value: isConnected ? (vitals.isFallDetected ? 'FALL DETECTED' : 'No Fall') : '--',
              unit: '',
              icon: Icons.directions_walk_rounded,
              accentColor: vitals.isFallDetected ? AppColors.emergencyRed : AppColors.successGreen,
              subtitle: isConnected
                  ? (vitals.isFallDetected ? 'CRITICAL IMPACT DETECTED' : 'Normal Activity')
                  : 'Sensor Inactive',
            ),

            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/wristband');
                    },
                    icon: const Icon(Icons.watch_outlined),
                    label: const Text('DIGITAL WRISTBAND'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/medical-id');
                    },
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('MY MEDICAL ID / QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/medical-profile');
                    },
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: const Text('MEDICAL PROFILE'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
