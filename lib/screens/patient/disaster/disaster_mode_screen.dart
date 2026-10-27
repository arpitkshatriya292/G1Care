import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/disaster/disaster_models.dart';
import '../../../models/emergency_incident.dart';
import '../../../models/vital_reading.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/disaster_provider.dart';
import '../../../providers/emergency_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/medical_profile_provider.dart';
import '../../../providers/wristband_provider.dart';
import '../../../widgets/sos_button.dart';

class DisasterModeScreen extends StatelessWidget {
  const DisasterModeScreen({super.key});

  void _confirmExitDisasterMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppColors.textPrimary),
            SizedBox(width: 10),
            Text('Exit Disaster Mode?'),
          ],
        ),
        content: const Text(
          'G1Care will return to standard emergency standby mode. Enhanced disaster and environmental monitoring will be deactivated.',
          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('STAY IN DISASTER MODE'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textSecondary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);
              await disasterProvider.deactivateDisasterMode();
              if (ctx.mounted) {
                Navigator.pop(ctx); // close dialog
              }
              if (context.mounted) {
                Navigator.pop(context); // exit screen to patient home
              }
            },
            child: const Text('DEACTIVATE & EXIT'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsModal(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Privacy & Edge Processing',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sensitive health data is processed locally on your device. Only explicitly permitted emergency indicators are synchronized.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Health-Data Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Share continuous vital metrics with external hospital triage', style: TextStyle(fontSize: 11)),
                  value: disasterProvider.isHealthDataSharingEnabled,
                  onChanged: (val) {
                    disasterProvider.setHealthDataSharing(val);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Emergency Location Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Transmit GPS coordinates only when emergency SOS is triggered', style: TextStyle(fontSize: 11)),
                  value: disasterProvider.isLocationSharingEnabled,
                  onChanged: (val) {
                    disasterProvider.setLocationSharing(val);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Disaster Incident Participation', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Permit civil defense responders to locate active distress', style: TextStyle(fontSize: 11)),
                  value: disasterProvider.isEmergencySharingEnabled,
                  onChanged: (val) {
                    disasterProvider.setEmergencySharing(val);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('SAVE PRIVACY PREFERENCES'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showScenarioSwitcherModal(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text(
                  'Scenario & Risk Presets (SIH26 Demo)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Switch active environmental disaster contexts and risk levels for testing Edge AI risk inference.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text('Disaster Scenarios:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildScenarioChip(context, disasterProvider, DisasterType.flood, 'FLOOD', Icons.water_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.heatwave, 'HEATWAVE', Icons.wb_sunny_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.cyclone, 'CYCLONE', Icons.cyclone_rounded),
                _buildScenarioChip(context, disasterProvider, DisasterType.airPollution, 'AIR POLLUTION', Icons.masks_rounded),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Risk Level Presets:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      disasterProvider.setRiskLevelPreset(DisasterRiskLevel.low);
                      Navigator.pop(ctx);
                    },
                    child: const Text('LOW RISK'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      disasterProvider.setRiskLevelPreset(DisasterRiskLevel.moderate);
                      Navigator.pop(ctx);
                    },
                    child: const Text('MODERATE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      disasterProvider.setRiskLevelPreset(DisasterRiskLevel.high);
                      Navigator.pop(ctx);
                    },
                    child: const Text('HIGH RISK'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: Icon(
                disasterProvider.isOnline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color: disasterProvider.isOnline ? AppColors.warningOrange : AppColors.successGreen,
              ),
              label: Text(
                disasterProvider.isOnline ? 'SIMULATE OFFLINE OUTAGE' : 'RESTORE ONLINE NETWORK',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                disasterProvider.toggleOfflineMode();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioChip(
    BuildContext context,
    DisasterProvider provider,
    DisasterType type,
    String label,
    IconData icon,
  ) {
    final isSelected = provider.disaster.type == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (selected) {
        if (selected) {
          provider.setDisasterScenario(type);
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _triggerDisasterSos(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<MedicalProfileProvider>(context, listen: false);
    final wristbandProvider = Provider.of<WristbandProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final emergencyProvider = Provider.of<EmergencyProvider>(context, listen: false);

    final profile = profileProvider.profile;
    final patientUser = authProvider.patientUser;
    final vitals = wristbandProvider.currentVitals;
    final location = locationProvider.currentLocation;

    await emergencyProvider.triggerEmergencySos(
      patientUid: patientUser?.uid ?? 'PATIENT-001',
      medicalId: profile?.medicalId ?? 'G1-MED-DEMO',
      patientName: profile?.fullName ?? patientUser?.name ?? 'Patient',
      bloodGroup: profile?.bloodGroup ?? 'Unknown',
      emergencyPhone: profile?.emergencyContactInfo.phone ?? patientUser?.phone ?? '',
      criticalAllergies: profile?.allergies ?? [],
      triggerType: EmergencyTriggerType.manualSos,
      vitalsSnapshot: vitals,
      latitude: location.latitude,
      longitude: location.longitude,
      locationAddress: location.address,
      isSimulatedLocation: location.isSimulated,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.emergency, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DISASTER SOS ACTIVATED: Response unit and nearest hospital alerted.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.emergencyRed,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pushNamed(context, '/patient/emergency-map');
    }
  }

  @override
  Widget build(BuildContext context) {
    final disasterProvider = Provider.of<DisasterProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final emergencyProvider = Provider.of<EmergencyProvider>(context);

    final disaster = disasterProvider.disaster;
    final health = disasterProvider.health;
    final env = disasterProvider.environment;
    final riskLevel = disasterProvider.riskLevel;
    final riskFactors = disasterProvider.riskFactors;
    final recommendations = disasterProvider.recommendations;
    final connectivity = disasterProvider.connectivityState;
    final hasActiveEmergency = emergencyProvider.hasActiveEmergency;

    final timeFormatter = DateFormat('hh:mm:ss a');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Sleek tactical background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Dark slate tactical header
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.emergencyRed, size: 22),
            const SizedBox(width: 8),
            const Text(
              'G1Care DISASTER MODE',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emergencyRed.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.emergencyRed, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔴 ', style: TextStyle(fontSize: 8)),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Scenario Simulator',
            onPressed: () => _showScenarioSwitcherModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Colors.white),
            tooltip: 'Privacy Controls',
            onPressed: () => _showPrivacySettingsModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACTIVE SOS BANNER (if SOS was triggered)
            if (hasActiveEmergency) ...[
              Card(
                color: AppColors.emergencyRedBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.emergencyRed, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      const Icon(Icons.emergency, color: AppColors.emergencyRed, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMERGENCY SOS ACTIVE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emergencyRed,
                              ),
                            ),
                            Text(
                              'Hospital response team dispatched to your location.',
                              style: TextStyle(fontSize: 11, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emergencyRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/patient/emergency-map');
                        },
                        child: const Text('TRACK', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 1. DISASTER INFORMATION CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: disaster.type.color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(disaster.type.icon, color: disaster.type.color, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'DISASTER INFORMATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: disaster.type.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            disaster.severity.displayName.toUpperCase(),
                            style: TextStyle(
                              color: disaster.type.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Disaster:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                disaster.type.displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: disaster.type.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Affected Area:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                disaster.isInsideAffectedArea ? 'Affected (Inside)' : 'Border / Safe Zone',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: disaster.isInsideAffectedArea ? AppColors.emergencyRed : AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Location: ${locationProvider.currentLocation.address}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Last Updated: ${timeFormatter.format(disaster.timestamp)} • ${disaster.source}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 2. G1CARE PROTECTION CARD
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'G1CARE PROTECTION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        // Connectivity Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: connectivity.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: connectivity.color, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                connectivity == DisasterConnectivityState.online
                                    ? Icons.wifi_rounded
                                    : (connectivity == DisasterConnectivityState.offline
                                        ? Icons.wifi_off_rounded
                                        : Icons.sync_rounded),
                                size: 12,
                                color: connectivity.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                connectivity.displayName,
                                style: TextStyle(
                                  color: connectivity.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Monitoring Active:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMonitoringPill(Icons.favorite_rounded, 'Health', AppColors.primary),
                        const SizedBox(width: 8),
                        _buildMonitoringPill(Icons.cloud_rounded, 'Environmental', AppColors.secondary),
                        const SizedBox(width: 8),
                        _buildMonitoringPill(Icons.gps_fixed_rounded, 'Location', AppColors.warningOrange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 3. PERSONAL RISK (EXACTLY THREE LEVELS: LOW, MODERATE, HIGH)
            Card(
              elevation: 2,
              color: riskLevel.bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: riskLevel.color, width: 1.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PERSONAL RISK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: riskLevel.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            riskLevel.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(riskLevel.icon, color: riskLevel.color, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            riskLevel == DisasterRiskLevel.low
                                ? 'Low composite vulnerability. Environmental and vital parameters remain stable.'
                                : (riskLevel == DisasterRiskLevel.moderate
                                    ? 'Moderate safety risk detected. Caution advised; monitor health vitals.'
                                    : 'High composite risk detected. Proactive safety measures or medical attention needed.'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: riskLevel.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. HEALTH STATUS GRID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HEALTH STATUS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  timeFormatter.format(health.timestamp),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.favorite_rounded,
                    title: 'Heart Rate',
                    value: '${health.heartRate}',
                    unit: 'BPM',
                    status: health.heartRate > 100 ? 'Elevated' : 'Normal',
                    statusColor: health.heartRate > 100 ? AppColors.warningOrange : AppColors.successGreen,
                    iconColor: AppColors.emergencyRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.water_drop_rounded,
                    title: 'SpO2 Oxygen',
                    value: '${health.spo2}',
                    unit: '%',
                    status: health.spo2 >= 95 ? 'Optimal' : 'Low',
                    statusColor: health.spo2 >= 95 ? AppColors.successGreen : AppColors.emergencyRed,
                    iconColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.thermostat_rounded,
                    title: 'Body Temp',
                    value: health.bodyTemperature.toStringAsFixed(1),
                    unit: '°C',
                    status: health.bodyTemperature >= 38.0 ? 'Fever/Heat' : 'Normal',
                    statusColor: health.bodyTemperature >= 38.0 ? AppColors.warningOrange : AppColors.successGreen,
                    iconColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Activity',
                    value: '${health.activitySteps}',
                    unit: 'steps',
                    status: health.activitySteps > 6000 ? 'Active' : 'Resting',
                    statusColor: AppColors.primary,
                    iconColor: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTelemetryCard(
              icon: Icons.bedtime_rounded,
              title: 'Sleep',
              value: '${health.sleepDurationHours.toStringAsFixed(1)} hrs',
              unit: '(${health.sleepQuality})',
              status: health.sleepDurationHours >= 6.5 ? 'Rested' : 'Sleep Deficit',
              statusColor: health.sleepDurationHours >= 6.5 ? AppColors.successGreen : AppColors.warningOrange,
              iconColor: Colors.indigo,
            ),

            const SizedBox(height: 16),

            // 5. ENVIRONMENT GRID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ENVIRONMENT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  timeFormatter.format(env.timestamp),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.thermostat_outlined,
                    title: 'Ambient Temp',
                    value: env.ambientTemperature.toStringAsFixed(1),
                    unit: '°C',
                    status: env.ambientTemperature >= 38.0 ? 'Extreme Heat' : (env.ambientTemperature >= 35.0 ? 'Hot' : 'Moderate'),
                    statusColor: env.ambientTemperature >= 38.0 ? AppColors.emergencyRed : (env.ambientTemperature >= 35.0 ? AppColors.warningOrange : AppColors.successGreen),
                    iconColor: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTelemetryCard(
                    icon: Icons.water_rounded,
                    title: 'Humidity',
                    value: env.humidity.toStringAsFixed(0),
                    unit: '%',
                    status: env.humidity >= 75.0 ? 'High' : 'Moderate',
                    statusColor: env.humidity >= 75.0 ? AppColors.warningOrange : AppColors.successGreen,
                    iconColor: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTelemetryCard(
              icon: Icons.air_rounded,
              title: 'Air Quality',
              value: '${env.aqi} AQI',
              unit: '(${env.aqiCategory})',
              status: env.aqi >= 200 ? 'Hazardous' : (env.aqi >= 120 ? 'Unhealthy' : 'Acceptable'),
              statusColor: env.aqi >= 200 ? AppColors.emergencyRed : (env.aqi >= 120 ? AppColors.warningOrange : AppColors.successGreen),
              iconColor: Colors.brown,
            ),

            const SizedBox(height: 18),

            // 6. "WHY AM I AT RISK?"
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'WHY AM I AT RISK?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Risk analysis generated locally on your device by combining vitals, baseline, and environmental stress factors:',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                    ),
                    const SizedBox(height: 12),
                    ...riskFactors.map((factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                factor.isElevated ? '• ' : '✓ ',
                                style: TextStyle(
                                  color: factor.isElevated ? AppColors.warningOrange : AppColors.successGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                                    children: [
                                      TextSpan(
                                        text: '${factor.title}: ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: factor.explanation),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 7. RECOMMENDED ACTION
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1.2),
              ),
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryDark, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'RECOMMENDED ACTION',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(rec.icon, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rec.actionText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 8. NAVIGATION ACTIONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/disaster-mode/safe-locations');
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('SAFE LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF4A148C), // Deep purple AI accent
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/patient/disaster-mode/ask-ai');
                    },
                    icon: const Icon(Icons.smart_toy_rounded),
                    label: const Text('ASK G1CARE AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Personal Wellness Dashboard Link
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/patient/disaster-mode/wellness');
              },
              icon: const Icon(Icons.insights_rounded, color: AppColors.primary),
              label: const Text(
                'PERSONAL WELLNESS & BASELINE TRENDS',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),

            // 9. PROMINENT EMERGENCY SOS BUTTON
            SosButton(
              isEnabled: true,
              riskLevel: riskLevel == DisasterRiskLevel.high ? HealthRiskLevel.critical : HealthRiskLevel.warning,
              onTriggered: () => _triggerDisasterSos(context),
              onCancelled: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Disaster SOS cancelled. You remain under Disaster Mode monitoring.'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 10. EXIT DISASTER MODE BUTTON
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                onPressed: () => _confirmExitDisasterMode(context),
                icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                label: const Text(
                  'EXIT DISASTER MODE',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringPill(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
                Text(
                  status,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
