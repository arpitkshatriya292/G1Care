import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/vital_reading.dart';
import '../../providers/wristband_provider.dart';
import '../../widgets/vital_card.dart';

class WristbandScreen extends StatelessWidget {
  const WristbandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wristbandProvider = Provider.of<WristbandProvider>(context);
    final vitals = wristbandProvider.currentVitals;
    final healthStatus = wristbandProvider.healthStatus;
    final isConnected = wristbandProvider.isConnected;
    final formattedTime = DateFormat('hh:mm:ss a').format(vitals.timestamp);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Digital Smart Wristband'),
        actions: [
          IconButton(
            icon: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
            tooltip: isConnected ? 'Disconnect Wristband' : 'Connect Wristband',
            onPressed: () {
              if (isConnected) {
                wristbandProvider.disconnect();
              } else {
                wristbandProvider.connect();
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
            // 1. SMART WRISTBAND HARDWARE BADGE
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppColors.successGreenBg
                                : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.watch_sharp,
                            color: isConnected
                                ? AppColors.successGreen
                                : AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wristbandProvider.deviceId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isConnected
                                          ? AppColors.successGreen
                                          : AppColors.emergencyRed,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    wristbandProvider.connectionState.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isConnected
                                          ? AppColors.successGreen
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.battery_charging_full_rounded,
                                    size: 16,
                                    color: vitals.batteryLevel > 20
                                        ? AppColors.successGreen
                                        : AppColors.emergencyRed,
                                  ),
                                  Text(
                                    '${vitals.batteryLevel}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Simulation disclaimer banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrangeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warningOrange, size: 16),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'DEMO / SIMULATION MODE • Continuous High-Fidelity Telemetry',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. OVERALL HEALTH RISK EVALUATION BANNER (3 LEVELS)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: healthStatus.statusBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: healthStatus.statusColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(healthStatus.statusIcon, color: healthStatus.statusColor, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              healthStatus.overallLevel.displayName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: healthStatus.statusColor,
                              ),
                            ),
                            Text(
                              'Synced: $formattedTime',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          healthStatus.summaryText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. LIVE HEALTH TELEMETRY GRID
            const Text(
              'Live Health Vitals Telemetry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Heart Rate
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
                      ? 'Normal Resting Rhythm (60–100 BPM)'
                      : (vitals.heartRate > 100 ? 'Elevated / Tachycardia' : 'Bradycardia'))
                  : 'Disconnected',
            ),

            // SpO2
            VitalCard(
              title: 'Blood Oxygen Saturation (SpO2)',
              value: isConnected ? '${vitals.spo2}' : '--',
              unit: '%',
              icon: Icons.water_drop_rounded,
              accentColor: healthStatus.spo2Level == HealthRiskLevel.critical
                  ? AppColors.emergencyRed
                  : (healthStatus.spo2Level == HealthRiskLevel.warning
                      ? AppColors.warningOrange
                      : AppColors.secondary),
              subtitle: isConnected
                  ? (vitals.spo2 >= 95 ? 'Optimal Blood Oxygenation' : 'Hypoxemia Detected')
                  : 'Disconnected',
            ),

            // Respiratory Rate
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
                  ? (vitals.respiratoryRate > 20 ? 'Tachypnea (Rapid)' : 'Normal Respiratory Effort (12–20)')
                  : 'Disconnected',
            ),

            // ECG Rhythm
            VitalCard(
              title: 'ECG Rhythm Analysis',
              value: isConnected ? vitals.ecgStatus : '--',
              unit: '',
              icon: Icons.monitor_heart_rounded,
              accentColor: vitals.ecgStatus == 'Normal Sinus'
                  ? AppColors.successGreen
                  : AppColors.emergencyRed,
              subtitle: isConnected
                  ? (vitals.ecgStatus == 'Normal Sinus' ? 'Normal Sinus Rhythm' : 'Arrhythmia Detected')
                  : 'Monitoring Inactive',
            ),

            // Fall Detection
            VitalCard(
              title: 'Fall Detection & Motion Sensor',
              value: isConnected ? (vitals.isFallDetected ? 'FALL DETECTED' : 'No Fall') : '--',
              unit: '',
              icon: Icons.directions_walk_rounded,
              accentColor: vitals.isFallDetected ? AppColors.emergencyRed : AppColors.successGreen,
              subtitle: isConnected
                  ? (vitals.isFallDetected
                      ? 'CRITICAL IMPACT EVENT DETECTED'
                      : 'Stable Gait & Motion Activity')
                  : 'Sensor Disconnected',
            ),

            const SizedBox(height: 24),

            // 4. HACKATHON SIMULATION CONTROLS DECK
            const Text(
              'Interactive Telemetry Simulator Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Test smooth realistic physiological transitions and anomaly detection',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // 3 Presets: Normal, Warning, Critical
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => wristbandProvider.setSimulationMode(SimulationMode.normal),
                    child: const Text('NORMAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => wristbandProvider.setSimulationMode(SimulationMode.warning),
                    child: const Text('WARNING', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emergencyRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => wristbandProvider.setSimulationMode(SimulationMode.critical),
                    child: const Text('CRITICAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Granular Anomaly Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.favorite, size: 16, color: AppColors.emergencyRed),
                  label: const Text('Simulate High Heart Rate'),
                  onPressed: () => wristbandProvider.simulateHighHeartRate(),
                ),
                ActionChip(
                  avatar: const Icon(Icons.water_drop, size: 16, color: AppColors.primary),
                  label: const Text('Simulate Low SpO2'),
                  onPressed: () => wristbandProvider.simulateLowSpO2(),
                ),
                ActionChip(
                  avatar: const Icon(Icons.air, size: 16, color: AppColors.secondary),
                  label: const Text('Simulate Abnormal Resp Rate'),
                  onPressed: () => wristbandProvider.simulateAbnormalRespiratoryRate(),
                ),
                ActionChip(
                  backgroundColor: AppColors.emergencyRedBg,
                  avatar: const Icon(Icons.warning, size: 16, color: AppColors.emergencyRed),
                  label: const Text('Simulate Fall Impact', style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold)),
                  onPressed: () => wristbandProvider.simulateFall(),
                ),
                ActionChip(
                  backgroundColor: AppColors.primaryLight,
                  avatar: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
                  label: const Text('Reset to Normal Stable', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () => wristbandProvider.resetToNormal(),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
